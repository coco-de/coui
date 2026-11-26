// The Diff's focus ring, judged in Chrome.
//
// The ring is a keyboard signal. A press that gives the comparison focus —
// with a mouse, the component takes that focus itself — must not draw it, and
// a key the comparison handles brings it back. `:focus-visible` alone cannot
// say which happened: Chrome can match it for a script `focus()` — on a page
// that has had no focus yet, and after keyboard use — which would put the
// keyboard ring on a mouse press and leave it there after the button comes up.
// The VM tests cannot see that
// (`tool/parity/src/web/diff_pointer_focus_entry.dart` is the shipped
// component on a page):
//
// * a mouse press, a drag and the release leave the comparison focused with
//   no ring — on a fresh page, and with the page in keyboard modality;
// * Tab onto the comparison draws the ring, and the next mouse press hides it;
// * a handled key after a mouse press brings the ring back, and so does
//   keyboard focus after the comparison loses focus — including when the
//   press landed on a comparison that already held it;
// * a finger tap (emulated touch) draws no ring.
//
// A run with no Chrome on the machine is skipped, not zeroed.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

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

Future<void> _settle(pptr.Page page) => page.evaluate<void>('''
() => new Promise(
  (done) => requestAnimationFrame(() => requestAnimationFrame(
    () => requestAnimationFrame(() => requestAnimationFrame(done))))
)''');

/// Where the comparison is, as numbers a mouse can aim at.
///
/// The ring is drawn on the handle's wrapper, the first child of the strip.
/// At rest that wrapper keeps a transparent outline so the ring can fade in,
/// so a ring is an outline that is *painted*: a style, a width and a colour
/// with some opacity.
const String _kStateJs = r'''
() => {
  const root = document.querySelector('[role="slider"]');
  const strip = root.querySelector('.coui-diff-handle-strip');
  const host = strip.firstElementChild;
  const alpha = (c) => {
    const m = c.match(/rgba?\(([^)]+)\)/);
    if (!m) return 1;
    const parts = m[1].split(/[ ,\/]+/).filter(Boolean);
    return parts.length > 3 ? parseFloat(parts[3]) : 1;
  };
  const cs = getComputedStyle(host);
  const ringPainted = cs.outlineStyle !== 'none' &&
      parseFloat(cs.outlineWidth) > 0 && alpha(cs.outlineColor) > 0;
  const r = root.getBoundingClientRect();
  const s = strip.getBoundingClientRect();
  return JSON.stringify({
    active: document.activeElement === root,
    ring: ringPainted,
    value: parseInt(root.getAttribute('aria-valuenow'), 10),
    dragging: root.hasAttribute('data-coui-dragging'),
    stripX: s.left + s.width / 2,
    y: r.top + r.height / 2,
    left: r.left,
    right: r.right,
  });
}
''';

Future<Map<String, Object?>> _state(pptr.Page page) async =>
    jsonDecode(await page.evaluate<String>(_kStateJs)) as Map<String, Object?>;

/// The state once the ring has finished fading to [ring].
///
/// The ring fades in and out on a transition, so a read a few frames after a
/// press can catch it half way and see a ring that is on its way out. This
/// waits for the fade (and gives up after a second, returning what it saw).
Future<Map<String, Object?>> _stateWithRing(
  pptr.Page page, {
  required bool ring,
}) async {
  var state = await _state(page);
  for (var i = 0; i < 20 && state['ring'] != ring; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state = await _state(page);
  }
  return state;
}

pptr.Point _at(num x, num y) => pptr.Point(x.toDouble(), y.toDouble());

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
    fixture = Directory.systemTemp.createTempSync('coui-diff-focus-probe-');
    final js = p.join(fixture.path, 'entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O1',
      '-o',
      js,
      'tool/parity/src/web/diff_pointer_focus_entry.dart',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
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

  final unsetNote = (Platform.environment['CHROME_EXECUTABLE'] ?? '').isEmpty
      ? ' (CHROME_EXECUTABLE unset)'
      : '';
  final skip = chromePath == null
      ? 'no local Chrome — tried ${candidates.join(', ')}$unsetNote; '
            'the focus ring cannot be checked against Chrome here'
      : null;

  Future<pptr.Page> openPage() async {
    final page = await browser.newPage();
    await page.setViewport(const pptr.DeviceViewport(width: 800, height: 600));
    await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
    await page.waitForSelector('[role="slider"] .coui-diff-handle-strip');
    await _settle(page);
    return page;
  }

  /// Puts the page in keyboard modality: Tab onto the button ahead of the
  /// comparison. A script `focus()` after this is what Chrome matches with
  /// `:focus-visible`.
  Future<void> tabOntoButton(pptr.Page page) async {
    await page.keyboard.press(pptr.Key.tab);
    await _settle(page);
    final onButton = await page.evaluate<bool>(
      "() => document.activeElement?.id === 'ahead'",
    );
    expect(onButton, isTrue, reason: 'the first Tab lands on the button');
  }

  group('a Diff', () {
    test('rests with no focus and no ring', () async {
      final page = await openPage();
      try {
        final state = await _state(page);

        expect(state['active'], isFalse);
        expect(state['ring'], isFalse);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'pressed with a mouse on a fresh page: focused, and no ring',
      () async {
        final page = await openPage();
        try {
          final at = await _state(page);
          final x = (at['left']! as num) + 60;
          final y = at['y']! as num;

          await page.mouse.move(_at(x, y));
          await page.mouse.down();
          await _settle(page);
          final pressed = await _state(page);
          expect(pressed['active'], isTrue, reason: 'the press focuses it');
          expect(pressed['dragging'], isTrue);
          expect(pressed['ring'], isFalse, reason: 'held with a mouse');

          await page.mouse.up();
          await _settle(page);
          final released = await _state(page);
          expect(released['active'], isTrue);
          expect(released['ring'], isFalse, reason: 'and after it comes up');
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test(
      'pressed with a mouse after Tab elsewhere: no ring, held or released',
      () async {
        final page = await openPage();
        try {
          await tabOntoButton(page);
          final at = await _state(page);
          final x = (at['left']! as num) + 60;
          final y = at['y']! as num;

          await page.mouse.move(_at(x, y));
          await page.mouse.down();
          await _settle(page);
          final held = await _state(page);
          expect(held['ring'], isFalse, reason: 'held');

          await page.mouse.move(_at(x + 120, y));
          await _settle(page);
          final dragged = await _state(page);
          expect(dragged['ring'], isFalse, reason: 'dragged');
          expect(
            dragged['value']! as int,
            greaterThan(held['value']! as int),
            reason: 'the split followed the mouse',
          );

          await page.mouse.up();
          await _settle(page);
          final released = await _state(page);
          expect(released['active'], isTrue);
          expect(released['ring'], isFalse, reason: 'released');
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('pressed on the handle itself: no ring either', () async {
      final page = await openPage();
      try {
        await tabOntoButton(page);
        final at = await _state(page);

        await page.mouse.move(_at(at['stripX']! as num, at['y']! as num));
        await page.mouse.down();
        await _settle(page);
        expect((await _state(page))['ring'], isFalse, reason: 'held');
        await page.mouse.up();
        await _settle(page);
        final released = await _state(page);
        expect(released['active'], isTrue);
        expect(released['ring'], isFalse, reason: 'released');
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'reached with Tab: the keyboard ring, off at the next press',
      () async {
        final page = await openPage();
        try {
          await tabOntoButton(page);
          await page.keyboard.press(pptr.Key.tab);
          await _settle(page);
          final reached = await _state(page);
          expect(reached['active'], isTrue);
          expect(reached['ring'], isTrue, reason: 'keyboard focus rings');

          final x = (reached['left']! as num) + 60;
          await page.mouse.click(_at(x, reached['y']! as num));
          final pressed = await _stateWithRing(page, ring: false);
          expect(pressed['active'], isTrue);
          expect(
            pressed['ring'],
            isFalse,
            reason: 'a press takes the ring off',
          );
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('a handled key after a mouse press brings the ring back', () async {
      final page = await openPage();
      try {
        await tabOntoButton(page);
        final at = await _state(page);
        await page.mouse.click(_at((at['left']! as num) + 60, at['y']! as num));
        await _settle(page);
        final pressed = await _state(page);
        expect(pressed['ring'], isFalse);
        final before = pressed['value']! as int;

        await page.keyboard.press(pptr.Key.arrowRight);
        await _settle(page);
        final keyed = await _state(page);
        expect(keyed['ring'], isTrue, reason: 'a key is keyboard use');
        expect(keyed['value']! as int, greaterThan(before));
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('Tab away and back after a mouse press rings again', () async {
      final page = await openPage();
      try {
        final at = await _state(page);
        await page.mouse.click(_at((at['left']! as num) + 60, at['y']! as num));
        await _settle(page);
        expect((await _state(page))['ring'], isFalse);

        // Leave (blur) and come back by keyboard: the press that focused it
        // must not still be remembered.
        await page.keyboard.down(pptr.Key.shift);
        await page.keyboard.press(pptr.Key.tab);
        await page.keyboard.up(pptr.Key.shift);
        await _settle(page);
        expect((await _state(page))['active'], isFalse);
        await page.keyboard.press(pptr.Key.tab);
        await _settle(page);
        final back = await _state(page);
        expect(back['active'], isTrue);
        expect(back['ring'], isTrue, reason: 'keyboard focus rings again');
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'a press on one that already has focus is forgotten once it blurs',
      () async {
        final page = await openPage();
        try {
          await tabOntoButton(page);
          await page.keyboard.press(pptr.Key.tab);
          await _settle(page);
          final reached = await _state(page);
          expect(reached['ring'], isTrue);

          // Already focused: the press raises no `focus` event to use it up.
          final x = (reached['left']! as num) + 60;
          await page.mouse.click(_at(x, reached['y']! as num));
          await _stateWithRing(page, ring: false);

          await page.keyboard.down(pptr.Key.shift);
          await page.keyboard.press(pptr.Key.tab);
          await page.keyboard.up(pptr.Key.shift);
          await _settle(page);
          expect((await _state(page))['active'], isFalse);
          await page.keyboard.press(pptr.Key.tab);
          final back = await _stateWithRing(page, ring: true);
          expect(back['active'], isTrue);
          expect(
            back['ring'],
            isTrue,
            reason: 'the old press must not hide a later keyboard focus',
          );
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('tapped with a finger after Tab elsewhere: no ring', () async {
      final page = await browser.newPage();
      try {
        await page.setViewport(
          const pptr.DeviceViewport(width: 800, height: 600, hasTouch: true),
        );
        await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
        await page.waitForSelector('[role="slider"] .coui-diff-handle-strip');
        await _settle(page);
        await tabOntoButton(page);
        final at = await _state(page);

        await page.touchscreen.tap(
          _at(at['stripX']! as num, at['y']! as num),
        );
        await _settle(page);
        final onHandle = await _state(page);
        expect(onHandle['active'], isTrue, reason: 'the tap focuses it');
        expect(onHandle['ring'], isFalse, reason: 'tapped on the handle');

        await page.keyboard.press(pptr.Key.tab);
        await _settle(page);
        await page.touchscreen.tap(
          _at((at['left']! as num) + 60, at['y']! as num),
        );
        await _settle(page);
        final elsewhere = await _state(page);
        expect(elsewhere['ring'], isFalse, reason: 'tapped off the handle');
      } finally {
        await page.close();
      }
    }, skip: skip);
  });
}
