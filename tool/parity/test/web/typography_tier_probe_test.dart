// The typography tier, rendered — what a real Chrome with the vendored
// Tailwind computes for each role at each viewport width.
//
// The Web unit tests read the rules the stylesheet emits
// (`packages/coui_web/test/base/typography_tier_css_test.dart`). That proves
// the declarations, not what the browser does with them: that a width lands
// in the tier the shared judgement gives it, with no fractional gap between
// the queries; that a pin on the document turns the viewport off; that a pin
// on a subtree reaches the elements inside it; that a component holding its
// own tier keeps its text there. Those claims live in the computed style, so
// this file reads it.
//
// The numbers are the table `coui_core` owns — the one the Flutter render
// test reads too — and the markup is the real components' server output.
// The one exception is a panel: it exists only after a click on a hydrated
// page, so that group compiles a client entry
// (`src/web/typography_tier_panel_entry.dart`) and clicks it open — the
// context menu with a right-click, the browser event no VM test can build.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../../src/web/offline_tailwind_harness.dart';

/// The table shared with the Core, Flutter and Web unit tests.
const String _kVectorsPath =
    'packages/coui_core/test/fixtures/typography_tier_vectors.json';

/// Within a hundredth of a pixel — the browser rounds a computed length to
/// a fixed number of decimals.
const double _kEpsilon = 0.01;

/// Viewport height — any height works; the tier reads the width only.
const int _kViewportHeight = 600;

String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

/// What one role draws at one tier: its size in px and tracking in em.
typedef _Drawn = ({double size, double trackingEm});

/// One element per role, carrying the role's class — the class every role
/// emit resolves to. [prefix] keeps ids apart when a page holds several.
Component _roles(Iterable<String> roles, {String prefix = 'r'}) => div([
  for (final role in roles)
    div(const [Text('Ag')], id: '$prefix-$role', classes: 'text-$role'),
]);

/// The computed font size and letter spacing (px) of every element whose id
/// starts with one of [prefixes].
String _measure(List<String> prefixes) =>
    '''
() => {
  const out = {};
  for (const prefix of ${jsonEncode(prefixes)}) {
    for (const el of document.querySelectorAll('[id^="' + prefix + '-"]')) {
      const cs = getComputedStyle(el);
      out[el.id] = {
        size: parseFloat(cs.fontSize),
        tracking: cs.letterSpacing === 'normal' ? 0 : parseFloat(cs.letterSpacing),
      };
    }
  }
  return JSON.stringify(out);
}
''';

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();

  final vectors =
      jsonDecode(File(p.join(repoRoot, _kVectorsPath)).readAsStringSync())
          as Map<String, dynamic>;
  final roles = <String, Map<CoreBreakpointTier, _Drawn>>{
    for (final row in (vectors['roles'] as List).cast<Map<String, dynamic>>())
      row['role'] as String: {
        for (final tier in CoreBreakpointTier.values)
          tier: (
            size: ((row[tier.name] as Map)['size'] as num).toDouble(),
            trackingEm: ((row[tier.name] as Map)['trackingEm'] as num)
                .toDouble(),
          ),
      },
  };
  // Width 0 is not a viewport a browser opens; every other row is.
  final widths = [
    for (final row in (vectors['widths'] as List).cast<Map<String, dynamic>>())
      if ((row['width'] as int) > 0)
        (
          width: row['width'] as int,
          tier: CoreBreakpointTier.values.byName(row['tier'] as String),
        ),
  ];
  final narrowest = widths.first.width;

  /// A real `CoUIWeb` root under the vendored Tailwind head — the page the
  /// stylesheet's rules run in.
  Component page(Component child, {CoreBreakpointTier? typographyTier}) =>
      .fragment([
        Document.head(
          children: [
            Component.element(
              tag: 'script',
              children: [RawText(vendoredScript)],
            ),
            Component.element(
              tag: 'script',
              children: [RawText(themeConfig.tailwindConfig)],
            ),
            Component.element(
              tag: 'style',
              children: [RawText(themeConfig.cssVariables)],
            ),
          ],
        ),
        CoUIWeb(theme: .coui, typographyTier: typographyTier, child: child),
      ]);

  /// Loads [html] offline in headless Chrome. The caller closes the browser.
  Future<(pptr.Browser, pptr.Page)> load(String html) async {
    final tempDir = Directory.systemTemp.createTempSync(
      'coui-parity-typography-tier-probe-',
    );
    try {
      final file = File(p.join(tempDir.path, 'tier.html'))
        ..writeAsStringSync(html);
      final browser = await pptr.puppeteer.launch(executablePath: chromePath);
      final page = await browser.newPage();
      await page.setOfflineMode(true);
      final _ = await page.goto(
        Uri.file(file.path).toString(),
        wait: pptr.Until.load,
      );

      return (browser, page);
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  }

  /// Opens a [width]-wide viewport and reads every element under [prefixes].
  Future<Map<String, ({double size, double tracking})>> readAt(
    pptr.Page page,
    int width,
    List<String> prefixes,
  ) async {
    await page.setViewport(
      pptr.DeviceViewport(width: width, height: _kViewportHeight),
    );
    final json =
        jsonDecode(await page.evaluate<String>(_measure(prefixes)))
            as Map<String, dynamic>;

    return {
      for (final MapEntry(:key, :value) in json.entries)
        key: (
          size: ((value as Map)['size'] as num).toDouble(),
          tracking: (value['tracking'] as num).toDouble(),
        ),
    };
  }

  /// Checks that every role under [prefix] draws what the table gives it at
  /// [tier].
  void expectTier(
    Map<String, ({double size, double tracking})> measured,
    CoreBreakpointTier tier, {
    required String prefix,
    required String reason,
  }) {
    for (final MapEntry(:key, :value) in roles.entries) {
      final drawn = value[tier]!;
      final read = measured['$prefix-$key'];
      expect(read, isNotNull, reason: '$prefix-$key missing — $reason');
      expect(
        read!.size,
        closeTo(drawn.size, _kEpsilon),
        reason: '$key size — $reason',
      );
      expect(
        read.tracking,
        closeTo(drawn.trackingEm * drawn.size, _kEpsilon),
        reason: '$key tracking — $reason',
      );
    }
  }

  // No local Chrome — the rendered claims cannot be verified here.
  final skip = chromePath == null;

  group('TypographyTierProbe — the roles Chrome draws at each width', () {
    testServer(
      'the viewport chooses: each width draws the tier the table gives it',
      (tester) async {
        tester.pumpComponent(page(_roles(roles.keys)));
        final response = await tester.request('/');

        final (browser, chrome) = await load(response.body);
        try {
          for (final (:width, :tier) in widths) {
            expectTier(
              await readAt(chrome, width, ['r']),
              tier,
              prefix: 'r',
              reason: '${width}px is ${tier.name}',
            );
          }
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testServer(
      'a pin on the document holds every width to its tier',
      (tester) async {
        tester.pumpComponent(
          page(_roles(roles.keys), typographyTier: .desktop),
        );
        final response = await tester.request('/');

        final (browser, chrome) = await load(response.body);
        try {
          for (final (:width, tier: _) in widths) {
            expectTier(
              await readAt(chrome, width, ['r']),
              .desktop,
              prefix: 'r',
              reason: 'pinned desktop at ${width}px',
            );
          }
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testServer(
      'a document attribute that names no tier leaves the viewport choosing',
      (tester) async {
        // What `CoUIWeb` writes when it lifts a pin it set: on the client the
        // attribute cannot be taken off `<html>` again, so it is rewritten to
        // a value the pins do not match.
        tester.pumpComponent(
          .fragment([
            const Document.html(
              attributes: {kTypographyTierAttribute: 'viewport'},
            ),
            page(_roles(roles.keys)),
          ]),
        );
        final response = await tester.request('/');

        final (browser, chrome) = await load(response.body);
        try {
          for (final (:width, :tier) in widths) {
            expectTier(
              await readAt(chrome, width, ['r']),
              tier,
              prefix: 'r',
              reason: 'unpinned at ${width}px is ${tier.name}',
            );
          }
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testServer(
      'print draws the sizes as authored at any paper width',
      (tester) async {
        tester.pumpComponent(page(_roles(roles.keys)));
        final response = await tester.request('/');

        final (browser, chrome) = await load(response.body);
        try {
          // A page laid out for paper is narrower than a tablet; the viewport
          // queries alone would print it at the phone sizes.
          await chrome.emulateMediaType(pptr.MediaType.print);
          expectTier(
            await readAt(chrome, narrowest, ['r']),
            .desktop,
            prefix: 'r',
            reason: 'printed at ${narrowest}px',
          );
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testServer(
      'a pin on a subtree holds that subtree, and only it',
      (tester) async {
        tester.pumpComponent(
          page(
            div([
              _roles(roles.keys, prefix: 'free'),
              TypographyTierScope(
                tier: .desktop,
                child: _roles(roles.keys, prefix: 'desk'),
              ),
              TypographyTierScope(
                tier: .mobile,
                child: _roles(roles.keys, prefix: 'mob'),
              ),
              // The nearer pin wins: a mobile part inside a desktop part.
              TypographyTierScope(
                tier: .desktop,
                child: TypographyTierScope(
                  tier: .mobile,
                  child: _roles(roles.keys, prefix: 'nest'),
                ),
              ),
            ]),
          ),
        );
        final response = await tester.request('/');

        final (browser, chrome) = await load(response.body);
        try {
          for (final (:width, :tier) in [widths.first, widths.last]) {
            final measured = await readAt(chrome, width, [
              'free',
              'desk',
              'mob',
              'nest',
            ]);
            expectTier(
              measured,
              tier,
              prefix: 'free',
              reason: 'outside every pin at ${width}px',
            );
            expectTier(
              measured,
              .desktop,
              prefix: 'desk',
              reason: 'desktop pin at ${width}px',
            );
            expectTier(
              measured,
              .mobile,
              prefix: 'mob',
              reason: 'mobile pin at ${width}px',
            );
            expectTier(
              measured,
              .mobile,
              prefix: 'nest',
              reason: 'mobile pin inside a desktop one at ${width}px',
            );
          }
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testServer(
      "an avatar's initials keep their desktop size at every width",
      (tester) async {
        tester.pumpComponent(
          page(
            div([
              Avatar(id: 'avatar-xl', initials: 'JD', size: .xl),
              Avatar(id: 'avatar-xl2', initials: 'JD', size: .xl2),
              // The roles the initials use, outside any pin, to show the
              // tier is in force on the same page.
              _roles(['headline-small', 'headline-large'], prefix: 'free'),
            ]),
          ),
        );
        final response = await tester.request('/');

        final (browser, chrome) = await load(response.body);
        try {
          await chrome.setViewport(
            pptr.DeviceViewport(width: narrowest, height: _kViewportHeight),
          );
          final json =
              jsonDecode(
                    await chrome.evaluate<String>('''
() => JSON.stringify(Object.fromEntries(
  ['avatar-xl', 'avatar-xl2', 'free-headline-small', 'free-headline-large']
    .map((id) => {
      const root = document.getElementById(id);
      const el = id.startsWith('avatar')
        ? root.querySelector('[class*="text-headline"]')
        : root;
      return [id, parseFloat(getComputedStyle(el).fontSize)];
    })))
'''),
                  )
                  as Map<String, dynamic>;

          final mobile = widths.first.tier;
          expect(
            json['free-headline-small'],
            roles['headline-small']![mobile]!.size,
            reason: 'the page is in its narrowest tier',
          );
          expect(
            json['free-headline-large'],
            roles['headline-large']![mobile]!.size,
          );
          expect(
            json['avatar-xl'],
            roles['headline-small']![CoreBreakpointTier.desktop]!.size,
            reason: 'xl initials at ${narrowest}px',
          );
          expect(
            json['avatar-xl2'],
            roles['headline-large']![CoreBreakpointTier.desktop]!.size,
            reason: 'xl2 initials at ${narrowest}px',
          );
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('TypographyTierProbe — a panel opened inside a scope', () {
    late Directory fixture;
    late File html;

    setUpAll(() async {
      if (skip) return;
      fixture = Directory.systemTemp.createTempSync(
        'coui-parity-typography-tier-panel-',
      );
      final js = p.join(fixture.path, 'entry.js');
      final result = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        '-O2',
        '-o',
        js,
        'tool/parity/src/web/typography_tier_panel_entry.dart',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      // No document pin: the page has to take its tier from the viewport,
      // or the scope's tier and the page's would be the same.
      html = File(p.join(fixture.path, 'panel.html'))
        ..writeAsStringSync('''
<!doctype html>
<html data-theme="light">
<head>
<meta charset="utf-8">
<script>$vendoredScript</script>
<script>${themeConfig.tailwindConfig}</script>
<style>${themeConfig.cssVariables}</style>
</head>
<body>
<script>${File(js).readAsStringSync()}</script>
</body>
</html>
''');
    });

    tearDownAll(() {
      if (!skip) fixture.deleteSync(recursive: true);
    });

    test(
      'renders at the scope’s tier, not the page’s',
      () async {
        final browser = await pptr.puppeteer.launch(executablePath: chromePath);
        try {
          final chrome = await browser.newPage();
          await chrome.setOfflineMode(true);
          await chrome.setViewport(
            pptr.DeviceViewport(width: narrowest, height: _kViewportHeight),
          );
          final _ = await chrome.goto(
            Uri.file(html.path).toString(),
            wait: pptr.Until.load,
          );
          // Hydrated, and the role classes generated for the page.
          await chrome.waitForFunction('''
() => {
  const el = document.getElementById('free-display-large');
  return el !== null && getComputedStyle(el).fontSize !== '16px';
}''');
          await chrome.click('#probe-trigger');
          await chrome.waitForFunction('''
() => {
  const el = document.getElementById('panel-display-large');
  return el !== null && getComputedStyle(el).fontSize !== '16px';
}''');

          final measured = await readAt(chrome, narrowest, [
            'free',
            'trigger',
            'panel',
          ]);
          final mobile = widths.first.tier;
          for (final role in ['display-large', 'headline-small']) {
            final drawn = roles[role]!;
            expect(
              measured['free-$role']!.size,
              drawn[mobile]!.size,
              reason: '$role on the page at ${narrowest}px',
            );
            expect(
              measured['trigger-$role']!.size,
              drawn[CoreBreakpointTier.desktop]!.size,
              reason: '$role inside the desktop scope',
            );
            expect(
              measured['panel-$role']!.size,
              drawn[CoreBreakpointTier.desktop]!.size,
              reason: '$role in the panel the scope opened',
            );
          }
          // The panel left the scope: it is not inside the wrapper around
          // the trigger, so what holds it to desktop is the scope stated
          // around it in the host's layer.
          final insideTriggerScope = await chrome.evaluate<bool>('''
() =>
  document.getElementById('trigger-display-large')
    .closest('[$kTypographyTierAttribute]')
    .contains(document.getElementById('panel-display-large'))''');
          expect(insideTriggerScope, isFalse);
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'a context menu renders at the scope’s tier, not the page’s',
      () async {
        final browser = await pptr.puppeteer.launch(executablePath: chromePath);
        try {
          final chrome = await browser.newPage();
          await chrome.setOfflineMode(true);
          await chrome.setViewport(
            pptr.DeviceViewport(width: narrowest, height: _kViewportHeight),
          );
          final _ = await chrome.goto(
            Uri.file(html.path).toString(),
            wait: pptr.Until.load,
          );
          // Hydrated, and the role classes generated for the page.
          await chrome.waitForFunction('''
() => {
  const el = document.getElementById('free-display-large');
  return el !== null && getComputedStyle(el).fontSize !== '16px';
}''');
          await chrome.click('#probe-context', button: pptr.MouseButton.right);
          await chrome.waitForFunction('''
() => {
  const el = document.getElementById('context-display-large');
  return el !== null && getComputedStyle(el).fontSize !== '16px';
}''');

          final measured = await readAt(chrome, narrowest, ['free', 'context']);
          final mobile = widths.first.tier;
          for (final role in ['display-large', 'headline-small']) {
            final drawn = roles[role]!;
            expect(
              measured['free-$role']!.size,
              drawn[mobile]!.size,
              reason: '$role on the page at ${narrowest}px',
            );
            expect(
              measured['context-$role']!.size,
              drawn[CoreBreakpointTier.desktop]!.size,
              reason: '$role in the context menu the scope opened',
            );
          }
          // The menu left the scope too: what holds it to desktop is the
          // scope stated around it in the host's layer.
          final insideContextScope = await chrome.evaluate<bool>('''
() =>
  document.getElementById('probe-context')
    .closest('[$kTypographyTierAttribute]')
    .contains(document.getElementById('context-display-large'))''');
          expect(insideContextScope, isFalse);
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
