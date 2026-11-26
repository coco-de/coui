// Link, rendered — the classes `Link` emits, turned into computed styles by the
// vendored Tailwind and a real Chrome.
//
// The unit tests of `Link` read class names and inline declarations off the
// component tree. That proves what is emitted, not what the browser makes of
// it — and four of the claims below live exactly in that gap: a utility class
// that Tailwind never generates is silently inert, a `group-*` variant only
// works if the marker sits on the right ancestor, and `from-font` only applies
// when no underline offset is stated.
//
// The markup is the real component's server output, not a hand-copied string,
// so a change to what `Link` emits changes what this test looks at.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../../src/web/offline_tailwind_harness.dart';

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

/// `--{varName}: R G B;` as the channels the browser will compute from it.
(int, int, int) _expectedRgb(String cssVariables, String varName) {
  final match = RegExp(
    '$varName:\\s*([0-9]+) ([0-9]+) ([0-9]+)',
  ).firstMatch(cssVariables);
  if (match == null) throw StateError('$varName not found in cssVariables.');

  return (
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

(int, int, int) _parseRgb(String css) {
  final match = RegExp(
    r'rgba?\(\s*(\d+)[,\s]+(\d+)[,\s]+(\d+)',
  ).firstMatch(css);
  if (match == null) throw StateError('not a computed colour: $css');

  return (
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// What this test reads off an element — enough to say what a link looks like.
const String _kReadStyle = '''
(selector) => {
  const el = document.querySelector(selector);
  if (!el) return null;
  const cs = getComputedStyle(el);
  return JSON.stringify({
    color: cs.color,
    textDecorationLine: cs.textDecorationLine,
    textDecorationThickness: cs.textDecorationThickness,
    textUnderlinePosition: cs.textUnderlinePosition,
    textUnderlineOffset: cs.textUnderlineOffset,
    outlineStyle: cs.outlineStyle,
    outlineWidth: cs.outlineWidth,
    outlineOffset: cs.outlineOffset,
    outlineColor: cs.outlineColor,
    borderTopLeftRadius: cs.borderTopLeftRadius,
    display: cs.display,
    rects: el.getClientRects().length,
  });
}
''';

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();

  // One page holding every shape a link takes.
  late String bodyHtml;

  testServer('server output of the links under test', (tester) async {
    tester.pumpComponent(
      Theme.defaults(
        child: Component.element(
          tag: 'div',
          children: [
            const Link(
              href: '#standard',
              id: 'standard',
              child: Text('Standard'),
            ),
            const Link(
              href: '#muted',
              id: 'muted',
              variant: CoreLinkVariant.muted,
              child: Text('Muted'),
            ),
            const Link(
              href: '#underlined',
              id: 'underlined',
              underline: true,
              child: Text('Underlined'),
            ),
            Link(
              href: '#acting',
              id: 'acting',
              onPressed: () {},
              child: const Text('Acting'),
            ),
            // A narrow paragraph, so the inline link has to wrap.
            Component.element(
              tag: 'p',
              id: 'paragraph',
              styles: const Styles(
                raw: {'width': '120px', 'line-height': '1.6'},
              ),
              children: [
                const Text('Read the '),
                Builder(
                  builder: (context) => Link.inlineSpan(
                    context,
                    href: '#inline',
                    text: 'theming guide for tokens and presets',
                  ),
                ),
                const Text(' first.'),
              ],
            ),
          ],
        ),
      ),
    );
    final response = await tester.request('/');
    final html = response.body;
    final match = RegExp(
      '<body[^>]*>(.*)</body>',
      dotAll: true,
    ).firstMatch(html);
    bodyHtml = match == null ? html : match.group(1)!;
    expect(bodyHtml, contains('id="standard"'));
  });

  group('Link rendered by the vendored Tailwind in Chrome', () {
    late pptr.Browser browser;
    late pptr.Page page;
    late Directory tempDir;

    setUpAll(() async {
      browser = await pptr.puppeteer.launch(executablePath: chromePath);
    });
    tearDownAll(() => browser.close());

    setUp(() async {
      page = await browser.newPage();
      tempDir = Directory.systemTemp.createTempSync('coui-link-render-');
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: bodyHtml,
        themeConfig: themeConfig,
        vendoredTailwindScript: vendoredScript,
      );
      final file = File(p.join(tempDir.path, 'link.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: pptr.Until.load);
      // Park the pointer away from every link, so a hover is always a choice.
      await page.mouse.move(const pptr.Point(790, 590));
    });
    tearDown(() async {
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    Future<Map<String, dynamic>> read(String selector) async {
      final json = await page.evaluate<String?>(
        _kReadStyle,
        args: [selector],
      );
      expect(json, isNotNull, reason: 'nothing matched $selector');

      return jsonDecode(json!) as Map<String, dynamic>;
    }

    void expectColour(Map<String, dynamic> style, String varName) {
      expect(
        _parseRgb(style['color'] as String),
        _expectedRgb(themeConfig.cssVariables, varName),
        reason: 'colour ${style['color']} is not $varName',
      );
    }

    final skip = chromePath == null
        ? 'no local Chrome — the rendered claims cannot be verified here'
        : null;

    test(
      'a standalone link is the link colour with no underline at rest',
      () async {
        final style = await read('#standard');

        expectColour(style, '--coui-link');
        expect(style['textDecorationLine'], 'none');
      },
      skip: skip,
    );

    test("the underline is the font's own: thickness and position from-font, "
        'no stated offset', () async {
      await page.hover('#underlined');
      final style = await read('#underlined');

      expect(style['textDecorationLine'], contains('underline'));
      expect(style['textDecorationThickness'], 'from-font');
      expect(style['textUnderlinePosition'], 'from-font');
      expect(style['textUnderlineOffset'], 'auto');
    }, skip: skip);

    test('hover reveals the underline, and leaving takes it away', () async {
      await page.hover('#standard');
      expect(
        (await read('#standard'))['textDecorationLine'],
        contains('underline'),
      );

      await page.mouse.move(const pptr.Point(790, 590));
      expect((await read('#standard'))['textDecorationLine'], 'none');
    }, skip: skip);

    test(
      'keyboard focus draws the 2px ring at a 2px gap and shows the underline',
      () async {
        await page.keyboard.press(pptr.Key.tab);
        final style = await read('#standard');

        expect(style['outlineStyle'], 'solid');
        expect(style['outlineWidth'], '2px');
        expect(style['outlineOffset'], '2px');
        expect(
          _parseRgb(style['outlineColor'] as String),
          _expectedRgb(themeConfig.cssVariables, '--coui-focus-ring'),
        );
        expect(style['textDecorationLine'], contains('underline'));
      },
      skip: skip,
    );

    test(
      'at rest the ring is a transparent reserved outline, not absent',
      () async {
        // `outline-none` in Tailwind v3 keeps the outline and makes it
        // transparent, so focus only has to move its colour.
        final style = await read('#standard');

        expect(style['outlineStyle'], 'solid');
        expect(style['outlineColor'], anyOf('rgba(0, 0, 0, 0)', 'transparent'));
      },
      skip: skip,
    );

    test('the ring follows the 4px corner', () async {
      expect((await read('#standard'))['borderTopLeftRadius'], '4px');
    }, skip: skip);

    test('underline: true is underlined without any interaction', () async {
      final style = await read('#underlined');

      expect(style['textDecorationLine'], contains('underline'));
    }, skip: skip);

    test('muted reads the muted colour', () async {
      expectColour(await read('#muted'), '--coui-on-surface-variant');
    }, skip: skip);

    test('an acting link reveals the underline from its Clickable', () async {
      // The text sits inside the Clickable; it is the Clickable that is
      // hovered and focused, so the text reads that state off its group.
      const content = '#acting span';
      expect((await read(content))['textDecorationLine'], 'none');

      await page.hover('#acting');
      expect(
        (await read(content))['textDecorationLine'],
        contains('underline'),
      );

      await page.mouse.move(const pptr.Point(790, 590));
      expect((await read(content))['textDecorationLine'], 'none');
    }, skip: skip);

    test('an acting link reveals the underline on keyboard focus', () async {
      // Anchors come first in tab order: standard, muted, underlined; then
      // the acting link's Clickable.
      for (var i = 0; i < 4; i++) {
        await page.keyboard.press(pptr.Key.tab);
      }
      final active = await page.evaluate<String?>(
        '() => document.activeElement && document.activeElement.id',
      );
      expect(active, 'acting');
      expect(
        (await read('#acting span'))['textDecorationLine'],
        contains('underline'),
      );
    }, skip: skip);

    test(
      'an inline link is always underlined and wraps with the words',
      () async {
        final style = await read('#paragraph a');

        expectColour(style, '--coui-link');
        expect(style['textDecorationLine'], contains('underline'));
        expect(style['display'], 'inline');
        expect(
          style['rects'] as int,
          greaterThan(1),
          reason: 'the link did not break across lines in a 120px paragraph',
        );
      },
      skip: skip,
    );

    test(
      "every link underline is the font's own, never the 4px offset",
      () async {
        for (final selector in ['#standard', '#underlined', '#paragraph a']) {
          final style = await read(selector);
          expect(style['textUnderlineOffset'], 'auto', reason: selector);
          expect(style['textUnderlinePosition'], 'from-font', reason: selector);
        }
      },
      skip: skip,
    );
  });
}
