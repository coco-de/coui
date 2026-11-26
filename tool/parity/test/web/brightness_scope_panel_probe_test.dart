// A panel opened inside a `BrightnessScope`, rendered — what a real Chrome
// with the vendored Tailwind draws for it.
//
// The Web unit tests pin that the panel is mounted inside a scope stated
// again around it (`packages/coui_web/test/base/brightness_scope_panel_test.dart`).
// That proves the markup, not what the browser does with it: that the
// scope's variables reach a panel the host lifts into the top layer, and
// that the panel then paints what a panel inside the scope paints. Those
// claims live in the computed style, so this file reads it.
//
// The page is light and the scope dark. A panel exists only after a click
// on a hydrated page, so this compiles a client entry
// (`src/web/brightness_scope_panel_entry.dart`) and clicks it open — the
// context menu with a right-click, the browser event no VM test can build.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

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

/// What the element with an id draws: its text colour, the surface variable
/// it sees, and the background of the nearest ancestor that paints one.
typedef _Seen = ({String color, String surface, String? fill});

/// The [_Seen] that [_read] returned as JSON.
_Seen _decode(String json) {
  final map = jsonDecode(json) as Map<String, dynamic>;

  return (
    color: map['color'] as String,
    surface: map['surface'] as String,
    fill: map['fill'] as String?,
  );
}

/// Reads [id] as a [_Seen], as JSON.
String _read(String id) =>
    '''
() => {
  const el = document.getElementById('$id');
  const cs = getComputedStyle(el);
  let fill = null;
  for (let node = el; node; node = node.parentElement) {
    const bg = getComputedStyle(node).backgroundColor;
    if (bg !== 'rgba(0, 0, 0, 0)' && bg !== 'transparent') {
      fill = bg;
      break;
    }
  }
  return JSON.stringify({
    color: cs.color,
    surface: cs.getPropertyValue('--coui-surface').trim(),
    fill: fill,
  });
}''';

/// Whether the element with [id] exists and the nearest ancestor painting a
/// background is the panel's own box — not one around the trigger too, which
/// is the page, before the panel's classes have been generated.
String _painted(String id, String trigger) =>
    '''
() => {
  const el = document.getElementById('$id');
  if (el === null) return false;
  for (let node = el; node; node = node.parentElement) {
    const bg = getComputedStyle(node).backgroundColor;
    if (bg !== 'rgba(0, 0, 0, 0)' && bg !== 'transparent') {
      return !node.contains(document.getElementById('$trigger'));
    }
  }
  return false;
}''';

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();
  final skip = chromePath == null;

  group('BrightnessScopePanelProbe — a panel opened inside a scope', () {
    late Directory fixture;
    late File html;

    setUpAll(() async {
      if (skip) return;
      fixture = Directory.systemTemp.createTempSync(
        'coui-parity-brightness-scope-panel-',
      );
      final js = p.join(fixture.path, 'entry.js');
      final result = await Process.run(Platform.resolvedExecutable, [
        'compile',
        'js',
        '-O2',
        '-o',
        js,
        'tool/parity/src/web/brightness_scope_panel_entry.dart',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
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

    /// Loads the page in a fresh browser, runs [open] once it has hydrated,
    /// waits for [panel] to paint, and reads [ids]. One page per panel: the
    /// overlay engine keeps one panel open at a time.
    Future<Map<String, _Seen>> openAndRead(
      Future<void> Function(pptr.Page chrome) open, {
      required String panel,
      required String trigger,
      required List<String> ids,
    }) async {
      final browser = await pptr.puppeteer.launch(executablePath: chromePath);
      try {
        final chrome = await browser.newPage();
        await chrome.setOfflineMode(true);
        await chrome.setViewport(
          const pptr.DeviceViewport(width: 1024, height: 768),
        );
        final _ = await chrome.goto(
          Uri.file(html.path).toString(),
          wait: pptr.Until.load,
        );
        await chrome.waitForFunction(
          "() => document.getElementById('$trigger') !== null",
        );
        await open(chrome);
        await chrome.waitForFunction(_painted(panel, trigger));

        return {
          for (final id in ids)
            id: _decode(await chrome.evaluate<String>(_read(id))),
        };
      } finally {
        await browser.close();
      }
    }

    Future<Map<String, _Seen>> openPopover(String name) => openAndRead(
      (chrome) => chrome.click('#$name-trigger'),
      panel: '$name-panel',
      trigger: '$name-trigger',
      ids: ['$name-panel', 'scope-text', 'page-text'],
    );

    test(
      'a popover paints what a popover inside the scope paints',
      () async {
        final scoped = await openPopover('scoped');
        final plain = await openPopover('plain');
        final hosted = await openPopover('hosted');

        final scope = scoped['scope-text']!;
        final page = scoped['page-text']!;
        // The two brightnesses differ, or a match below would prove
        // nothing.
        expect(scope.surface, isNot(page.surface));
        expect(hosted['hosted-panel']!.fill, isNotNull);
        expect(hosted['hosted-panel']!.fill, isNot(plain['plain-panel']!.fill));

        final panel = scoped['scoped-panel']!;
        expect(
          panel.surface,
          scope.surface,
          reason: 'the scope’s palette reaches the panel',
        );
        expect(
          panel.color,
          scope.color,
          reason: 'the scope restarts the text colour in the panel too',
        );
        expect(
          panel.fill,
          hosted['hosted-panel']!.fill,
          reason: 'the panel paints the dark panel, not the page’s light one',
        );
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'the popover panel has left the scope around its trigger',
      () async {
        final browser = await pptr.puppeteer.launch(executablePath: chromePath);
        try {
          final chrome = await browser.newPage();
          await chrome.setOfflineMode(true);
          final _ = await chrome.goto(
            Uri.file(html.path).toString(),
            wait: pptr.Until.load,
          );
          await chrome.waitForFunction(
            "() => document.getElementById('scoped-trigger') !== null",
          );
          await chrome.click('#scoped-trigger');
          await chrome.waitForFunction(
            _painted('scoped-panel', 'scoped-trigger'),
          );
          // What makes it dark is the scope stated around it in the host's
          // layer, not the wrapper around the trigger.
          final insideTriggerScope = await chrome.evaluate<bool>('''
() =>
  document.getElementById('scoped-trigger')
    .closest('[data-theme]:not(html)')
    .contains(document.getElementById('scoped-panel'))''');
          expect(insideTriggerScope, isFalse);
        } finally {
          await browser.close();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );

    test(
      'a context menu takes the scope’s palette',
      () async {
        final seen = await openAndRead(
          (chrome) =>
              chrome.click('#probe-context', button: pptr.MouseButton.right),
          panel: 'context-panel',
          trigger: 'probe-context',
          ids: ['context-panel', 'scope-text', 'page-text'],
        );

        final scope = seen['scope-text']!;
        expect(scope.surface, isNot(seen['page-text']!.surface));
        expect(
          seen['context-panel']!.surface,
          scope.surface,
          reason: 'the scope’s palette reaches the menu',
        );
        expect(
          seen['context-panel']!.color,
          scope.color,
          reason: 'the scope restarts the text colour in the menu too',
        );
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
