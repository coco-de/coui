// The Web ContextMenu's glide, preview and haptic cue, driven by real touch
// input in Chrome.
//
// The VM can pin the tracker that times the press and starts the glide
// (`packages/coui_web/test/components/menu/context_menu_press_test.dart`
// replays the shared table on it with a manual clock) and the markup the
// pieces produce. It cannot reach what makes the glide a glide in a browser:
// a `touchmove` listener that has to exist before the finger goes down and
// must be able to hold the page still under it, rows measured off the page at
// every event, a mark that a browser's CSS paints as the weight of a press, a
// click that activates a row the way a tap does, a panel placed by layout and
// a preview placed around the box layout gave it. This file compiles the
// shipped component (`tool/parity/src/web/context_menu_glide_entry.dart`) and
// judges it in Chrome.
//
// ## What is replayed
//
// Every trace of the shared glide table the Web is named in
// (`context_menu_glide_vectors.json`) — the same traces the Core test replays
// on the state machine, the Flutter test as pointer events and the VM test on
// the tracker — as touch events through the DevTools input domain. Positions
// the table writes against the menu (`row`, `between`, `outside`) are resolved
// against the rows and the panel as Chrome laid them out. After each event the
// rendered page is read: which row carries the mark (and that Chrome paints it
// washed), how many times `navigator.vibrate` was called, whether the menu is
// still in the document, and which rows the page was told were chosen.
//
// ## What else is judged here
//
// * the listeners of the region: `touchmove` exists only for a menu that
//   glides, and not as a passive one;
// * a finger gliding over the menu does not scroll the page, and the control —
//   a finger that was not held, and one on a menu that does not glide — does;
// * the release of a glide is taken off the page (the `touchend` is prevented
//   and no click follows), and a plain tap is not;
// * a mouse right click is unchanged: nothing is lit, nothing ticks;
// * the default markup carries none of the new attributes;
// * a browser without `navigator.vibrate` plays nothing and throws nothing;
// * the preview: where it is placed for every scenario of the shared preview
//   table (right-to-left included), exactly where `CoreContextMenuPreview`
//   puts it around the menu Chrome laid out, hidden until it is placed,
//   ignoring the pointer, following the menu when it moves, and gone with it.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:path/path.dart' as p;
import 'package:puppeteer/protocol/input.dart' show TouchPoint;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// The tables shared with Core, Flutter and the VM Web tests (cwd is the
/// repository root under `dart test tool/parity/test`).
const String _kGlideVectorsPath =
    'packages/coui_core/test/fixtures/context_menu_glide_vectors.json';
const String _kPreviewVectorsPath =
    'packages/coui_core/test/fixtures/context_menu_preview_vectors.json';

const String _kEntryPath = 'tool/parity/src/web/context_menu_glide_entry.dart';

/// A phone-sized viewport — the one a long press is for.
const int _kPhoneWidth = 360;
const int _kPhoneHeight = 480;

/// The gap between the preview and the menu, and the margin the viewport keeps
/// from the screen edge — Core's numbers, read here so the probe states them
/// once.
const double _kGap = CoreContextMenuContract.defaultPreviewGap;

/// Chrome lays boxes out in 1/64 px.
const double _kTolerance = 0.5;

/// What the page records from before its own scripts run: the vibrations the
/// component asked for, the events that reached the window and what became of
/// them. `navigator.vibrate` is replaced on the prototype so the call the
/// component makes is the one that is counted.
const String _kSpyJs = '''
() => {
  window.__probe = {
    vibrations: [], pointercancel: 0, clicks: 0, touchmove: [], touchend: [],
  };
  Object.defineProperty(Navigator.prototype, 'vibrate', {
    configurable: true, writable: true,
    value(pattern) { window.__probe.vibrations.push(pattern); return true; },
  });
  addEventListener('pointercancel', () => { window.__probe.pointercancel++; },
    true);
  addEventListener('click', (e) => {
    if (e.isTrusted) window.__probe.clicks++;
  }, true);
  addEventListener('touchmove', (e) => {
    window.__probe.touchmove.push(
      {cancelable: e.cancelable, prevented: e.defaultPrevented});
  });
  addEventListener('touchend', (e) => {
    window.__probe.touchend.push(
      {cancelable: e.cancelable, prevented: e.defaultPrevented});
  });
}
''';

/// The open menu, as Chrome has it: the panel's box, the box of the list that
/// scrolls it (when one does) and every interactive row — its box wherever the
/// list has it, whether it carries the mark, whether it is disabled, its id and
/// the colour its wash paints.
const String _kReadMenuJs = '''
() => {
  const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
  if (!menu) return JSON.stringify(null);
  const box = (r) => [r.left, r.top, r.right, r.bottom];
  const scroller = menu.querySelector('.co-fit-scroller');
  const rows = [...menu.querySelectorAll(
    '[role="menuitem"],[role="menuitemcheckbox"],[role="menuitemradio"]')];
  return JSON.stringify({
    panel: box(menu.getBoundingClientRect()),
    scroller: scroller ? box(scroller.getBoundingClientRect()) : null,
    rows: rows.map((row) => {
      const wash = row.querySelector('.co-menu-item-wash');
      return {
        box: box(row.getBoundingClientRect()),
        lit: row.hasAttribute('data-coui-glide'),
        disabled: row.getAttribute('aria-disabled') === 'true',
        id: row.getAttribute('data-roving-item'),
        wash: wash ? getComputedStyle(wash).backgroundColor : '',
      };
    }),
  });
}
''';

/// Whether the menu's panel has been given its place and nothing is still
/// animating — the point after which the rows are where they will stay.
const String _kSettledJs = '''
(needsScroller) => {
  const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
  if (!menu) return false;
  const wrapper = menu.closest('[id^="co-context-menu-panel"]');
  if (!wrapper || wrapper.style.left === '') return false;
  if (needsScroller && !menu.querySelector('.co-fit-scroller')) return false;
  return document.getAnimations().every(
    (a) => a.playState !== 'running' && a.playState !== 'pending');
}
''';

const String _kMenuOpenJs =
    '() => !!document.querySelector(\'#coui-overlay-menu [role="menu"]\')';

const String _kMenuClosedJs =
    '() => !document.querySelector(\'#coui-overlay-menu [role="menu"]\')';

typedef _Row = ({
  CoreMenuBox box,
  bool lit,
  bool disabled,
  String id,
  String wash,
});

typedef _Menu = ({CoreMenuBox panel, CoreMenuBox? scroller, List<_Row> rows});

typedef _Point = ({double x, double y});

CoreMenuBox _boxOf(Object? edges) {
  final e = (edges! as List).cast<num>().map((v) => v.toDouble()).toList();

  return CoreMenuBox(left: e[0], top: e[1], right: e[2], bottom: e[3]);
}

double _n(Map<String, Object?> map, String key) =>
    (map[key]! as num).toDouble();

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

/// The alpha of a computed CSS colour: `rgb()` is opaque, `rgba()` states it
/// last, and the `color()` form after a slash.
double _alphaOf(String color) {
  final value = color.trim();
  if (value == 'transparent') return 0;
  if (value.startsWith('rgba(')) {
    return double.parse(value.substring(5, value.length - 1).split(',').last);
  }
  final slash = value.indexOf('/');
  if (slash >= 0) {
    return double.parse(
      value.substring(slash + 1, value.length - 1).replaceAll('%', ''),
    );
  }

  return 1;
}

String? _chromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in [
    if (Platform.environment['CHROME_EXECUTABLE'] case final String chrome
        when chrome.isNotEmpty)
      chrome,
    ...candidates,
  ]) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

Future<void> _frames(pptr.Page page, [int count = 2]) async {
  for (var i = 0; i < count; i++) {
    await page.evaluate<void>(
      '() => new Promise(resolve => requestAnimationFrame(() => resolve()))',
    );
  }
}

Future<_Menu?> _readMenu(pptr.Page page) async {
  final json = await page.evaluate<String>(_kReadMenuJs);
  final data = jsonDecode(json) as Map<String, Object?>?;
  if (data == null) return null;

  return (
    panel: _boxOf(data['panel']),
    scroller: data['scroller'] == null ? null : _boxOf(data['scroller']),
    rows: [
      for (final row in _list(data['rows']))
        (
          box: _boxOf(row['box']),
          lit: row['lit']! as bool,
          disabled: row['disabled']! as bool,
          id: row['id'] as String? ?? '',
          wash: row['wash']! as String,
        ),
    ],
  );
}

Future<bool> _menuOpen(pptr.Page page) => page.evaluate<bool>(_kMenuOpenJs);

/// Reads [read] until two reads, a few frames apart, agree. A mark, a count or
/// a row set reaches the page a render after the event that caused it, and an
/// expectation that something did *not* happen is only as good as having given
/// it the time to.
Future<T> _stable<T>(pptr.Page page, Future<T> Function() read) async {
  var previous = await read();
  for (var i = 0; i < 40; i++) {
    await _frames(page, 3);
    final next = await read();
    if (jsonEncode(next) == jsonEncode(previous)) return next;
    previous = next;
  }

  return previous;
}

Future<int> _vibrations(pptr.Page page) =>
    page.evaluate<int>('() => window.__probe.vibrations.length');

Future<List<int>> _activated(pptr.Page page) async =>
    (jsonDecode(
              await page.evaluate<String>('() => couiGlideActivated()'),
            )
            as List)
        .cast<int>();

/// Which interactive row is lit and how washed the rows are: the index of the
/// row that carries the mark (or `null`), the alpha of its wash and the largest
/// alpha among the others. The wash fades with a transition, so a caller reads
/// this until it stops changing before it judges it.
Future<({int? lit, double litAlpha, double othersAlpha})> _litState(
  pptr.Page page,
) async {
  final menu = await _readMenu(page);
  if (menu == null) return (lit: null, litAlpha: 0.0, othersAlpha: 0.0);
  final lit = [
    for (var i = 0; i < menu.rows.length; i++)
      if (menu.rows[i].lit) i,
  ];
  expect(lit.length, lessThanOrEqualTo(1), reason: 'at most one row is lit');

  return (
    lit: lit.isEmpty ? null : lit.single,
    litAlpha: lit.isEmpty ? 0.0 : _alphaOf(menu.rows[lit.single].wash),
    othersAlpha: [
      0.0,
      for (var i = 0; i < menu.rows.length; i++)
        if (lit.isEmpty || i != lit.single) _alphaOf(menu.rows[i].wash),
    ].reduce(math.max),
  );
}

/// One finger, sent as touch events through the DevTools input domain: the
/// events a touch screen makes, routed by the browser through hit testing,
/// gesture detection and scroll arbitration as it does a real one.
class _Finger {
  _Finger(this.page);

  final pptr.Page page;

  Future<void> _send(String type, List<TouchPoint> points) =>
      page.devTools.input.dispatchTouchEvent(type, points);

  Future<void> down(_Point at) async {
    await _send('touchStart', [TouchPoint(x: at.x, y: at.y, id: 1)]);
    await _frames(page);
  }

  Future<void> move(_Point to) async {
    await _send('touchMove', [TouchPoint(x: to.x, y: to.y, id: 1)]);
    await _frames(page);
  }

  Future<void> up() async {
    await _send('touchEnd', const []);
    await _frames(page);
  }

  Future<void> cancel() async {
    await _send('touchCancel', const []);
    await _frames(page);
  }
}

void main() {
  final chromePath = _chromePath();
  final glideDoc =
      jsonDecode(File(_kGlideVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final previewDoc =
      jsonDecode(File(_kPreviewVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final traces = _list(glideDoc['traces']);
  final menus = glideDoc['menus']! as Map<String, Object?>;
  final scenarios = _list(previewDoc['scenarios']);

  late pptr.Browser browser;
  late Directory fixture;
  late File html;

  setUpAll(() async {
    if (chromePath == null) return;
    fixture = Directory.systemTemp.createTempSync('coui-ctx-glide-probe-');
    final js = p.join(fixture.path, 'entry.js');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O1',
      '-o',
      js,
      _kEntryPath,
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    // Real motion: the panel's enter and exit are part of what is judged (the
    // rows are measured while it settles, and the preview fades with it).
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

  final skip = chromePath == null
      ? 'no local Chrome — the glide cannot be checked against a browser here'
      : null;

  /// A page with the spy installed before the component's scripts run, at
  /// the size given, with touch input available.
  Future<pptr.Page> openPage({
    int width = _kPhoneWidth,
    int height = _kPhoneHeight,
    bool vibrate = true,
    List<String>? errors,
  }) async {
    final page = await browser.newPage();
    await page.setViewport(
      pptr.DeviceViewport(width: width, height: height, hasTouch: true),
    );
    await page.evaluateOnNewDocument(_kSpyJs);
    if (errors != null) {
      page.onError.listen((error) => errors.add('$error'));
    }
    await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
    await page.waitForFunction('typeof couiGlideConfigure === "function"');
    if (!vibrate) {
      await page.evaluate<void>(
        '() => { delete Navigator.prototype.vibrate; }',
      );
    }

    return page;
  }

  Future<void> configure(
    pptr.Page page, {
    String? menu,
    List<Map<String, Object?>>? items,
    bool glide = true,
    bool haptics = false,
    Map<String, Object?>? preview,
    int? closeMs,
  }) async {
    items ??= _list((menus[menu]! as Map<String, Object?>)['items']);
    await page.evaluate<void>(
      '(c) => couiGlideConfigure(c)',
      args: [
        jsonEncode({
          'items': items,
          'glide': glide,
          'haptics': haptics,
          'preview': ?preview,
          'closeMs': ?closeMs,
        }),
      ],
    );
    await _frames(page, 3);
  }

  Future<void> waitSettled(pptr.Page page, {bool tall = false}) async {
    await page.waitForFunction(
      _kSettledJs,
      args: [tall],
      timeout: const Duration(seconds: 30),
    );
    await _frames(page, 3);
  }

  Future<void> settleAfter(pptr.Page page, {bool tall = false}) async {
    // The hold is up some 500 ms after the down; give the menu the time to
    // open, be placed and finish its enter animation.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await page.waitForFunction(
      _kMenuOpenJs,
      timeout: const Duration(seconds: 30),
    );
    await waitSettled(page, tall: tall);
  }

  _Point resolve(
    Map<String, Object?> to,
    _Point previous, {
    required _Point origin,
    required _Menu? menu,
  }) {
    if (to['same'] == true) return previous;
    if (to.containsKey('offset')) {
      final offset = (to['offset']! as List).cast<num>();

      return (x: origin.x + offset[0], y: origin.y + offset[1]);
    }
    final read = menu!;
    if (to.containsKey('row')) {
      final box = read.rows[(to['row']! as num).toInt()].box;
      final at = (to['at']! as List).cast<num>();

      return (
        x: box.left + box.width * at[0],
        y: box.top + box.height * at[1],
      );
    }
    final panel = read.panel;
    if (to.containsKey('between')) {
      final pair = (to['between']! as List).cast<num>();
      final upper = read.rows[pair[0].toInt()].box;
      final lower = read.rows[pair[1].toInt()].box;

      return (
        x: panel.left + panel.width / 2,
        y: (upper.bottom + lower.top) / 2,
      );
    }
    final by = _n(to, 'by');

    return switch (to['outside']) {
      'below' => (x: panel.left + panel.width / 2, y: panel.bottom + by),
      'above' => (x: panel.left + panel.width / 2, y: panel.top - by),
      'left' => (x: panel.left - by, y: panel.top + panel.height / 2),
      'right' => (x: panel.right + by, y: panel.top + panel.height / 2),
      final side => throw StateError('unknown side $side'),
    };
  }

  Future<void> scrollList(pptr.Page page, int firstRow) async {
    await page.evaluate<void>(
      '''
(first) => {
  const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
  const scroller = menu.querySelector('.co-fit-scroller');
  const rows = [...menu.querySelectorAll(
    '[role="menuitem"],[role="menuitemcheckbox"],[role="menuitemradio"]')];
  const top = (el) => el.getBoundingClientRect().top
    - scroller.getBoundingClientRect().top + scroller.scrollTop;
  scroller.scrollTop = top(rows[first]) - top(rows[0]);
}''',
      args: [firstRow],
    );
    await _frames(page, 3);
  }

  /// What the table says an event left behind, read off the page.
  Future<void> check(
    pptr.Page page,
    Map<String, Object?> expected,
    String where,
  ) async {
    if (expected.containsKey('open')) {
      if (expected['open']! as bool) {
        // Closing starts at the event and finishes within the exit duration;
        // a menu that is still there after that did not close.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(await _menuOpen(page), isTrue, reason: '$where: open');
      } else {
        var closed = true;
        try {
          await page.waitForFunction(
            _kMenuClosedJs,
            timeout: const Duration(seconds: 15),
          );
        } on TimeoutException {
          closed = false;
        }
        expect(closed, isTrue, reason: '$where: the menu closed');
      }
    }
    if (expected.containsKey('highlight')) {
      final state = await _stable(page, () async {
        final read = await _litState(page);

        return [read.lit, read.litAlpha, read.othersAlpha];
      });
      expect(state[0], expected['highlight'], reason: '$where: highlight');
      // What the mark is for: Chrome washes the lit row as a pressed one, and
      // no other row.
      if (state[0] != null) {
        expect(
          state[1]! as double,
          greaterThan(0),
          reason: '$where: the lit row is washed',
        );
      }
      expect(
        state[2],
        0,
        reason: '$where: no row but the lit one is washed',
      );
    }
    if (expected.containsKey('cues')) {
      expect(
        await _stable(page, () => _vibrations(page)),
        expected['cues'],
        reason: '$where: cues',
      );
    }
    if (expected.containsKey('activated')) {
      expect(
        await _stable(page, () => _activated(page)),
        (expected['activated']! as List).cast<int>(),
        reason: '$where: activated',
      );
    }
  }

  /// Replays one trace of the glide table: the touch events, the page read
  /// after each, and what the release left on the page.
  Future<void> replayTrace(Map<String, Object?> trace) async {
    final page = await openPage();
    try {
      final menuName = (trace['menu'] as String?) ?? 'basic';
      final events = _list(trace['events']);
      final down = events.first;
      final origin = (x: _n(down, 'x'), y: _n(down, 'y'));
      final haptics = trace['haptics'] == true;
      await configure(
        page,
        menu: menuName,
        glide: trace['glide'] != false,
        haptics: haptics,
      );
      final finger = _Finger(page);
      await finger.down(origin);

      var at = origin;
      var settled = false;
      _Menu? menu;
      var lastKind = 'down';
      for (final event in events.skip(1)) {
        final kind = event['kind']! as String;
        final to = event['to'] as Map<String, Object?>?;
        // The first event after the hold waits for the menu to open and
        // come to rest; the events before it belong to the hold.
        if ((event['at']! as int) >= 500 && !settled) {
          await settleAfter(page, tall: menuName == 'tall');
          settled = true;
        }
        if (settled && kind != 'scroll') menu = await _readMenu(page);
        if (to != null && kind != 'scroll') {
          at = resolve(to, at, origin: origin, menu: menu);
        }
        switch (kind) {
          case 'move':
            await finger.move(at);
          case 'up':
            await finger.up();
          case 'cancel':
            await finger.cancel();
          case 'scroll':
            await scrollList(page, (to!['firstRow']! as num).toInt());
          default:
            fail('the table gave Chrome an event it cannot replay: $event');
        }
        lastKind = kind;

        final expected = event['expect'] as Map<String, Object?>?;
        if (expected != null) {
          await check(
            page,
            expected,
            '${trace['name']} — after $kind at ${event['at']} ms',
          );
        }
      }

      // A lift that ended a press which opened the menu is not a tap: the
      // touch-end was taken off the page and no click followed it.
      if (lastKind == 'up' && trace['glide'] != false) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final probe =
            jsonDecode(
                  await page.evaluate<String>(
                    '() => JSON.stringify(window.__probe)',
                  ),
                )
                as Map<String, Object?>;
        final ends = _list(probe['touchend']);
        expect(ends, isNotEmpty, reason: 'the page saw the touch end');
        expect(
          ends.last['prevented'],
          isTrue,
          reason: 'and the menu took it: ${probe['touchend']}',
        );
        expect(probe['clicks'], 0, reason: 'so no click followed');
        expect(
          probe['pointercancel'],
          0,
          reason: 'nothing took the pointer',
        );
      }
      if (haptics) {
        final pulses =
            (jsonDecode(
                      await page.evaluate<String>(
                        '() => JSON.stringify(window.__probe.vibrations)',
                      ),
                    )
                    as List)
                .cast<num>();
        expect(
          pulses.every(
            (pulse) => pulse == CoreHapticCue.selectionTick.pulseMilliseconds,
          ),
          isTrue,
          reason: 'every cue is the tick, at the length Core states: $pulses',
        );
      }
    } finally {
      await page.close();
    }
  }

  group('every glide trace the table names the Web in, in Chrome', () {
    for (final trace in traces) {
      final platforms = (trace['platforms'] as List?)?.cast<String>();
      if (platforms != null && !platforms.contains('web')) continue;

      test(
        trace['name']! as String,
        () => replayTrace(trace),
        skip: skip,
      );
    }
  }, timeout: const Timeout(Duration(minutes: 30)));

  group('traces the table does not name the Web in, run here as well', () {
    // They name rows the list has scrolled out of view or that lie below the
    // fold, at a place the finger would have to be off the screen to reach.
    // The Web measures the same rows from the page, so the answer is
    // expected to be the table's; a failure here is not a failure of the
    // table, which does not ask it of the Web.
    for (final trace in traces) {
      final platforms = (trace['platforms'] as List?)?.cast<String>();
      if (platforms == null || platforms.contains('web')) continue;

      test(
        trace['name']! as String,
        () => replayTrace(trace),
        skip: skip,
      );
    }
  }, timeout: const Timeout(Duration(minutes: 30)));

  group('the region and the page', () {
    /// The listeners of the first element matching [selector], as the browser
    /// reports them.
    Future<List<({String type, bool passive})>> listenersOf(
      pptr.Page page,
      String selector,
    ) async {
      final handle = await page.$(selector);
      final listeners = await page.devTools.domDebugger.getEventListeners(
        handle.remoteObject.objectId!,
      );

      return [
        for (final listener in listeners)
          (type: listener.type, passive: listener.passive),
      ];
    }

    Future<Map<String, Object?>> readProbe(pptr.Page page) async =>
        jsonDecode(
              await page.evaluate<String>(
                '() => JSON.stringify(window.__probe)',
              ),
            )
            as Map<String, Object?>;

    Future<void> waitForClosed(pptr.Page page) => page.waitForFunction(
      _kMenuClosedJs,
      timeout: const Duration(seconds: 15),
    );

    test('a menu that does not glide listens for no touchmove', () async {
      final page = await openPage();
      try {
        await configure(page, menu: 'basic', glide: false);
        final types = (await listenersOf(page, '#cm')).map((l) => l.type);

        expect(
          types.toSet(),
          containsAll(['contextmenu', 'pointerdown', 'touchend']),
        );
        expect(types, isNot(contains('touchmove')));
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('haptics or a preview alone add no listener', () async {
      final page = await openPage();
      try {
        await configure(
          page,
          menu: 'basic',
          glide: false,
          haptics: true,
          preview: {'width': 100, 'height': 60},
        );
        final types = (await listenersOf(page, '#cm')).map((l) => l.type);

        expect(types, isNot(contains('touchmove')));
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'a menu that glides listens for touchmove, and not passively',
      () async {
        final page = await openPage();
        try {
          await configure(page, menu: 'basic');
          final moves = (await listenersOf(
            page,
            '#cm',
          )).where((l) => l.type == 'touchmove');

          expect(moves, hasLength(1));
          expect(
            moves.single.passive,
            isFalse,
            reason: 'a passive listener cannot hold the page still',
          );
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('a finger gliding over the menu does not scroll the page', () async {
      final page = await openPage();
      try {
        await configure(page, menu: 'basic', haptics: true);
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 50.0));
        await settleAfter(page);

        final menu = (await _readMenu(page))!;
        // Down the list in steps, the way a finger goes.
        for (final row in menu.rows.take(4)) {
          await finger.move((
            x: row.box.left + row.box.width / 2,
            y: row.box.top + row.box.height / 2,
          ));
        }
        await finger.up();
        await Future<void>.delayed(const Duration(milliseconds: 400));

        final probe = await readProbe(page);
        printOnFailure('probe: ${jsonEncode(probe)}');
        final moves = _list(probe['touchmove']);
        expect(moves, isNotEmpty, reason: 'the page saw the finger move');
        expect(
          moves.every((move) => move['cancelable'] == true),
          isTrue,
          reason: 'every move could still be cancelled',
        );
        expect(
          moves.every((move) => move['prevented'] == true),
          isTrue,
          reason: 'and the menu cancelled every one of them',
        );
        expect(
          probe['pointercancel'],
          0,
          reason: 'the browser kept the pointer',
        );
        expect(await page.evaluate<num>('() => window.scrollY'), 0);
        expect(await _activated(page), [3], reason: 'and the lift chose');
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('control: a finger that moves before the hold is up scrolls the '
        'page as it always did', () async {
      final page = await openPage();
      try {
        await configure(page, menu: 'basic', haptics: true);
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 300.0));
        for (var step = 1; step <= 10; step++) {
          await finger.move((x: 60.0, y: 300.0 - step * 20));
        }
        await finger.up();
        await Future<void>.delayed(const Duration(milliseconds: 700));

        final probe = await readProbe(page);
        printOnFailure('probe: ${jsonEncode(probe)}');
        expect(
          _list(probe['touchmove']).any((move) => move['prevented'] == true),
          isFalse,
          reason: 'the menu has not opened, so it holds nothing back',
        );
        expect(
          await page.evaluate<num>('() => window.scrollY'),
          greaterThan(0),
          reason:
              'and Chrome scrolled the page under the finger — the '
              'arbitration the test above holds off is real here',
        );
        expect(await _menuOpen(page), isFalse);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'a menu that does not glide lets the page pan under a held finger',
      () async {
        final page = await openPage();
        try {
          await configure(page, menu: 'basic', glide: false);
          final finger = _Finger(page);
          await finger.down((x: 60.0, y: 300.0));
          await settleAfter(page);
          for (var step = 1; step <= 10; step++) {
            await finger.move((x: 60.0, y: 300.0 - step * 20));
          }
          await finger.up();
          await Future<void>.delayed(const Duration(milliseconds: 500));

          final probe = await readProbe(page);
          printOnFailure('probe: ${jsonEncode(probe)}');
          expect(
            _list(probe['touchmove']).any((move) => move['prevented'] == true),
            isFalse,
            reason: 'there is no glide to hold the page for',
          );
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test(
      'lighting a row renders it in place: the panel is not mounted again',
      () async {
        // The portal that carries the panel re-renders it when the lit row
        // changes. The panel must keep its nodes — and so its enter animation,
        // which would pop on every row, and the scroll position of its list.
        final page = await openPage();
        try {
          await configure(page, menu: 'tall', haptics: true);
          final finger = _Finger(page);
          await finger.down((x: 60.0, y: 50.0));
          await settleAfter(page, tall: true);

          await page.evaluate<void>('''
() => {
  const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
  const scroller = menu.querySelector('.co-fit-scroller');
  scroller.scrollTop = 400;
  menu.__tag = 'menu';
  scroller.__tag = 'scroller';
  menu.closest('[id^="co-context-menu-panel"]').__tag = 'wrapper';
  window.__starts = 0;
  document.addEventListener('animationstart', () => { window.__starts++; }, true);
}''');
          await _frames(page, 3);

          final menu = (await _readMenu(page))!;
          final list = menu.scroller!;
          // Three rows that are wholly in view, one after the other.
          final inView = menu.rows
              .where((row) {
                final visible = list.intersect(row.box);

                return visible != null && visible.height >= row.box.height - 1;
              })
              .take(3)
              .toList();
          expect(inView, hasLength(3));
          for (final row in inView) {
            await finger.move((
              x: row.box.left + row.box.width / 2,
              y: row.box.top + row.box.height / 2,
            ));
          }
          await _frames(page, 4);

          final facts =
              jsonDecode(
                    await page.evaluate<String>('''
() => {
  const menu = document.querySelector('#coui-overlay-menu [role="menu"]');
  const scroller = menu.querySelector('.co-fit-scroller');
  return JSON.stringify({
    menu: menu.__tag, scroller: scroller.__tag,
    wrapper: menu.closest('[id^="co-context-menu-panel"]').__tag,
    scrollTop: scroller.scrollTop, starts: window.__starts,
  });
}'''),
                  )
                  as Map<String, Object?>;
          printOnFailure('facts: ${jsonEncode(facts)}');

          expect(
            facts['menu'],
            'menu',
            reason: 'the menu box is the same node',
          );
          expect(facts['scroller'], 'scroller', reason: 'and so is its list');
          expect(
            facts['wrapper'],
            'wrapper',
            reason: 'and the positioned wrapper',
          );
          expect(facts['scrollTop'], 400, reason: 'the list kept its place');
          expect(facts['starts'], 0, reason: 'no animation started again');
          await finger.cancel();
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('a row scrolled partly out of view is not under a finger above the '
        'list', () async {
      // The row's box reaches above the list that scrolls it; only the part
      // the list shows is the row a finger can be on.
      final page = await openPage();
      try {
        await configure(page, menu: 'tall');
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 50.0));
        await settleAfter(page, tall: true);

        final before = (await _readMenu(page))!;
        final list = before.scroller!;
        final offset = before.rows[5].box.top - list.top;
        await page.evaluate<void>(
          '''
(offset) => {
  document.querySelector('#coui-overlay-menu .co-fit-scroller')
    .scrollTop = offset + 19;
}''',
          args: [offset],
        );
        await _frames(page, 3);

        final menu = (await _readMenu(page))!;
        final row = menu.rows[5].box;
        final above = (x: row.left + row.width / 2, y: list.top - 3);
        expect(row.top, lessThan(list.top), reason: 'the row is cut off');
        expect(row.bottom, greaterThan(list.top), reason: 'by part of itself');
        expect(above.y, greaterThan(0), reason: 'and the point is on screen');
        expect(row.containsPoint(above.x, above.y), isTrue);

        await finger.move(above);
        expect(
          await _stable(page, () => _litState(page).then((state) => state.lit)),
          isNull,
          reason: 'no row is under a finger above the list',
        );
        await finger.up();
        await waitForClosed(page);

        expect(await _activated(page), isEmpty);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a row of an inline submenu is chosen like any other', () async {
      final page = await openPage();
      try {
        await configure(
          page,
          items: [
            {
              'kind': 'action',
              'label': 'Share',
              'submenu': [
                {'kind': 'action', 'label': 'Mail'},
                {'kind': 'action', 'label': 'Copy link'},
              ],
            },
            {'kind': 'action', 'label': 'Delete'},
          ],
          haptics: true,
        );
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 50.0));
        await settleAfter(page);

        final menu = (await _readMenu(page))!;
        expect(
          menu.rows,
          hasLength(4),
          reason: 'Share, then its two rows, then Delete',
        );
        final row = menu.rows[2].box;
        await finger.move((
          x: row.left + row.width / 2,
          y: row.top + row.height / 2,
        ));
        final lit = await _stable(
          page,
          () => _litState(page).then((state) => state.lit),
        );
        expect(lit, 2, reason: 'the nested row is the one that is lit');
        await finger.up();
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(await _activated(page), [2]);
        expect(await _litState(page).then((state) => state.lit), isNull);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a row of an inline submenu scrolled partly out of view is not under '
        'a finger above the list', () async {
      // The submenu's rows sit in two lists, its own and the menu's. The menu's
      // is the one that cuts them off.
      final page = await openPage();
      try {
        await configure(
          page,
          items: [
            for (var i = 0; i < 5; i++) {'kind': 'action', 'label': 'Row $i'},
            {
              'kind': 'action',
              'label': 'Share',
              'submenu': [
                for (final label in ['Mail', 'Copy link', 'Print'])
                  {'kind': 'action', 'label': label},
              ],
            },
            for (var i = 0; i < 25; i++) {'kind': 'action', 'label': 'More $i'},
          ],
        );
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 50.0));
        await settleAfter(page, tall: true);

        final before = (await _readMenu(page))!;
        final list = before.scroller!;
        // Rows 0–4, Share (5), then the submenu's Mail (6).
        final offset = before.rows[6].box.top - list.top;
        await page.evaluate<void>(
          '''
(offset) => {
  document.querySelector('#coui-overlay-menu .co-fit-scroller')
    .scrollTop = offset + 19;
}''',
          args: [offset],
        );
        await _frames(page, 3);

        final menu = (await _readMenu(page))!;
        final row = menu.rows[6].box;
        final above = (x: row.left + row.width / 2, y: list.top - 3);
        expect(row.top, lessThan(list.top), reason: 'the row is cut off');
        expect(row.bottom, greaterThan(list.top), reason: 'by part of itself');
        expect(row.containsPoint(above.x, above.y), isTrue);

        await finger.move(above);
        expect(
          await _stable(page, () => _litState(page).then((state) => state.lit)),
          isNull,
          reason: 'no row is under a finger above the list',
        );
        await finger.up();
        await waitForClosed(page);

        expect(await _activated(page), isEmpty);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a pen glides like a finger', () async {
      final page = await openPage();
      try {
        await configure(page, menu: 'basic', haptics: true);
        final input = page.devTools.input;
        Future<void> penDown(_Point at) async {
          await input.dispatchMouseEvent(
            'mouseMoved',
            at.x,
            at.y,
            pointerType: 'pen',
          );
          await input.dispatchMouseEvent(
            'mousePressed',
            at.x,
            at.y,
            button: pptr.MouseButton.left,
            buttons: 1,
            clickCount: 1,
            pointerType: 'pen',
          );
          await _frames(page);
        }

        Future<void> penMove(_Point at) async {
          await input.dispatchMouseEvent(
            'mouseMoved',
            at.x,
            at.y,
            button: pptr.MouseButton.left,
            buttons: 1,
            pointerType: 'pen',
          );
          await _frames(page);
        }

        await penDown((x: 60.0, y: 50.0));
        await settleAfter(page);
        final menu = (await _readMenu(page))!;
        final row = menu.rows[2].box;
        final at = (x: row.left + row.width / 2, y: row.top + row.height / 2);
        await penMove(at);
        final lit = await _stable(
          page,
          () => _litState(page).then((state) => state.lit),
        );
        expect(lit, 2);
        await input.dispatchMouseEvent(
          'mouseReleased',
          at.x,
          at.y,
          button: pptr.MouseButton.left,
          buttons: 0,
          clickCount: 1,
          pointerType: 'pen',
        );
        await waitForClosed(page);

        expect(await _activated(page), [2]);
        expect(await _vibrations(page), 2, reason: 'one tick lit, one chose');
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a plain tap is a tap: the page gets its click', () async {
      // The control for "no click followed the release of a glide": a tap
      // that is not a press does produce one here.
      final page = await openPage();
      try {
        await configure(page, menu: 'basic');
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 300.0));
        await finger.up();
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(await page.evaluate<num>('() => window.__probe.clicks'), 1);
        expect(await _menuOpen(page), isFalse);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test(
      'a right click is unchanged: nothing is lit and nothing ticks',
      () async {
        final page = await openPage();
        try {
          await configure(page, menu: 'basic', haptics: true);
          await page.mouse.click(
            const pptr.Point(60, 50),
            button: pptr.MouseButton.right,
          );
          await page.waitForFunction(_kMenuOpenJs);
          await waitSettled(page);

          final menu = (await _readMenu(page))!;
          expect(menu.rows.where((row) => row.lit), isEmpty);
          // A mouse moves over the rows without a mark: it has no finger to
          // glide, and `:hover` is the mouse's own.
          final row = menu.rows.first.box;
          final centre = pptr.Point(
            row.left + row.width / 2,
            row.top + row.height / 2,
          );
          await page.mouse.move(centre, steps: 4);
          await _frames(page, 3);
          expect(
            (await _readMenu(page))!.rows.where((row) => row.lit),
            isEmpty,
          );
          expect(await _vibrations(page), 0);

          await page.mouse.click(centre);
          await waitForClosed(page);
          expect(await _activated(page), [0]);
          expect(await _vibrations(page), 0);
        } finally {
          await page.close();
        }
      },
      skip: skip,
    );

    test('a held mouse button opens nothing', () async {
      final page = await openPage();
      try {
        await configure(page, menu: 'basic', haptics: true);
        await page.mouse.move(const pptr.Point(60, 50));
        await page.mouse.down();
        await Future<void>.delayed(const Duration(milliseconds: 800));
        expect(await _menuOpen(page), isFalse);
        await page.mouse.up();
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('the default markup carries nothing of a glide', () async {
      final page = await openPage();
      try {
        await configure(page, menu: 'basic', glide: false);
        await page.mouse.click(
          const pptr.Point(60, 50),
          button: pptr.MouseButton.right,
        );
        await page.waitForFunction(_kMenuOpenJs);
        await waitSettled(page);

        final facts =
            jsonDecode(
                  await page.evaluate<String>('''
() => JSON.stringify({
  marked: document.querySelectorAll('[data-coui-glide]').length,
  styled: [...document.querySelectorAll('style')]
    .filter((s) => s.textContent.includes('data-coui-glide')).length,
  previews: document.querySelectorAll('[id^="co-context-menu-preview"]').length,
})'''),
                )
                as Map<String, Object?>;

        expect(facts, {'marked': 0, 'styled': 0, 'previews': 0});
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('a browser without navigator.vibrate plays nothing and throws '
        'nothing', () async {
      final errors = <String>[];
      final page = await openPage(vibrate: false, errors: errors);
      try {
        expect(
          await page.evaluate<bool>(
            "() => typeof navigator.vibrate === 'undefined'",
          ),
          isTrue,
        );
        await configure(page, menu: 'basic', haptics: true);
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 50.0));
        await settleAfter(page);
        final menu = (await _readMenu(page))!;
        final row = menu.rows.first.box;
        await finger.move((
          x: row.left + row.width / 2,
          y: row.top + row.height / 2,
        ));
        final lit = await _stable(
          page,
          () => _litState(page).then((state) => state.lit),
        );
        expect(lit, 0);
        await finger.up();
        await waitForClosed(page);

        expect(await _activated(page), [0], reason: 'the glide still chose');
        expect(errors, isEmpty);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('lifting over a row of a menu that is already closing chooses '
        'nothing', () async {
      // Once the exit has played the rows are gone and nothing can be chosen
      // whatever the glide thinks. The invariant is only observable while the
      // panel is still on the page, so the exit is made long and the finger
      // lifts a moment after Escape, with every row still in the DOM under it.
      final page = await openPage();
      try {
        await configure(page, menu: 'basic', haptics: true, closeMs: 4000);
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 300.0));
        await settleAfter(page);
        final menu = (await _readMenu(page))!;
        // The third row, "Cut": the second one of this menu is disabled.
        final row = menu.rows[2].box;
        await finger.move((
          x: row.left + row.width / 2,
          y: row.top + row.height / 2,
        ));
        final lit = await _stable(
          page,
          () => _litState(page).then((state) => state.lit),
        );
        expect(lit, 2, reason: 'the premise: the row under the finger is lit');
        final ticks = await _vibrations(page);
        expect(ticks, 1, reason: 'the premise: entering the row ticked once');

        await page.keyboard.press(pptr.Key.escape);
        await _frames(page, 3);
        expect(
          await _menuOpen(page),
          isTrue,
          reason: 'the premise: the panel is leaving, not gone',
        );

        await finger.up();
        await _frames(page, 3);
        expect(
          await _menuOpen(page),
          isTrue,
          reason: 'the panel was still on the page when the finger lifted',
        );
        expect(
          await _activated(page),
          isEmpty,
          reason: 'no row of a closing menu is chosen',
        );
        expect(
          await _vibrations(page),
          ticks,
          reason: 'and no tick plays for a choice that was not made',
        );

        await page.waitForFunction(
          _kMenuClosedJs,
          timeout: const Duration(seconds: 15),
        );
        expect(await _activated(page), isEmpty);
      } finally {
        await page.close();
      }
    }, skip: skip);
  }, timeout: const Timeout(Duration(minutes: 30)));

  group('the preview', () {
    final threeRows = [
      for (final label in ['One', 'Two', 'Three'])
        {'kind': 'action', 'label': label},
    ];

    /// What the page shows of the open menu and its preview, in client
    /// coordinates.
    const readJs = '''
() => {
  const box = (el) => {
    const r = el.getBoundingClientRect();
    return [r.left, r.top, r.right, r.bottom];
  };
  const menu = document.querySelector('[id^="co-context-menu-panel"]');
  const preview = document.querySelector('[id^="co-context-menu-preview"]');
  if (!menu || !preview) return JSON.stringify(null);
  const content = document.getElementById('pv');
  const r = preview.getBoundingClientRect();
  const under = document.elementFromPoint(
    r.left + r.width / 2, r.top + r.height / 2);
  return JSON.stringify({
    menu: box(menu), preview: box(preview), content: box(content),
    placed: preview.style.left !== '',
    pointerEvents: getComputedStyle(preview).pointerEvents,
    position: getComputedStyle(preview).position,
    popoverOpen: preview.matches(':popover-open'),
    hitIsPreview: !!under && preview.contains(under),
    animation: getComputedStyle(preview.firstElementChild).animationName,
  });
}''';

    /// Samples the preview's wrapper once a frame, so what it looked like
    /// before it was placed can be read afterwards.
    const sampleJs = '''
() => {
  window.__frames = [];
  const tick = () => {
    const preview = document.querySelector('[id^="co-context-menu-preview"]');
    if (preview) {
      window.__frames.push({
        placed: preview.style.left !== '',
        opacity: parseFloat(
          getComputedStyle(preview.firstElementChild).opacity),
        animation: getComputedStyle(preview.firstElementChild).animationName,
      });
    }
    window.__tick = requestAnimationFrame(tick);
  };
  tick();
}''';

    const placedJs = '''
() => {
  const preview = document.querySelector('[id^="co-context-menu-preview"]');
  return !!preview && preview.style.left !== '' &&
    document.getAnimations().every(
      (a) => a.playState !== 'running' && a.playState !== 'pending');
}''';

    const goneJs = '''
() => !document.querySelector('[id^="co-context-menu-preview"]')
  && !document.querySelector('[id^="co-context-menu-panel"]')''';

    Future<Map<String, Object?>?> readPreview(pptr.Page page) async {
      final json = await page.evaluate<String>(readJs);

      return jsonDecode(json) as Map<String, Object?>?;
    }

    /// Opens a three-row menu with a preview by a right click at [pointer] and
    /// waits for the menu and the preview to be placed and to stop moving.
    Future<Map<String, Object?>> openWithPreview(
      pptr.Page page, {
      required _Point pointer,
      required List<num> preview,
    }) async {
      await configure(
        page,
        items: threeRows,
        glide: false,
        preview: {'width': preview[0], 'height': preview[1]},
      );
      await page.evaluate<void>(sampleJs);
      await page.mouse.click(
        pptr.Point(pointer.x, pointer.y),
        button: pptr.MouseButton.right,
      );
      await page.waitForFunction(
        placedJs,
        timeout: const Duration(seconds: 30),
      );
      await _frames(page, 3);

      return (await readPreview(page))!;
    }

    CorePreviewPlacement expectedPlacement(
      Map<String, Object?> read,
      int width,
      int height, {
      required bool rtl,
    }) {
      final preview = _boxOf(read['preview']);
      const margin = CorePopoverStyle.defaultViewportPadding;

      return CoreContextMenuPreview.place(
        menu: _boxOf(read['menu']),
        previewWidth: preview.width,
        previewHeight: preview.height,
        viewport: CoreMenuBox(
          left: margin.left,
          top: margin.top,
          right: width - margin.right,
          bottom: height - margin.bottom,
        ),
        direction: rtl ? .rtl : .ltr,
      );
    }

    String physicalSide(CoreMenuBox menu, CoreMenuBox preview) {
      if (preview.bottom <= menu.top + _kTolerance) return 'above';
      if (preview.top >= menu.bottom - _kTolerance) return 'below';
      if (preview.left >= menu.right - _kTolerance) return 'right';
      if (preview.right <= menu.left + _kTolerance) return 'left';

      return 'overlapping';
    }

    for (final scenario in scenarios) {
      test(scenario['name']! as String, () async {
        final viewport = (scenario['viewport']! as List).cast<num>();
        final pointer = (scenario['pointer']! as List).cast<num>();
        final preview = (scenario['preview']! as List).cast<num>();
        final rtl = scenario['direction'] == 'rtl';
        final page = await openPage(
          width: viewport[0].toInt(),
          height: viewport[1].toInt(),
        );
        try {
          if (rtl) {
            await page.evaluate<void>(
              "() => { document.documentElement.dir = 'rtl'; }",
            );
          }
          final read = await openWithPreview(
            page,
            pointer: (x: pointer[0].toDouble(), y: pointer[1].toDouble()),
            preview: preview,
          );
          printOnFailure('read: ${jsonEncode(read)}');
          final menu = _boxOf(read['menu']);
          final box = _boxOf(read['preview']);
          final content = _boxOf(read['content']);

          // Where the rule puts it, around the menu Chrome laid out.
          final placement = expectedPlacement(
            read,
            viewport[0].toInt(),
            viewport[1].toInt(),
            rtl: rtl,
          );
          expect(placement.capped, isFalse, reason: 'the scenario fits');
          expect(placement.visible, isTrue);
          expect(box.left, closeTo(placement.box.left, _kTolerance));
          expect(box.top, closeTo(placement.box.top, _kTolerance));
          expect(box.right, closeTo(placement.box.right, _kTolerance));
          expect(box.bottom, closeTo(placement.box.bottom, _kTolerance));

          // And on the side the scenario names.
          expect(physicalSide(menu, box), scenario['physical']);
          expect(
            content.width,
            closeTo(preview[0].toDouble(), _kTolerance),
            reason: 'the preview keeps its own size',
          );

          // Never over the menu, never off the screen, and the gap is the gap.
          expect(box.intersect(menu), isNull);
          expect(box.left, greaterThanOrEqualTo(-_kTolerance));
          expect(box.top, greaterThanOrEqualTo(-_kTolerance));
          expect(box.right, lessThanOrEqualTo(viewport[0] + _kTolerance));
          expect(box.bottom, lessThanOrEqualTo(viewport[1] + _kTolerance));
          final gap = switch (scenario['physical']) {
            'above' => menu.top - box.bottom,
            'below' => box.top - menu.bottom,
            'right' => box.left - menu.right,
            _ => menu.left - box.right,
          };
          expect(gap, closeTo(_kGap, _kTolerance));

          // What it is: a fixed panel in the top layer that ignores the
          // pointer, and fades in with the panel.
          expect(read['position'], 'fixed');
          expect(read['pointerEvents'], 'none');
          expect(read['popoverOpen'], isTrue);
          expect(read['hitIsPreview'], isFalse, reason: 'a tap passes through');
          expect(read['animation'], 'co-overlay-enter');

          // It was never seen before it was placed.
          final frames = _list(
            jsonDecode(
              await page.evaluate<String>(
                '() => JSON.stringify(window.__frames)',
              ),
            ),
          );
          final unplaced = frames.where((frame) => frame['placed'] == false);
          expect(unplaced, isNotEmpty, reason: 'the sampler saw it unplaced');
          expect(
            unplaced.every(
              (frame) => frame['opacity'] == 0 && frame['animation'] == 'none',
            ),
            isTrue,
            reason: 'and it was transparent and not yet animating: $unplaced',
          );

          // It goes with the menu.
          await page.keyboard.press(pptr.Key.escape);
          await page.waitForFunction(
            goneJs,
            timeout: const Duration(seconds: 15),
          );
        } finally {
          await page.close();
        }
      }, skip: skip);
    }

    test('follows the menu when the page scrolls under it', () async {
      final page = await openPage(width: 390, height: 844);
      try {
        final first = await openWithPreview(
          page,
          pointer: (x: 100.0, y: 600.0),
          preview: const [200, 120],
        );
        final before = _boxOf(first['menu']);

        await page.evaluate<void>('() => window.scrollBy(0, 40)');
        // The engine measures the anchor again, the menu moves, and the
        // preview is placed around where it moved to.
        await _frames(page, 6);
        final settled = await _stable(page, () async {
          final now = (await readPreview(page))!;

          return [now['menu'], now['preview']];
        });
        final moved = {'menu': settled[0], 'preview': settled[1]};

        final menu = _boxOf(moved['menu']);
        expect(
          menu.top,
          closeTo(before.top - 40, 1),
          reason: 'the menu followed the page',
        );
        final placement = expectedPlacement(moved, 390, 844, rtl: false);
        final box = _boxOf(moved['preview']);
        expect(box.left, closeTo(placement.box.left, _kTolerance));
        expect(box.top, closeTo(placement.box.top, _kTolerance));
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('is held to the room when it is larger than any side has', () async {
      final page = await openPage();
      try {
        final read = await openWithPreview(
          page,
          pointer: (x: 180.0, y: 240.0),
          preview: const [320, 400],
        );
        final menu = _boxOf(read['menu']);
        final box = _boxOf(read['preview']);
        final placement = expectedPlacement(read, 360, 480, rtl: false);

        expect(box.intersect(menu), isNull, reason: 'never over the menu');
        expect(box.left, greaterThanOrEqualTo(-_kTolerance));
        expect(box.right, lessThanOrEqualTo(360 + _kTolerance));
        expect(box.top, greaterThanOrEqualTo(-_kTolerance));
        expect(box.bottom, lessThanOrEqualTo(480 + _kTolerance));
        expect(box.left, closeTo(placement.box.left, _kTolerance));
        expect(box.top, closeTo(placement.box.top, _kTolerance));
        expect(box.width, closeTo(placement.box.width, _kTolerance));
        expect(box.height, closeTo(placement.box.height, _kTolerance));
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('goes with a menu a finger chose a row of', () async {
      final page = await openPage();
      try {
        await configure(
          page,
          items: threeRows,
          haptics: true,
          preview: {'width': 100, 'height': 60},
        );
        final finger = _Finger(page);
        await finger.down((x: 60.0, y: 300.0));
        await settleAfter(page);
        await page.waitForFunction(
          placedJs,
          timeout: const Duration(seconds: 30),
        );

        final menu = (await _readMenu(page))!;
        final row = menu.rows[1].box;
        await finger.move((
          x: row.left + row.width / 2,
          y: row.top + row.height / 2,
        ));
        final lit = await _stable(
          page,
          () => _litState(page).then((state) => state.lit),
        );
        expect(lit, 1);
        await finger.up();
        await page.waitForFunction(
          goneJs,
          timeout: const Duration(seconds: 15),
        );

        expect(await _activated(page), [1]);
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('is not placed around a panel the engine has not placed '
        'yet', () async {
      // The placement is asked for whenever the host is rebuilt while the menu
      // is open — including in the frame before the engine has given the panel
      // its place. A panel without a place sits wherever layout left it, and a
      // preview placed around that box would flash there. The engine's frame is
      // held so the placement attempt can be made first, deterministically.
      final page = await openPage();
      try {
        await configure(
          page,
          items: threeRows,
          glide: false,
          preview: {'width': 100, 'height': 60},
        );
        await page.evaluate<void>('''
() => {
  window.__held = [];
  window.__nativeRaf = window.requestAnimationFrame.bind(window);
  window.requestAnimationFrame = (callback) => {
    window.__held.push(callback);
    return window.__held.length;
  };
}''');
        await page.mouse.click(
          const pptr.Point(60, 300),
          button: pptr.MouseButton.right,
        );
        await page.waitForFunction(
          '''
() => !!document.querySelector('[id^="co-context-menu-panel"]')
  && !!document.querySelector('[id^="co-context-menu-preview"]')''',
          polling: pptr.Polling.interval(const Duration(milliseconds: 10)),
          timeout: const Duration(seconds: 15),
        );
        const stateJs = '''
() => {
  const panel = document.querySelector('[id^="co-context-menu-panel"]');
  const preview = document.querySelector('[id^="co-context-menu-preview"]');
  return JSON.stringify({
    panelLeft: panel.style.left,
    previewLeft: preview.style.left,
    held: window.__held.length,
  });
}''';
        Future<Map<String, Object?>> state() async =>
            jsonDecode(await page.evaluate<String>(stateJs))
                as Map<String, Object?>;

        final before = await state();
        printOnFailure('before: $before');
        expect(
          before['panelLeft'],
          '',
          reason: 'the premise: the panel is in the page and has no place',
        );
        expect(before['previewLeft'], '');

        // Rebuild the host with the same configuration: it asks for the
        // preview to be placed, in a frame of its own queued behind the
        // engine's. That frame is run on its own, ahead of the engine's.
        await page.evaluate<void>(
          '(c) => couiGlideConfigure(c)',
          args: [
            jsonEncode({
              'items': threeRows,
              'glide': false,
              'haptics': false,
              'preview': {'width': 100, 'height': 60},
            }),
          ],
        );
        final queued = await state();
        printOnFailure('queued: $queued');
        expect(
          queued['held'],
          (before['held']! as int) + 1,
          reason: 'the premise: the rebuild queued a frame of its own',
        );
        await page.evaluate<void>(
          '(index) => window.__held.splice(index, 1)[0](performance.now())',
          args: [before['held']],
        );
        final attempted = await state();
        printOnFailure('attempted: $attempted');
        expect(
          attempted['panelLeft'],
          '',
          reason: 'the engine has still not placed the panel',
        );
        expect(
          attempted['previewLeft'],
          '',
          reason: 'so the preview is not placed around where it happens to be',
        );

        // Let the frames run: the engine places the panel, and the preview
        // follows it to the place the rule gives.
        await page.evaluate<void>('''
() => {
  window.requestAnimationFrame = window.__nativeRaf;
  window.__held.splice(0).forEach((callback) => window.__nativeRaf(callback));
}''');
        await page.waitForFunction(
          placedJs,
          timeout: const Duration(seconds: 30),
        );
        await _frames(page, 3);
        final read = (await readPreview(page))!;
        printOnFailure('read: ${jsonEncode(read)}');
        final expected = expectedPlacement(
          read,
          _kPhoneWidth,
          _kPhoneHeight,
          rtl: false,
        );
        final box = _boxOf(read['preview']);
        expect(box.left, closeTo(expected.box.left, _kTolerance));
        expect(box.top, closeTo(expected.box.top, _kTolerance));
      } finally {
        await page.close();
      }
    }, skip: skip);

    test('shares its entry with the screen-reader dismiss node, which closes '
        'both', () async {
      final page = await openPage();
      try {
        await openWithPreview(
          page,
          pointer: (x: 60.0, y: 300.0),
          preview: [100, 60],
        );
        // The assistive-technology twin of a click outside the menu sits
        // beside the panel in the same entry the preview is mounted in.
        final json = await page.evaluate<String>('''
() => {
  const node = document.querySelector('[data-coui-modal-dismiss]');
  const panel = document.querySelector('[id^="co-context-menu-panel"]');
  const preview = document.querySelector('[id^="co-context-menu-preview"]');
  if (!node || !panel || !preview) return JSON.stringify(null);
  return JSON.stringify({
    role: node.getAttribute('role'),
    tabindex: node.getAttribute('tabindex'),
    label: node.getAttribute('aria-label'),
    sameEntry: node.parentElement === panel.parentElement &&
      node.parentElement === preview.parentElement,
  });
}''');
        final read = jsonDecode(json) as Map<String, Object?>?;
        printOnFailure('read: $json');
        expect(
          read,
          isNotNull,
          reason: 'the dismiss node, the panel and the preview are all there',
        );
        expect(read!['role'], 'button');
        expect(read['tabindex'], '-1');
        expect(read['sameEntry'], isTrue);
        expect((read['label']! as String).isNotEmpty, isTrue);

        await page.evaluate<void>(
          "() => document.querySelector('[data-coui-modal-dismiss]').click()",
        );
        await page.waitForFunction(
          goneJs,
          timeout: const Duration(seconds: 15),
        );
        expect(
          await page.evaluate<bool>(
            "() => !document.querySelector('[data-coui-modal-dismiss]')",
          ),
          isTrue,
          reason: 'the node goes with the entry',
        );
      } finally {
        await page.close();
      }
    }, skip: skip);
  }, timeout: const Timeout(Duration(minutes: 30)));
}
