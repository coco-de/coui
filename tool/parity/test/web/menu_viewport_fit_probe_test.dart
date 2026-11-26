// Menus that do not fit the viewport — the Chrome half of the shared fit
// vectors, and of the wiring the Flutter engine has no counterpart for.
//
// The Web states a held panel in CSS and lets the browser lay it out: the
// positioner measures the panel, `CoreOverlayFit` says how much room it has,
// and the `Menu` holds its own box to `max-height` and scrolls its rows in a
// list inside the box (`overflow-y: auto`). Flutter caps the panel with a
// layout constraint instead. They agree only if the browser really scrolls the
// list that was marked, really reports that it holds more than it shows
// (`scrollHeight`), leaves the capped box itself still — the border, the
// corners, the shadow and a glass rim drawn inside the box would scroll away
// with a scrolling box — and does not flip between held and free as the
// measurement feeds back into the next update — all of which are browser
// behaviour, so this file compiles the shipped positioner and hosts
// (`tool/parity/src/web/menu_fit_entry.dart`) and judges them in Chrome.
//
// Two groups:
//
// * the positioner on its own, fed every vector of the shared table (the
//   panel's natural height and the viewport's paddings) at that vector's
//   viewport height — the Chrome half of what the Core and Flutter tests read;
// * the real `DropdownMenu` / `ContextMenu` / `Menubar` with thirty rows in a
//   phone-sized viewport: inside the viewport, scrollable to the last row,
//   and that row reachable by pointer — plus the roles and the Escape of an
//   anchored panel opened from the keyboard.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// The table shared with the Core test and the Flutter engine test.
const String _kVectorsPath =
    'packages/coui_core/test/fixtures/overlay_fit_vectors.json';

/// Chrome lays boxes out in 1/64 px; the table states whole and half pixels.
const double _kTolerance = 0.5;

/// A phone-sized viewport — the one the shared table's headline case is for.
const int _kPhoneWidth = 360;
const int _kPhoneHeight = 480;

/// The panel's distance from the viewport edge the positioner keeps by
/// default (`CorePopoverStyle.defaultViewportPadding`).
const double _kMargin = 8;

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

double _n(Map<String, Object?> map, String key) =>
    (map[key]! as num).toDouble();

/// The positioner-only panel: its box, its scroller and what the browser says
/// about both. The cap is on the box; the list inside it is what scrolls.
const String _kMeasureRawJs = '''
() => {
  const panel = document.getElementById('fit-panel');
  const held = document.getElementById('fit-box');
  const root = document.getElementById('fit-root');
  const box = panel.getBoundingClientRect();
  return JSON.stringify({
    top: box.top, bottom: box.bottom, height: box.height,
    scrollHeight: root.scrollHeight, clientHeight: root.clientHeight,
    overflowY: getComputedStyle(root).overflowY,
    maxHeight: held.style.maxHeight,
    className: root.className,
    innerHeight: window.innerHeight,
  });
}
''';

/// The real menu's box, read off the menu layer, and the list that scrolls
/// inside it (the box itself while the panel fits and nothing scrolls).
const String _kMeasureMenuJs = '''
() => {
  const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
  if (!menu) return JSON.stringify(null);
  const scroller = menu.querySelector('.co-fit-scroller');
  const scrolls = scroller || menu;
  const box = menu.getBoundingClientRect();
  const rows = [...menu.querySelectorAll('[role="menuitem"]')];
  const centre = (el) => {
    const r = el.getBoundingClientRect();
    return {x: r.left + r.width / 2, y: r.top + r.height / 2};
  };
  const hit = (el) => {
    const c = centre(el);
    const at = document.elementFromPoint(c.x, c.y);
    return !!at && el.contains(at);
  };
  return JSON.stringify({
    top: box.top, bottom: box.bottom, height: box.height,
    scrollHeight: scrolls.scrollHeight, clientHeight: scrolls.clientHeight,
    overflowY: getComputedStyle(scrolls).overflowY,
    overflowX: getComputedStyle(scrolls).overflowX,
    maxHeight: menu.style.maxHeight,
    className: scrolls.className,
    hasScroller: !!scroller,
    boxClassName: menu.className,
    boxOverflowY: getComputedStyle(menu).overflowY,
    boxScrollHeight: menu.scrollHeight, boxClientHeight: menu.clientHeight,
    boxScrollTop: menu.scrollTop,
    innerHeight: window.innerHeight,
    rowCount: rows.length,
    firstReachable: rows.length > 0 && hit(rows[0]),
    lastReachable: rows.length > 0 && hit(rows[rows.length - 1]),
    lastCentre: rows.length > 0 ? centre(rows[rows.length - 1]) : null,
    scrollTop: scrolls.scrollTop,
  });
}
''';

void main() {
  final candidates = _chromeCandidates();
  final chromePath = candidates
      .where((candidate) => File(candidate).existsSync())
      .firstOrNull;
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  late pptr.Browser browser;
  late Directory fixture;
  late File html;

  setUpAll(() async {
    if (chromePath == null) return;
    fixture = Directory.systemTemp.createTempSync('coui-menu-fit-probe-');
    final js = p.join(fixture.path, 'entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O1',
      '-o',
      js,
      'tool/parity/src/web/menu_fit_entry.dart',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    // Real motion: the hosts' enter / exit animations are part of what is
    // being judged (the panel must be measurable while it animates in).
    final content = buildOfflineTailwindHarnessHtml(
      bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
      themeConfig: ThemeConfig.defaults(),
      vendoredTailwindScript: loadVendoredTailwindScript(),
      additionalHeadHtml: '<style>body{margin:0}</style>',
    ).replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
    html = File(p.join(fixture.path, 'index.html'))..writeAsStringSync(content);
    browser = await launchCaptureBrowser(
      width: _kPhoneWidth,
      height: _kPhoneHeight,
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
            'the fit vectors cannot be checked against Chrome here'
      : null;

  Future<pptr.Page> openPage({int height = _kPhoneHeight}) async {
    final page = await browser.newPage();
    await page.setViewport(
      pptr.DeviceViewport(width: _kPhoneWidth, height: height),
    );
    await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
    await page.waitForFunction(
      'typeof couiFitConfigure === "function" && '
      'typeof couiFitStart === "function"',
    );
    await _settle(page);

    return page;
  }

  group('the positioner against the shared vectors', () {
    for (final c in cases) {
      final viewport = _n(c, 'viewport');
      final extent = _n(c, 'extent');
      // A browser window is a whole number of pixels tall, and a panel with
      // no height has no box to place — those two rows of the table are
      // judged by the Core and Flutter tests.
      final skipCase = viewport != viewport.roundToDouble()
          ? 'a fractional viewport height cannot be emulated'
          : extent <= 0
          ? 'an empty panel has no box to place'
          : skip;

      test(c['name']! as String, () async {
        final page = await openPage(height: viewport.round());
        try {
          final before = _n(c, 'paddingBefore');
          final after = _n(c, 'paddingAfter');
          await page.evaluate<void>(
            '(e, b, a) => couiFitConfigure(e, b, a)',
            args: [extent, before, after],
          );
          await _settle(page);
          await page.evaluate<void>('() => couiFitStart()');
          await page.waitForFunction(
            "document.getElementById('fit-panel').style.top !== ''",
          );
          await _settle(page);

          final measured = await _measureRaw(page);
          final fit = c['fit']! as Map<String, Object?>;
          final capped = fit['capped']! as bool;
          final height = measured['height']! as num;
          expect(
            height.toDouble(),
            closeTo(_n(fit, 'extent'), _kTolerance),
            reason: 'the panel is ${capped ? 'held to the room' : 'free'}',
          );
          if (capped) {
            expect(
              (measured['top']! as num).toDouble(),
              closeTo(_n(fit, 'start'), _kTolerance),
              reason: 'a panel that took all the room sits at its start',
            );
            if (_n(c, 'room') > 0) {
              expect(
                (measured['bottom']! as num).toDouble(),
                lessThanOrEqualTo(viewport - after + _kTolerance),
                reason: 'and ends inside the paddings',
              );
            }
            expect(measured['overflowY'], 'auto');
            expect(
              (measured['scrollHeight']! as num) -
                  (measured['clientHeight']! as num),
              greaterThanOrEqualTo(1),
              reason: 'the rows beyond the room are in the scroller',
            );
            expect(measured['className'], contains('co-fit-scroller'));
          } else {
            expect(measured['maxHeight'], isEmpty, reason: 'no cap emitted');
            expect(
              measured['className'],
              isNot(contains('co-fit-scroller')),
              reason: 'and no marker',
            );
          }
        } finally {
          await page.close();
        }
      }, skip: skipCase);
    }

    // Natural heights a fraction over the 464px room. The scroller's
    // `scrollHeight` and `clientHeight` are whole numbers, so for a fraction
    // under a half the overflow of a held panel reads as zero. Without
    // hysteresis that is one update free and the next held again.
    for (final natural in [464.4, 464.7]) {
      test(
        'a panel $natural px tall in a 464px room stays held across updates',
        () async {
          final page = await openPage();
          try {
            await page.evaluate<void>(
              '(e, b, a) => couiFitConfigure(e, b, a)',
              args: [natural, _kMargin, _kMargin],
            );
            await _settle(page);
            await page.evaluate<void>('() => couiFitStart()');
            await page.waitForFunction(
              "document.getElementById('fit-panel').style.top !== ''",
            );
            await _settle(page);

            // The cap is rendered and measured once; nothing keeps measuring.
            final settled = await page.evaluate<int>('() => couiFitUpdates()');
            await _settle(page);
            await _settle(page);
            expect(
              await page.evaluate<int>('() => couiFitUpdates()'),
              settled,
              reason:
                  'a held panel is not measured again until something moves',
            );

            final seen = <String>{};
            for (var i = 0; i < 6; i++) {
              final measured = await _measureRaw(page);
              seen.add('${measured['maxHeight']}|${measured['height']}');
              // The scroll tracker re-measures on resize.
              await page.evaluate<void>(
                "() => window.dispatchEvent(new Event('resize'))",
              );
              await _settle(page);
            }

            expect(
              seen,
              hasLength(1),
              reason: 'held or free, the same answer every update: $seen',
            );
            expect(
              seen.single,
              startsWith('464px|'),
              reason: 'and it is the held one',
            );
          } finally {
            await page.close();
          }
        },
        skip: skip,
      );
    }

    test(
      "scrolling the held panel's own rows does not measure it again",
      () async {
        // `scroll` does not bubble, but the tracker listens on the window with
        // capture and so hears every element's. A held panel scrolls inside
        // itself by design; measuring and re-rendering per scroll step, for a
        // trigger that has not moved, would put a render between the pointer
        // and the rows.
        final page = await openPage();
        try {
          await page.evaluate<void>(
            '(e, b, a) => couiFitConfigure(e, b, a)',
            args: [1080, _kMargin, _kMargin],
          );
          await _settle(page);
          await page.evaluate<void>('() => couiFitStart()');
          await page.waitForFunction(
            "document.getElementById('fit-panel').style.top !== ''",
          );
          await _settle(page);
          final before = await page.evaluate<int>('() => couiFitUpdates()');
          expect(before, greaterThan(0), reason: 'it was measured once');

          for (var step = 1; step <= 5; step++) {
            await page.evaluate<void>(
              "(y) => { document.getElementById('fit-root').scrollTop = y; }",
              args: [step * 40],
            );
            await _settle(page);
          }

          expect(
            await page.evaluate<num>(
              "() => document.getElementById('fit-root').scrollTop",
            ),
            200,
            reason: 'the rows really scrolled',
          );
          expect(
            await page.evaluate<int>('() => couiFitUpdates()'),
            before,
            reason: 'and nothing was measured for it',
          );
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test(
      'a held panel is given more room again when the viewport grows',
      () async {
        // Only the scroller still knows how tall the panel really is; a capped
        // panel that hid its own size would stay at the old cap for good.
        final page = await openPage();
        try {
          await page.evaluate<void>(
            '(e, b, a) => couiFitConfigure(e, b, a)',
            args: [700, _kMargin, _kMargin],
          );
          await _settle(page);
          await page.evaluate<void>('() => couiFitStart()');
          await page.waitForFunction(
            "document.getElementById('fit-panel').style.top !== ''",
          );
          await _settle(page);
          var measured = await _measureRaw(page);
          expect(
            (measured['height']! as num).toDouble(),
            closeTo(_kPhoneHeight - 2 * _kMargin, _kTolerance),
            reason: 'held to a 480px viewport',
          );

          await page.setViewport(
            const pptr.DeviceViewport(width: _kPhoneWidth, height: 900),
          );
          await _settle(page);

          measured = await _measureRaw(page);
          expect(
            (measured['height']! as num).toDouble(),
            closeTo(700, _kTolerance),
            reason: 'the whole panel fits a 900px viewport',
          );
          expect(measured['maxHeight'], isEmpty);
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('a free panel is held when the viewport shrinks', () async {
      final page = await openPage(height: 900);
      try {
        await page.evaluate<void>(
          '(e, b, a) => couiFitConfigure(e, b, a)',
          args: [700, _kMargin, _kMargin],
        );
        await _settle(page);
        await page.evaluate<void>('() => couiFitStart()');
        await page.waitForFunction(
          "document.getElementById('fit-panel').style.top !== ''",
        );
        await _settle(page);
        var measured = await _measureRaw(page);
        expect((measured['height']! as num).toDouble(), closeTo(700, 0.5));

        await page.setViewport(
          const pptr.DeviceViewport(width: _kPhoneWidth, height: 400),
        );
        await _settle(page);

        measured = await _measureRaw(page);
        expect(
          (measured['height']! as num).toDouble(),
          closeTo(400 - 2 * _kMargin, _kTolerance),
        );
        expect((measured['top']! as num).toDouble(), closeTo(_kMargin, 0.5));
      } finally {
        await page.close();
      }
    }, skip: skip);
  });

  group('an anchored panel opened from the keyboard', () {
    test('is a vertical menu with the background inert behind it, and Escape '
        'closes it', () async {
      final page = await openPage();
      try {
        await page.focus('#dd-trigger');
        await page.keyboard.press(pptr.Key.enter);
        await _waitForMenu(page);

        var state = await _readAnchoredPanelState(page);
        printOnFailure('open: ${jsonEncode(state)}');
        expect(state['triggerRole'], 'button');
        expect(state['triggerHasPopup'], 'true');
        expect(state['triggerExpanded'], 'true', reason: 'it says it is open');
        expect(state['menuRole'], 'menu');
        expect(state['menuOrientation'], 'vertical');
        expect(
          state['modalOnAnyAncestor'],
          isFalse,
          reason:
              '`aria-modal` belongs to dialogs; a menu is contained by making '
              'what is behind it inert',
        );
        expect(
          state['backdropInert'],
          isTrue,
          reason: 'what is behind the panel is out of the tab order',
        );

        // With the background inert, Tab has one place to go: into the menu.
        await page.keyboard.press(pptr.Key.tab);
        await _settle(page);
        state = await _readAnchoredPanelState(page);
        expect(
          state['activeIsMenuItem'],
          isTrue,
          reason: 'Tab enters the menu',
        );

        // Escape is heard wherever focus is — here, on a row.
        await page.keyboard.press(pptr.Key.escape);
        await page.waitForFunction(
          "!document.querySelector('#coui-overlay-menu [role=\"menu\"]')",
          timeout: const Duration(seconds: 5),
        );
        await _settle(page);

        state = await _readAnchoredPanelState(page);
        printOnFailure('closed: ${jsonEncode(state)}');
        expect(state['menuRole'], isNull, reason: 'the panel is gone');
        expect(state['triggerExpanded'], 'false', reason: 'and it says so');
        expect(
          state['backdropInert'],
          isFalse,
          reason: 'and the page is live again',
        );
      } finally {
        await page.close();
      }
    }, skip: skip);
  });

  group('thirty menu rows in a phone-sized viewport', () {
    /// Everything a long menu owes the person using it, read off Chrome once
    /// it has opened.
    Future<void> expectReachableToTheLastRow(
      pptr.Page page, {
      required int rows,
      bool atTopOfRoom = false,
    }) async {
      var measured = await _measureMenu(page);
      expect(measured, isNotNull, reason: 'the menu opened');
      measured = measured!;
      printOnFailure('opened: ${jsonEncode(measured)}');
      expect(measured['rowCount'], rows);
      expect(
        (measured['top']! as num).toDouble(),
        greaterThanOrEqualTo(_kMargin - _kTolerance),
        reason: 'inside the viewport at the top',
      );
      expect(
        (measured['bottom']! as num).toDouble(),
        lessThanOrEqualTo(_kPhoneHeight - _kMargin + _kTolerance),
        reason: 'inside the viewport at the bottom',
      );
      if (atTopOfRoom) {
        // Neither side of the trigger has room: the panel takes the whole
        // viewport, so it sits at the top of it whatever the trigger does.
        expect(
          (measured['top']! as num).toDouble(),
          closeTo(_kMargin, _kTolerance),
          reason: 'a panel that takes all the room sits at its top',
        );
        expect(
          (measured['bottom']! as num).toDouble(),
          closeTo(_kPhoneHeight - _kMargin, _kTolerance),
        );
      }
      expect(measured['hasScroller'], isTrue, reason: 'a list holds the rows');
      expect(measured['overflowY'], 'auto', reason: 'the rows scroll');
      expect(
        measured['overflowX'],
        'hidden',
        reason: 'and the other axis stays hidden',
      );
      expect(
        (measured['scrollHeight']! as num) > (measured['clientHeight']! as num),
        isTrue,
        reason: 'there is more in the list than it shows',
      );
      expect(
        measured['boxOverflowY'],
        'hidden',
        reason: "the panel's own box does not scroll",
      );
      expect(
        measured['boxClassName'],
        isNot(contains('co-fit-scroller')),
        reason: 'and is not the list that does',
      );
      expect(
        (measured['boxScrollHeight']! as num).toDouble(),
        closeTo((measured['boxClientHeight']! as num).toDouble(), 1),
        reason: 'it holds nothing beyond what it shows',
      );
      expect(measured['firstReachable'], isTrue, reason: 'the first row');
      expect(
        measured['lastReachable'],
        isFalse,
        reason: 'the last row is below the fold until the box is scrolled',
      );

      await page.evaluate<void>('''
() => {
  const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
  const scroller = menu.querySelector('.co-fit-scroller');
  scroller.scrollTop = scroller.scrollHeight;
}''');
      await _settle(page);

      measured = (await _measureMenu(page))!;
      expect(
        measured['lastReachable'],
        isTrue,
        reason: 'scrolled to the end, the last row is under the pointer',
      );
      expect(
        measured['boxScrollTop'],
        0,
        reason:
            'only the list moved: the box, with all it is drawn with, did not',
      );

      final centre = measured['lastCentre']! as Map<String, Object?>;
      await page.mouse.click(
        pptr.Point(
          (centre['x']! as num).toDouble(),
          (centre['y']! as num).toDouble(),
        ),
      );
      await _settle(page);
      expect(
        await page.evaluate<String>('() => couiFitEvents()'),
        'Row $rows',
        reason: 'and activating it reports it',
      );
    }

    test('DropdownMenu, trigger at the top', () async {
      final page = await openPage();
      try {
        await page.click('#dd-trigger');
        await _waitForMenu(page);
        await expectReachableToTheLastRow(page, rows: 30);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('DropdownMenu, trigger in the middle of the viewport', () async {
      // Neither side of the trigger has room: the panel takes the viewport.
      final page = await openPage();
      try {
        await page.evaluate<void>(
          "() => { document.querySelector('#hosts > div').style.top = "
          "'230px'; }",
        );
        await _settle(page);
        await page.click('#dd-trigger');
        await _waitForMenu(page);
        await expectReachableToTheLastRow(page, rows: 30, atTopOfRoom: true);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('ContextMenu opened with a right click', () async {
      final page = await openPage();
      try {
        await page.mouse.click(
          const pptr.Point(40, 90),
          button: pptr.MouseButton.right,
        );
        await _waitForMenu(page);
        await expectReachableToTheLastRow(page, rows: 30);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('Menubar', () async {
      final page = await openPage();
      try {
        await page.click('#mb button');
        await _waitForMenu(page);
        await expectReachableToTheLastRow(page, rows: 30);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a menu that fits is left exactly as it was', () async {
      final page = await openPage();
      try {
        await page.click('#dd-short-trigger');
        await _waitForMenu(page);
        final measured = (await _measureMenu(page))!;
        expect(measured['rowCount'], 2);
        expect(measured['maxHeight'], isEmpty, reason: 'no cap emitted');
        expect(measured['overflowY'], 'hidden', reason: 'and nothing scrolls');
        expect(measured['hasScroller'], isFalse, reason: 'no list either');
        expect(measured['className'], isNot(contains('co-fit-scroller')));
        expect(
          (measured['scrollHeight']! as num).toDouble(),
          closeTo((measured['clientHeight']! as num).toDouble(), 1),
        );
      } finally {
        await page.close();
      }
    }, skip: skip);
  });
}

/// The anchored panel's roles and focus, as assistive technology and the tab
/// order see them.
const String _kAnchoredPanelJs = '''
() => {
  const active = document.activeElement;
  const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
  const trigger = document.querySelector('[aria-haspopup]');
  const backdrop = document.querySelector('[data-coui-backdrop]');
  let modalOnAnyAncestor = false;
  for (let node = menu; node; node = node.parentElement) {
    if (node.hasAttribute('aria-modal')) modalOnAnyAncestor = true;
  }
  return JSON.stringify({
    triggerRole: trigger ? trigger.getAttribute('role') : null,
    triggerHasPopup: trigger ? trigger.getAttribute('aria-haspopup') : null,
    triggerExpanded: trigger ? trigger.getAttribute('aria-expanded') : null,
    menuRole: menu ? menu.getAttribute('role') : null,
    menuOrientation: menu ? menu.getAttribute('aria-orientation') : null,
    modalOnAnyAncestor: modalOnAnyAncestor,
    backdropInert: backdrop ? backdrop.hasAttribute('inert') : null,
    activeIsMenuItem: !!active && active.getAttribute('role') === 'menuitem',
  });
}
''';

Future<Map<String, Object?>> _readAnchoredPanelState(pptr.Page page) async =>
    jsonDecode(await page.evaluate<String>(_kAnchoredPanelJs))
        as Map<String, Object?>;

/// Waits a few frames, so a state change, the render it causes and the
/// measurement that follows it have all landed.
Future<void> _settle(pptr.Page page) => page.evaluate<void>('''
() => new Promise(
  (done) => requestAnimationFrame(() => requestAnimationFrame(
    () => requestAnimationFrame(() => requestAnimationFrame(done))))
)''');

Future<Map<String, Object?>> _measureRaw(pptr.Page page) async =>
    jsonDecode(await page.evaluate<String>(_kMeasureRawJs))
        as Map<String, Object?>;

Future<Map<String, Object?>?> _measureMenu(pptr.Page page) async =>
    jsonDecode(await page.evaluate<String>(_kMeasureMenuJs))
        as Map<String, Object?>?;

/// Waits for the menu to be in the overlay layer, positioned, and for its
/// enter animation to have finished (so its box is the final one).
///
/// Placed is the box's opacity (it is hidden until the positioner reports
/// where it goes); finished is read from the animations themselves, because
/// the box only scales and the panel inside it fades, so the opacity of the
/// box says nothing about either once the panel is placed.
Future<void> _waitForMenu(pptr.Page page) async {
  await page.waitForFunction('''
() => {
    const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
    if (!menu) return false;
    const motion = menu.parentElement;
    return getComputedStyle(motion).opacity === '1' &&
        motion.getAnimations({subtree: true})
            .every((a) => a.playState === 'finished');
  }''');
  await _settle(page);
}
