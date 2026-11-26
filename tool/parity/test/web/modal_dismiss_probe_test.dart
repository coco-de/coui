// The modal dismiss control, judged in Chrome.
//
// A modal surface leaves the page behind it `inert` and its scrim
// `aria-hidden`, so a screen-reader user has nothing to click and, on a touch
// device, no `Escape`. The Web puts a phantom button beside the panel
// (`modalDismissControl`) — the twin of the `dismiss` action the Flutter seat
// attaches to the same surfaces. The VM test pins which surfaces carry it and
// what it is named; what only a browser decides is judged here, on the
// shipped components (`tool/parity/src/web/modal_dismiss_entry.dart`):
//
// * it is really clipped to a 1px box (`sr-only` is a class a stylesheet has
//   to deliver) and takes no part in layout;
// * it is never a tab stop — Tab walks past it, however long it is pressed;
// * a click (what assistive technology delivers when it activates a node) and
//   `Enter` / space on a focused control close the surface, and closing gives
//   the page behind it back;
// * the surfaces that must not carry it, do not — a non-modal popover and a
//   modal one that ignores outside clicks — and an anchored menu and a
//   context menu opened by a real right click do.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// Where the probe looks for Chrome, in order: `CHROME_EXECUTABLE` when it is
/// set — CI's web-selection job sets it to the runner's browser — then the
/// system installs the other probes look in.
List<String> _chromeCandidates() => [
  if (Platform.environment['CHROME_EXECUTABLE'] case final String chrome
      when chrome.isNotEmpty)
    chrome,
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/google-chrome-stable',
  '/usr/bin/chromium-browser',
  '/usr/bin/chromium',
];

/// What the browser says about the control and the page behind it.
const String _kStateJs = '''
() => {
  const controls = [...document.querySelectorAll('[data-coui-modal-dismiss]')];
  const c = controls[0];
  const cs = c ? getComputedStyle(c) : null;
  const r = c ? c.getBoundingClientRect() : null;
  const backdrop = document.querySelector('[data-coui-backdrop]');
  return JSON.stringify({
    count: controls.length,
    role: c ? c.getAttribute('role') : null,
    tabindex: c ? c.getAttribute('tabindex') : null,
    label: c ? c.getAttribute('aria-label') : null,
    hasPopoverAttr: c ? c.hasAttribute('popover') : null,
    position: cs ? cs.position : null,
    width: r ? r.width : null,
    height: r ? r.height : null,
    insideBackdrop: c ? !!c.closest('[data-coui-backdrop]') : null,
    backdropInert: backdrop ? backdrop.hasAttribute('inert') : null,
    activeIsControl: !!c && document.activeElement === c,
  });
}
''';

/// Whether keyboard focus is on the control right now.
const String _kFocusOnControlJs = '''
() => {
  const c = document.querySelector('[data-coui-modal-dismiss]');
  return !!c && document.activeElement === c;
}
''';

Future<Map<String, Object?>> _state(pptr.Page page) async =>
    jsonDecode(await page.evaluate<String>(_kStateJs)) as Map<String, Object?>;

/// Waits a few frames, so a state change and the render it causes have landed.
Future<void> _settle(pptr.Page page) => page.evaluate<void>('''
() => new Promise(
  (done) => requestAnimationFrame(() => requestAnimationFrame(
    () => requestAnimationFrame(() => requestAnimationFrame(done))))
)''');

Future<void> _waitForControl(pptr.Page page) async {
  await page.waitForFunction(
    "() => document.querySelector('[data-coui-modal-dismiss]') !== null",
  );
  await _settle(page);
}

/// The control is gone once the surface has played its exit and unmounted.
Future<void> _waitForClosed(pptr.Page page) async {
  await page.waitForFunction(
    "() => document.querySelector('[data-coui-modal-dismiss]') === null",
  );
  await _settle(page);
}

void main() {
  final candidates = _chromeCandidates();
  final chromePath = candidates
      .where((candidate) => File(candidate).existsSync())
      .firstOrNull;

  late pptr.Browser browser;
  late Directory fixture;
  late File html;

  setUpAll(() async {
    if (chromePath == null) return;
    fixture = Directory.systemTemp.createTempSync('coui-modal-dismiss-probe-');
    final js = p.join(fixture.path, 'entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O1',
      '-o',
      js,
      'tool/parity/src/web/modal_dismiss_entry.dart',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    // Real motion: the surface unmounts after its exit animation, which is
    // part of what closing means here.
    final content = buildOfflineTailwindHarnessHtml(
      bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>',
    ).replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
    html = File(p.join(fixture.path, 'index.html'))..writeAsStringSync(content);
    browser = await launchCaptureBrowser(
      width: 800,
      height: 600,
      executablePath: chromePath,
    );
  });

  tearDownAll(() async {
    if (chromePath == null) return;
    await browser.close();
    fixture.deleteSync(recursive: true);
  });

  // The skip says where it looked, so a skipped run is not read as a pass.
  final unsetNote = (Platform.environment['CHROME_EXECUTABLE'] ?? '').isEmpty
      ? ' (CHROME_EXECUTABLE unset)'
      : '';
  final skip = chromePath == null
      ? 'no local Chrome — tried ${candidates.join(', ')}$unsetNote; '
            'the dismiss control cannot be checked against Chrome here'
      : null;

  Future<pptr.Page> openPage() async {
    final page = await browser.newPage();
    await page.setViewport(pptr.DeviceViewport(width: 800, height: 600));
    await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
    await page.waitForSelector('#pop-trigger');
    await _settle(page);

    return page;
  }

  group('a modal popover', () {
    test('carries a phantom button the browser really hides', () async {
      final page = await openPage();
      try {
        await page.click('#pop-trigger');
        await _waitForControl(page);
        final state = await _state(page);

        expect(state['count'], 1);
        expect(state['role'], 'button');
        expect(state['label'], 'Dismiss');
        expect(state['tabindex'], '-1');
        expect(
          state['hasPopoverAttr'],
          isFalse,
          reason: 'not a top-layer panel',
        );
        // `sr-only`: absolute and 1px — present for assistive technology,
        // nothing for the eye or for layout.
        expect(state['position'], 'absolute');
        expect(state['width'], 1);
        expect(state['height'], 1);
        // Beside the panel, outside the `inert` page — reachable.
        expect(state['insideBackdrop'], isFalse);
        expect(state['backdropInert'], isTrue, reason: 'the page is blocked');
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('is never a tab stop', () async {
      final page = await openPage();
      try {
        await page.click('#pop-trigger');
        await _waitForControl(page);

        // The panel holds nothing focusable and the page is inert, so Tab
        // leaves the document and wraps. Enough presses to go around twice.
        for (var i = 0; i < 8; i++) {
          await page.keyboard.press(pptr.Key.tab);
          expect(
            await page.evaluate<bool>(_kFocusOnControlJs),
            isFalse,
            reason: 'Tab press ${i + 1} landed on the invisible control',
          );
        }
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a click on it closes the surface and gives the page back', () async {
      final page = await openPage();
      try {
        await page.click('#pop-trigger');
        await _waitForControl(page);
        // What assistive technology delivers when it activates the node.
        await page.evaluate<void>(
          "() => document.querySelector('[data-coui-modal-dismiss]').click()",
        );
        await _waitForClosed(page);

        expect(
          await page.evaluate<bool>(
            "() => !document.querySelector('[data-coui-backdrop]')"
            ".hasAttribute('inert')",
          ),
          isTrue,
          reason: 'closing makes the page behind it reachable again',
        );
        expect(
          await page.evaluate<bool>(
            "() => !document.body.textContent.includes('Modal body')",
          ),
          isTrue,
          reason: 'and the panel is gone',
        );
      } finally {
        await page.close();
      }
    }, skip: skip);

    for (final (name, key) in [
      ('Enter', pptr.Key.enter),
      ('space', pptr.Key.space),
    ]) {
      test('$name on the focused control closes the surface', () async {
        final page = await openPage();
        try {
          await page.click('#pop-trigger');
          await _waitForControl(page);
          // A reader that moves focus onto the node (programmatic focus works
          // on a `tabindex="-1"` element), then presses a key.
          await page.evaluate<void>(
            "() => document.querySelector('[data-coui-modal-dismiss]')"
            '.focus()',
          );
          expect(await page.evaluate<bool>(_kFocusOnControlJs), isTrue);
          await page.keyboard.press(key);
          await _waitForClosed(page);
        } finally {
          await page.close();
        }
      }, skip: skip);
    }
  });

  group('the surfaces that carry none', () {
    test('a non-modal popover leaves the page reachable', () async {
      final page = await openPage();
      try {
        await page.click('#pop-plain-trigger');
        await page.waitForFunction(
          "() => document.body.textContent.includes('Plain body')",
        );
        await _settle(page);

        expect((await _state(page))['count'], 0);
        expect(
          await page.evaluate<bool>(
            "() => !document.querySelector('[data-coui-backdrop]')"
            ".hasAttribute('inert')",
          ),
          isTrue,
        );
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a modal popover that ignores outside clicks offers none', () async {
      final page = await openPage();
      try {
        await page.click('#pop-sticky-trigger');
        await page.waitForFunction(
          "() => document.body.textContent.includes('Sticky body')",
        );
        await _settle(page);

        expect((await _state(page))['count'], 0);
      } finally {
        await page.close();
      }
    }, skip: skip);
  });

  group('the menus', () {
    test('an anchored menu offers it, and it closes the menu', () async {
      final page = await openPage();
      try {
        await page.click('#dd-trigger');
        await _waitForControl(page);
        expect((await _state(page))['label'], 'Dismiss');

        await page.evaluate<void>(
          "() => document.querySelector('[data-coui-modal-dismiss]').click()",
        );
        await _waitForClosed(page);
        expect(
          await page.evaluate<bool>(
            "() => document.querySelector('#coui-overlay-menu [role=\"menu\"]')"
            ' === null',
          ),
          isTrue,
        );
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a context menu opened by a right click offers it too', () async {
      final page = await openPage();
      try {
        final box = await (await page.$('#cm-area')).boundingBox;
        await page.mouse.click(
          pptr.Point(box!.left + 20, box.top + 20),
          button: pptr.MouseButton.right,
        );
        await _waitForControl(page);
        expect((await _state(page))['count'], 1);

        await page.evaluate<void>(
          "() => document.querySelector('[data-coui-modal-dismiss]').click()",
        );
        await _waitForClosed(page);
      } finally {
        await page.close();
      }
    }, skip: skip);
  });
}
