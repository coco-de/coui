// The Web `SwipeActions` row, driven by real input in Chrome: a drag, a flick,
// a full swipe, a press of another button than the main one, Tab and Escape,
// a rebuild under a focused action, a second row in the same scope, a row in
// the content of another, a right-to-left reading direction, reduced motion.
//
// The VM cannot reach the row's DOM half — it needs real `PointerEvent`s, a
// real layout to measure the strips in and a real pointer capture (see
// `packages/coui_web/test/components/layout/swipe_actions_test.dart`). What it
// does with a pointer once the numbers are in is Core's, pinned by
// `packages/coui_core/test/fixtures/swipe_actions_vectors.json`; the Flutter
// widget replays the same table on the framework's recogniser and the Web
// row model replays it with a manual clock. This file puts the compiled
// shipped component through the same rows with trusted input, so the three
// seats are held to one table and the Web one is held to it in a browser.
//
// ## How the pointer is driven, and why its clock is stamped
//
// The strokes go through the DevTools input domain: trusted events the
// browser routes through hit testing and pointer capture exactly as it does a
// real mouse. Each carries an explicit `timestamp` — the table's own, in
// milliseconds — and Chrome hands that to the page as
// `PointerEvent.timeStamp`. A speed is a distance over a time and the time the
// row reads is the event's own clock, so stamping it makes a stroke's speed the
// table's speed whatever the machine is doing. One event is sent per frame, so
// the page sees the stroke that was sent instead of whatever coalescing leaves
// of it.
//
// ## What is read off the page
//
// The row's offset is its painted position — `getBoundingClientRect` of the
// sliding row against its root — and is compared with the table after every
// move, so a row that "follows the pointer" is judged by where it is, not by
// what it was told.
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;

import 'package:coui_web/coui_web.dart'
    show CoreDensity, CoreSwipeActionsStyle, ThemeConfig;
import 'package:puppeteer/protocol/input.dart'
    show InputApi, MouseButton, TimeSinceEpoch, TouchPoint;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// The vector table shared with Core, Flutter and the VM Web tests (cwd is the
/// repository root under `dart test tool/parity/test`).
const String _kVectorsPath =
    'packages/coui_core/test/fixtures/swipe_actions_vectors.json';

const String _kEntryPath = 'tool/parity/src/web/swipe_actions_entry.dart';

const int _kViewportWidth = 800;
const int _kViewportHeight = 700;

/// Where the entry puts slot 0: its left edge and top edge on the page. The
/// table's pointer coordinates are in the row's own box, from its top-left.
const double _kSlotLeft = 100;
const double _kSlotTop = 100;

/// The vertical distance between two slots.
const double _kSlotStep = 120;

const String _kIdPrefix = 'row-';

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

/// What the page says about one row, read in one go.
typedef _Geo = ({
  double left,
  double top,
  double width,
  double height,
  double offset,
  String state,
  String? side,
  double? leadingPlatter,
  double? trailingPlatter,
  double? leadingStrip,
  double? trailingStrip,
});

/// One pointer, with a clock of its own: the table's.
///
/// Every event it sends is stamped `origin + clock`, where the origin is "now"
/// when the pointer is created — Chrome only honours a stamp that is a
/// plausible wall-clock time — and the clock is set to exactly the table's
/// time, not to however long the process took.
///
/// It presses the main button unless [button] says another one.
class _Pointer {
  _Pointer(this._page, {this.button = MouseButton.left})
    : _input = _page.devTools.input,
      _origin = DateTime.now().millisecondsSinceEpoch / 1000;

  final pptr.Page _page;
  final MouseButton button;
  final InputApi _input;
  final double _origin;
  Duration _clock = Duration.zero;
  Point<double> _at = const Point(0, 0);

  /// The `buttons` bit of [button] while it is held.
  int get _held => switch (button) {
    MouseButton.left => 1,
    MouseButton.right => 2,
    MouseButton.middle => 4,
    _ => 0,
  };

  TimeSinceEpoch _stamp(int atMs) => TimeSinceEpoch(
    _origin + Duration(milliseconds: atMs).inMicroseconds / 1000000,
  );

  /// Waits for the next frame, so the browser delivers what was sent so far
  /// as its own event.
  Future<void> _frame() => _page.evaluate<void>(
    '() => new Promise(resolve => requestAnimationFrame(() => resolve()))',
  );

  Future<void> down(Point<double> at, {required int atMs}) async {
    _at = at;
    _clock = Duration(milliseconds: atMs);
    await _input.dispatchMouseEvent(
      'mouseMoved',
      at.x,
      at.y,
      timestamp: _stamp(atMs),
    );
    await _input.dispatchMouseEvent(
      'mousePressed',
      at.x,
      at.y,
      button: button,
      buttons: _held,
      clickCount: 1,
      timestamp: _stamp(atMs),
    );
    await _frame();
  }

  Future<void> move(Point<double> to, {required int atMs}) async {
    _at = to;
    _clock = Duration(milliseconds: atMs);
    await _input.dispatchMouseEvent(
      'mouseMoved',
      to.x,
      to.y,
      button: button,
      buttons: _held,
      timestamp: _stamp(atMs),
    );
    await _frame();
  }

  /// Lifts where the pointer is, [atMs] on the table's clock.
  Future<void> up({required int atMs}) async {
    _clock = Duration(milliseconds: atMs);
    await _input.dispatchMouseEvent(
      'mouseReleased',
      _at.x,
      _at.y,
      button: button,
      buttons: 0,
      clickCount: 1,
      timestamp: _stamp(atMs),
    );
  }

  /// A plain click: press and lift, [heldMs] apart.
  Future<void> tap(Point<double> at, {int heldMs = 60}) async {
    await down(at, atMs: _clock.inMilliseconds);
    await up(atMs: _clock.inMilliseconds + heldMs);
  }
}

/// One finger, stamped on the table's clock like [_Pointer].
///
/// Touch emulation has to be on for the browser to treat these as touch
/// (`pointerType: touch`, `touch-action` honoured).
class _Finger {
  _Finger(this._page)
    : _input = _page.devTools.input,
      _origin = DateTime.now().millisecondsSinceEpoch / 1000;

  final pptr.Page _page;
  final InputApi _input;
  final double _origin;

  TimeSinceEpoch _stamp(int atMs) => TimeSinceEpoch(
    _origin + Duration(milliseconds: atMs).inMicroseconds / 1000000,
  );

  Future<void> _send(String type, int atMs, [Point<double>? at]) async {
    await _input.dispatchTouchEvent(type, [
      if (at != null) TouchPoint(x: at.x, y: at.y),
    ], timestamp: _stamp(atMs));
    await _page.evaluate<void>(
      '() => new Promise(resolve => requestAnimationFrame(() => resolve()))',
    );
  }

  Future<void> down(Point<double> at, {required int atMs}) =>
      _send('touchStart', atMs, at);

  Future<void> move(Point<double> to, {required int atMs}) =>
      _send('touchMove', atMs, to);

  Future<void> up({required int atMs}) => _send('touchEnd', atMs);

  /// The system takes the finger away: `pointercancel`.
  Future<void> cancel({required int atMs}) => _send('touchCancel', atMs);
}

void main() {
  final repoRoot = Directory.current.path;
  final chromePath = _systemChromePath();
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final styleNumbers = doc['style']! as Map<String, Object?>;
  final gestures = (doc['gestures']! as List<Object?>)
      .cast<Map<String, Object?>>();

  double extent(int count) => CoreSwipeActionsStyle.extentFor(
    count,
    actionWidth: (styleNumbers['actionWidth']! as num).toDouble(),
    actionSpacing: (styleNumbers['actionSpacing']! as num).toDouble(),
    platterInset: (styleNumbers['platterInset']! as num).toDouble(),
  );

  late pptr.Browser browser;
  late Directory fixture;
  late File html;
  late pptr.Page page;

  Future<void> frames(int count) async {
    for (var i = 0; i < count; i++) {
      await page.evaluate<void>(
        '() => new Promise(resolve => requestAnimationFrame(() => resolve()))',
      );
    }
  }

  /// Mounts [rows] (see the entry for the keys) and waits until they are in
  /// the document.
  Future<void> mount(List<Map<String, Object?>> rows) async {
    await page.evaluate<void>(
      '(specs) => couiSwipeMount(specs)',
      args: [jsonEncode(rows)],
    );
    for (final row in rows) {
      await page.waitForFunction(
        '''
() => document.getElementById("$_kIdPrefix${row['id']}") !== null''',
      );
    }
    await frames(3);
  }

  Future<_Geo> geo(String id) async {
    final json = await page.evaluate<String>(
      '''
(id) => {
        const root = document.getElementById('row-' + id);
        const rect = root.getBoundingClientRect();
        const row = root
          .querySelector(':scope > [data-swipe-row]')
          .getBoundingClientRect();
        const width = (selector) => {
          const el = root.querySelector(selector);
          return el ? el.getBoundingClientRect().width : null;
        };
        return JSON.stringify({
          left: rect.left, top: rect.top, width: rect.width,
          height: rect.height, offset: row.left - rect.left,
          state: root.dataset.swipeState, side: root.dataset.swipeSide ?? null,
          leadingPlatter: width(':scope > [data-swipe-platter="leading"]'),
          trailingPlatter: width(':scope > [data-swipe-platter="trailing"]'),
          leadingStrip:
            width(':scope > [data-swipe-platter="leading"] > [data-swipe-strip]'),
          trailingStrip:
            width(':scope > [data-swipe-platter="trailing"] > [data-swipe-strip]'),
        });
      }''',
      args: [id],
    );
    final v = jsonDecode(json) as Map<String, Object?>;
    double? number(String key) => (v[key] as num?)?.toDouble();

    return (
      left: number('left')!,
      top: number('top')!,
      width: number('width')!,
      height: number('height')!,
      offset: number('offset')!,
      state: v['state']! as String,
      side: v['side'] as String?,
      leadingPlatter: number('leadingPlatter'),
      trailingPlatter: number('trailingPlatter'),
      leadingStrip: number('leadingStrip'),
      trailingStrip: number('trailingStrip'),
    );
  }

  Future<List<String>> log() async {
    final json = await page.evaluate<String>('() => couiSwipeLog()');

    return (jsonDecode(json) as List<Object?>).cast<String>();
  }

  Future<String?> focused() => page.evaluate<String?>(
    '''
() => document.activeElement
        ? (document.activeElement.getAttribute('aria-label') ||
           document.activeElement.id || document.activeElement.tagName)
        : null''',
  );

  /// Tabs until [label] has focus, so a test says which action a keyboard
  /// user is on rather than how many keys it took to get there.
  Future<void> tabTo(String label) async {
    for (var i = 0; i < 8; i++) {
      await page.keyboard.press(pptr.Key.tab);
      if (await focused() == label) return;
    }
    fail('Tab never reached "$label"; focus is on ${await focused()}');
  }

  /// Puts focus on the element with [id] the way script does, without a key.
  Future<void> focusElement(String id) => page.evaluate<void>(
    '(id) => document.getElementById(id).focus()',
    args: [id],
  );

  /// Puts focus on the action labelled [label] of the row whose DOM id is
  /// `row-<id>`, the way script does, without a key.
  Future<void> focusAction(String id, String label) => page.evaluate<void>(
    '''
(id, label) => document
        .querySelector('#row-' + id + ' button[aria-label="' + label + '"]')
        .focus()''',
    args: [id, label],
  );

  /// Sets what the page does in the middle of the next rebuild, once the rows
  /// have been updated: [body] is the statements of a host that acts as part
  /// of the same update.
  Future<void> duringUpdate(String body) => page.evaluate<void>(
    '(body) => { window.couiSwipeDuringUpdate = new Function(body); }',
    args: [body],
  );

  /// Waits for the row to come to rest at [target] (px, physical) in a state
  /// that is not "dragging", and returns where it is.
  Future<_Geo> settled(String id, double target) async {
    _Geo? last;
    for (var i = 0; i < 80; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      last = await geo(id);
      if (last.state != 'dragging' && (last.offset - target).abs() <= 0.6) {
        return last;
      }
    }
    fail(
      'row $id never came to rest at $target (state ${last?.state}, '
      'offset ${last?.offset})',
    );
  }

  Point<double> pageOf(double x, double y, {int slot = 0}) =>
      Point(_kSlotLeft + x, _kSlotTop + slot * _kSlotStep + y);

  /// A slow drag that opens [trailing] (or the leading side) by [travel] px —
  /// 250 px/s, well under a fling — and waits for it to rest open.
  Future<_Geo> openByDrag(
    String id, {
    required bool trailing,
    required double restsAt,
    bool rtl = false,
    int slot = 0,
    double travel = 200,
  }) async {
    final direction = (trailing ? -1.0 : 1.0) * (rtl ? -1.0 : 1.0);
    final pointer = _Pointer(page);
    await pointer.down(pageOf(300, 36, slot: slot), atMs: 0);
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      await pointer.move(
        pageOf(300 + direction * travel * i / steps, 36, slot: slot),
        atMs: i * 100,
      );
    }
    await pointer.up(atMs: 900);

    final rest = await settled(id, restsAt);

    return rest;
  }

  /// Replays one row of the shared table in Chrome.
  Future<void> replay(Map<String, Object?> vector) async {
    const id = 't';
    final rtl = vector['rtl'] == true;
    final leading = (vector['leading'] as int?) ?? 0;
    final trailing = (vector['trailing'] as int?) ?? 0;
    await mount([
      {
        'id': id,
        'leading': leading,
        'trailing': trailing,
        'fullSwipe':
            vector['leadingFullSwipe'] != false &&
            vector['trailingFullSwipe'] != false,
        'rtl': rtl,
      },
    ]);

    // A row that starts open is opened by a real drag first, then grabbed
    // over its content (not over an action) so the table's strokes apply.
    final startOffset = ((vector['startOffset'] as num?) ?? 0).toDouble();
    var shift = 0.0;
    final events = (vector['events']! as List<Object?>)
        .cast<Map<String, Object?>>();
    if (startOffset != 0) {
      final opened = await openByDrag(
        id,
        trailing: (startOffset < 0) != rtl,
        restsAt: startOffset,
        rtl: rtl,
      );
      expect(opened.state, 'open', reason: 'the row starts open');
      shift = 150 - (events.first['x']! as num).toDouble();
    }
    await page.evaluate<void>('() => couiSwipeClear()');

    final expectedOffsets = (vector['offsets']! as List<Object?>)
        .cast<num>()
        .map((n) => n.toDouble())
        .toList();
    final released = vector['release'] as Map<String, Object?>?;
    final pointer = _Pointer(page);
    var move = 0;
    var last = const Point<double>(0, 0);
    for (final event in events) {
      final atMs = (event['at']! as num).toInt();
      if (event['x'] != null) {
        last = Point(
          (event['x']! as num).toDouble(),
          (event['y']! as num).toDouble(),
        );
      }
      switch (event['kind']! as String) {
        case 'down':
          await pointer.down(
            pageOf(
              (event['x']! as num).toDouble() + shift,
              (event['y']! as num).toDouble(),
            ),
            atMs: atMs,
          );
        case 'move':
          await pointer.move(
            pageOf(
              (event['x']! as num).toDouble() + shift,
              (event['y']! as num).toDouble(),
            ),
            atMs: atMs,
          );
          await frames(1);
          expect(
            (await geo(id)).offset,
            closeTo(expectedOffsets[move], 0.6),
            reason: 'offset after move ${move + 1} of "${vector['name']}"',
          );
          move++;
        case 'up':
          await pointer.up(atMs: atMs);
      }
    }
    expect(move, expectedOffsets.length);

    final entries = <String>[];
    if (released == null) {
      // A tap, or a stroke that went vertical: the row is where it was, and
      // the browser's click reaches the row's content.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final rest = await geo(id);
      expect(rest.offset, closeTo(startOffset, 0.6));
      expect(rest.state, startOffset == 0 ? 'closed' : 'open');
      entries.addAll(await log());
      // The browser sends the click to the row's content when the pointer
      // is still over the row when it lifts; a stroke that left the row
      // before the lift sends it somewhere else.
      final overRow =
          last.x >= 0 && last.x <= 400 && last.y >= 0 && last.y <= 72;
      if (overRow) {
        expect(entries, contains('$id:content'), reason: 'a tap is a click');
      }
      expect(entries, isNot(contains('$id:Archive')));

      return;
    }

    final outcome = released['outcome']! as String;
    final target = (released['target']! as num).toDouble();
    final rest = await settled(id, target);
    final isOpen = outcome.startsWith('open');
    expect(rest.state, isOpen ? 'open' : 'closed', reason: outcome);
    if (isOpen) {
      expect(
        rest.side,
        outcome == 'openLeading' ? 'leading' : 'trailing',
        reason: 'the side it rests open on',
      );
    }
    entries.addAll(await log());
    // The first action of the side runs on a full swipe, and nothing else
    // does; the drag's own click reaches neither the content nor the caller.
    final firstLabel = outcome == 'executeLeading' ? 'Pin' : 'Archive';
    expect(
      entries,
      outcome.startsWith('execute') ? ['$id:$firstLabel'] : isEmpty,
      reason: 'what ran: $outcome',
    );
  }

  group(
    'the Web SwipeActions, with real input in Chrome',
    () {
      setUpAll(() async {
        fixture = Directory.systemTemp.createTempSync('coui-swipe-actions-');
        final js = '${fixture.path}/entry.js';
        final result = await Process.run(Platform.resolvedExecutable, [
          'compile',
          'js',
          '-O2',
          '-o',
          js,
          _kEntryPath,
        ]);
        expect(
          result.exitCode,
          0,
          reason: 'compiling the probe entry failed:\n${result.stderr}',
        );
        // Real motion: only the capture harness freezes transitions, and the
        // settle is part of what is being judged.
        final content = buildOfflineTailwindHarnessHtml(
          bodyHtml: '<script>${File(js).readAsStringSync()}</script>',
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(
            repoRoot: repoRoot,
          ),
        ).replaceFirst('<style>$kCaptureAnimationFreezeCss</style>', '');
        html = File('${fixture.path}/index.html')..writeAsStringSync(content);
        browser = await launchCaptureBrowser(
          width: _kViewportWidth,
          height: _kViewportHeight,
          executablePath: chromePath,
        );
      });

      setUp(() async {
        page = await browser.newPage();
        await page.goto(Uri.file(html.path).toString(), wait: pptr.Until.load);
        await page.waitForFunction(
          '() => typeof couiSwipeMount === "function"',
        );
      });

      tearDown(() => page.close());

      tearDownAll(() async {
        await browser.close();
        fixture.deleteSync(recursive: true);
      });

      group('the shared gestures table, as trusted pointer input', () {
        for (final vector in gestures) {
          final events = (vector['events']! as List<Object?>)
              .cast<Map<String, Object?>>();
          // A cancel needs a touch pointer the system takes away; the model
          // test and the Flutter widget replay those rows.
          if (events.any((event) => event['kind'] == 'cancel')) continue;
          test(vector['name']! as String, () => replay(vector));
        }
      });

      group('layout', () {
        test(
          'the measured strips are the platter widths Core states',
          () async {
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 2},
            ]);

            final rest = await geo('t');
            expect(rest.leadingStrip, closeTo(extent(1), 0.5));
            expect(rest.trailingStrip, closeTo(extent(2), 0.5));
            expect(rest.leadingStrip, 72);
            expect(rest.trailingStrip, 132);
            expect(rest.width, 400);
            expect(rest.height, 72);
          },
        );

        test(
          'closed, the platters are as wide as nothing and the row is home',
          () async {
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 2},
            ]);

            final rest = await geo('t');
            expect(rest.leadingPlatter, 0);
            expect(rest.trailingPlatter, 0);
            expect(rest.offset, 0);
            expect(rest.state, 'closed');
          },
        );

        test(
          'at another density the row travels as far as the platter is wide',
          () async {
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 2},
            ]);
            await page.evaluate<void>('''
() => document.documentElement.setAttribute('data-coui-density', 'compact')
''');
            await frames(3);

            // The numbers the compact density states for the default cell,
            // spacing and inset — the strips are measured, so whatever the
            // variables resolve to is how far the row must open.
            const density = CoreDensity.compact;
            double extentOf(int count) => CoreSwipeActionsStyle.extentFor(
              count,
              actionWidth: density.controlHeight(48),
              actionSpacing: density.space(12),
              platterInset: density.space(12),
            );
            final rest = await geo('t');
            expect(rest.trailingStrip, closeTo(extentOf(2), 0.5));
            expect(rest.leadingStrip, closeTo(extentOf(1), 0.5));
            expect(
              extentOf(2),
              lessThan(132),
              reason: 'the density really moved the platter',
            );

            final open = await openByDrag(
              't',
              trailing: true,
              restsAt: -extentOf(2),
            );
            expect(open.state, 'open');
            expect(open.trailingPlatter, closeTo(extentOf(2), 0.5));
          },
        );

        test(
          'the browser keeps vertical panning, and clips the travel',
          () async {
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 2},
              {'id': 'off', 'leading': 1, 'trailing': 2, 'enabled': false},
            ]);

            Future<List<String>> styles(String id) async {
              final json = await page.evaluate<String>(
                '''
(id) => {
                const style = getComputedStyle(document.getElementById('row-' + id));
                return JSON.stringify([style.touchAction, style.overflowX, style.overflowY]);
              }''',
                args: [id],
              );

              return (jsonDecode(json) as List<Object?>).cast<String>();
            }

            expect(await styles('t'), ['pan-y', 'clip', 'visible']);
            // A row that cannot be swiped has no reason to take horizontal
            // panning from whatever scrolls around it.
            expect((await styles('off')).first, 'auto');
          },
        );

        test('DOM order is visual order in either direction', () async {
          await mount([
            {'id': 'ltr', 'leading': 1, 'trailing': 2},
            {'id': 'rtl', 'leading': 1, 'trailing': 2, 'rtl': true},
          ]);

          Future<List<({String label, double left, bool reachable})>> buttons(
            String id,
          ) async {
            final json = await page.evaluate<String>(
              '''
(id) => JSON.stringify(
                [...document.getElementById('row-' + id).querySelectorAll('button')]
                  .map((b) => ({
                    label: b.getAttribute('aria-label'),
                    left: b.getBoundingClientRect().left,
                    reachable: getComputedStyle(b).visibility === 'visible' &&
                      getComputedStyle(b).display !== 'none',
                  })))''',
              args: [id],
            );

            return (jsonDecode(json) as List<Object?>)
                .cast<Map<String, Object?>>()
                .map(
                  (b) => (
                    label: b['label']! as String,
                    left: (b['left']! as num).toDouble(),
                    reachable: b['reachable']! as bool,
                  ),
                )
                .toList();
          }

          final ltr = await buttons('ltr');
          expect(ltr.map((b) => b.label), ['Pin', 'Delete', 'Archive']);
          // Left to right: reading order is the DOM order, and the first
          // action of the trailing side is the one at the end edge.
          expect(ltr[0].left, lessThan(ltr[1].left));
          expect(ltr[1].left, lessThan(ltr[2].left));

          final rtl = await buttons('rtl');
          expect(rtl.map((b) => b.label), ['Pin', 'Delete', 'Archive']);
          // Right to left: reading order runs the other way, so does the page.
          expect(rtl[0].left, greaterThan(rtl[1].left));
          expect(rtl[1].left, greaterThan(rtl[2].left));

          // Clipped, never hidden: a screen reader and Tab still reach them.
          for (final b in [...ltr, ...rtl]) {
            expect(b.reachable, isTrue, reason: b.label);
          }
        });

        test('the visible label is not read twice', () async {
          await mount([
            {'id': 't', 'trailing': 1},
          ]);

          final json = await page.evaluate<String>(
            '''
() => JSON.stringify({
              name: document.querySelector('#row-t button').getAttribute('aria-label'),
              labels: [...document.querySelectorAll('#row-t [aria-hidden="true"]')]
                .map((el) => el.textContent.trim()),
            })''',
          );
          final read = jsonDecode(json) as Map<String, Object?>;
          expect(read['name'], 'Archive');
          expect(read['labels'], contains('Archive'));
        });

        test(
          'a right-to-left row opens its leading platter on the right',
          () async {
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 1, 'rtl': true},
            ]);

            await openByDrag(
              't',
              trailing: false,
              restsAt: -72,
              rtl: true,
            );
            final rest = await geo('t');
            final json = await page.evaluate<String>(
              '''
() => {
              const root = document.getElementById('row-t');
              const platter = root.querySelector(':scope > [data-swipe-platter="leading"]')
                .getBoundingClientRect();
              return JSON.stringify([platter.left, platter.right, root.getBoundingClientRect().right]);
            }''',
            );
            final edges = (jsonDecode(json) as List<Object?>).cast<num>();
            expect(rest.side, 'leading');
            expect(rest.offset, -72);
            expect(
              edges[1],
              closeTo(edges[2], 0.5),
              reason: 'at the right edge',
            );
            expect(edges[1] - edges[0], closeTo(72, 0.5));
          },
        );
      });

      group('the drag', () {
        test(
          'a pulled platter is exactly as wide as the row has left it',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            final pointer = _Pointer(page);
            await pointer.down(pageOf(300, 36), atMs: 0);
            await pointer.move(pageOf(270, 36), atMs: 100);
            await pointer.move(pageOf(240, 36), atMs: 200);
            await frames(1);

            final mid = await geo('t');
            expect(mid.state, 'dragging');
            expect(mid.offset, closeTo(-30, 0.6));
            expect(mid.trailingPlatter, closeTo(30, 0.6));
            expect(mid.leadingPlatter, isNull, reason: 'no leading actions');
            await pointer.up(atMs: 1000);
            await settled('t', 0);
          },
        );

        test('a drag that starts on an action does not press it', () async {
          await mount([
            {'id': 't', 'trailing': 2},
          ]);
          await openByDrag('t', trailing: true, restsAt: -132);
          await page.evaluate<void>('() => couiSwipeClear()');

          // Over the first action (the one at the end edge), pulling the
          // row closed.
          final first = await page.evaluate<String>(
            '''
() => {
              const r = document.querySelector('#row-t button[aria-label="Archive"]')
                .getBoundingClientRect();
              return JSON.stringify([r.left + r.width / 2, r.top + r.height / 2]);
            }''',
          );
          final at = (jsonDecode(first) as List<Object?>).cast<num>();
          final pointer = _Pointer(page);
          await pointer.down(
            Point(at[0].toDouble(), at[1].toDouble()),
            atMs: 0,
          );
          for (var i = 1; i <= 8; i++) {
            await pointer.move(
              Point(at[0].toDouble() + i * 20, at[1].toDouble()),
              atMs: i * 100,
            );
          }
          await pointer.up(atMs: 900);

          await settled('t', 0);
          expect(await log(), isEmpty, reason: 'no press, no click');
        });

        test('a click on an action presses it and is not the row’s', () async {
          await mount([
            {'id': 't', 'trailing': 2},
          ]);
          await openByDrag('t', trailing: true, restsAt: -132);
          await page.evaluate<void>('() => couiSwipeClear()');

          final center = await page.evaluate<String>(
            '''
() => {
              const r = document.querySelector('#row-t button[aria-label="Archive"]')
                .getBoundingClientRect();
              return JSON.stringify([r.left + r.width / 2, r.top + r.height / 2]);
            }''',
          );
          final at = (jsonDecode(center) as List<Object?>).cast<num>();
          await _Pointer(page).tap(Point(at[0].toDouble(), at[1].toDouble()));

          await settled('t', 0);
          // The action ran; the caller's own onClick (the row's) did not.
          expect(await log(), ['t:Archive']);
        });

        test(
          'a fling closes an open row although the pull back is short',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            await openByDrag('t', trailing: true, restsAt: -132);

            // 40 px in 48 ms: 830 px/s, a flick.
            final pointer = _Pointer(page);
            await pointer.down(pageOf(150, 36), atMs: 0);
            for (var i = 1; i <= 4; i++) {
              await pointer.move(pageOf(150 + i * 15, 36), atMs: i * 16);
            }
            await pointer.up(atMs: 70);

            final rest = await settled('t', 0);
            expect(rest.state, 'closed');
          },
        );

        test('a row that is not enabled cannot be dragged', () async {
          await mount([
            {'id': 't', 'trailing': 2, 'enabled': false},
          ]);
          final pointer = _Pointer(page);
          await pointer.down(pageOf(300, 36), atMs: 0);
          for (var i = 1; i <= 5; i++) {
            await pointer.move(pageOf(300 - i * 40, 36), atMs: i * 100);
          }
          await pointer.up(atMs: 700);
          await frames(2);

          final rest = await geo('t');
          expect(rest.offset, 0);
          expect(rest.state, 'closed');
          expect(
            await page.evaluate<int>(
              '() => document.querySelectorAll("#row-t button").length',
            ),
            0,
            reason: 'a disabled row exposes no action',
          );
        });
      });

      group('a press that is not the main button', () {
        test('does not swipe, whichever other button it is', () async {
          await mount([
            {'id': 't', 'trailing': 2, 'button': true},
          ]);
          // What the page is told of each press: the browser calls the mouse
          // primary whatever button it presses with, so only the button
          // itself says it is not the main one. A secondary press asks for a
          // menu; nothing here answers it.
          await page.evaluate<void>('''
() => {
            window.__presses = [];
            document.addEventListener('pointerdown', (e) => {
              window.__presses.push(
                { kind: e.pointerType, button: e.button, primary: e.isPrimary, id: e.pointerId });
            }, true);
            document.addEventListener('contextmenu', (e) => e.preventDefault());
          }''');
          Future<List<Object?>> presses() async {
            final json = await page.evaluate<String>(
              '''
() => JSON.stringify(
        window.__presses.map(({ id, ...rest }) => rest))''',
            );

            return jsonDecode(json) as List<Object?>;
          }

          Future<bool> holdsPointer() => page.evaluate<bool>(
            '''
() => document.getElementById('row-t')
                .hasPointerCapture(window.__presses.at(-1).id)''',
          );

          // Pulled toward the side that has actions, far enough for a row
          // that took the press to be open.
          for (final button in [MouseButton.right, MouseButton.middle]) {
            final pointer = _Pointer(page, button: button);
            await pointer.down(pageOf(300, 36), atMs: 0);
            for (var i = 1; i <= 4; i++) {
              await pointer.move(pageOf(300 - i * 30, 36), atMs: i * 100);
            }
            await frames(1);

            final mid = await geo('t');
            expect(mid.state, 'closed', reason: '$button: not dragging');
            expect(mid.offset, 0, reason: '$button: the row did not follow');
            expect(
              await holdsPointer(),
              isFalse,
              reason: '$button: no capture',
            );

            await pointer.up(atMs: 500);
            await frames(2);
            final rest = await geo('t');
            expect(rest.state, 'closed', reason: '$button: still closed');
            expect(rest.offset, 0);
          }
          expect(await presses(), [
            {'kind': 'mouse', 'button': 2, 'primary': true},
            {'kind': 'mouse', 'button': 1, 'primary': true},
          ], reason: 'the presses were the secondary and the middle button');
          expect(await log(), isEmpty, reason: 'nothing ran');

          // And the main button is as it was: a click reaches the content
          // and the caller.
          await _Pointer(page).tap(pageOf(250, 36));
          await frames(2);
          expect(await log(), ['t:content', 't:root-click']);
        });
      });

      group('the full swipe', () {
        test('a disabled first action is never run by a long pull', () async {
          await mount([
            {'id': 't', 'trailing': 2, 'firstDisabled': true},
          ]);

          // The table's full-swipe stroke: 270 px, far past the threshold.
          final pointer = _Pointer(page);
          await pointer.down(pageOf(380, 36), atMs: 0);
          const xs = [350.0, 250.0, 150.0, 80.0];
          for (var i = 0; i < xs.length; i++) {
            await pointer.move(pageOf(xs[i], 36), atMs: (i + 1) * 100);
          }
          await pointer.up(atMs: 500);

          final rest = await settled('t', -132);
          expect(rest.state, 'open', reason: 'the pull opens instead');
          expect(await log(), isEmpty, reason: 'and nothing ran');
        });
      });

      group('touch', () {
        setUp(() async {
          await page.devTools.emulation.setTouchEmulationEnabled(
            true,
            maxTouchPoints: 1,
          );
        });

        test(
          'a touch drag opens the row; a tap on it only closes it',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);

            final finger = _Finger(page);
            await finger.down(pageOf(300, 36), atMs: 0);
            for (var i = 1; i <= 8; i++) {
              await finger.move(pageOf(300 - i * 25, 36), atMs: i * 100);
            }
            await finger.up(atMs: 900);
            final open = await settled('t', -132);
            expect(open.state, 'open');
            expect(await log(), isEmpty, reason: 'a drag is not a click');

            // A tap on the shifted row: the browser sends it a click, which the
            // overlay takes — the row closes and its content hears nothing.
            await finger.down(pageOf(150, 36), atMs: 1000);
            await finger.up(atMs: 1060);
            await settled('t', 0);
            expect(await log(), isEmpty);
          },
        );

        test(
          'a touch the system takes away puts the row back and runs nothing',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);

            final finger = _Finger(page);
            await finger.down(pageOf(300, 36), atMs: 0);
            for (var i = 1; i <= 3; i++) {
              await finger.move(pageOf(300 - i * 30, 36), atMs: i * 100);
            }
            await frames(1);
            final mid = await geo('t');
            expect(mid.state, 'dragging');
            expect(mid.offset, closeTo(-60, 0.6));

            await finger.cancel(atMs: 400);
            final rest = await settled('t', 0);
            expect(rest.state, 'closed');
            expect(await log(), isEmpty);
          },
        );

        test(
          'a key still clicks after a touch drag: no click came to take it',
          () async {
            await mount([
              {'id': 't', 'trailing': 2, 'button': true},
            ]);

            // A slow short pull that comes back closed. The lift decides a
            // release, so the row expects the click a mouse would send after
            // it; a touch lift sends none.
            final finger = _Finger(page);
            await finger.down(pageOf(300, 36), atMs: 0);
            const xs = [270.0, 250.0, 240.0];
            for (var i = 0; i < xs.length; i++) {
              await finger.move(pageOf(xs[i], 36), atMs: (i + 1) * 100);
            }
            await finger.up(atMs: 400);
            await settled('t', 0);
            expect(await log(), isEmpty, reason: 'a drag is not a click');

            // Enter on a focused button is a click that no pointer started.
            // It is the next click the row hears, and it is an ordinary one.
            await focusElement('button-t');
            await page.keyboard.press(pptr.Key.enter);
            await frames(2);
            expect(await log(), ['t:content', 't:root-click']);
          },
        );

        test(
          'a touch pulled past the threshold and then cancelled runs nothing',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);

            final finger = _Finger(page);
            await finger.down(pageOf(380, 36), atMs: 0);
            const xs = [350.0, 250.0, 150.0, 80.0];
            for (var i = 0; i < xs.length; i++) {
              await finger.move(pageOf(xs[i], 36), atMs: (i + 1) * 100);
            }
            await frames(1);
            expect((await geo('t')).offset, closeTo(-270, 0.6));

            await finger.cancel(atMs: 500);
            await settled('t', 0);
            expect(await log(), isEmpty, reason: 'a cancel is not a release');
          },
        );
      });

      group('content that wants the pointer for itself', () {
        test(
          'a drag that starts on a link swipes instead of dragging the link',
          () async {
            await mount([
              {'id': 't', 'trailing': 2, 'link': true},
            ]);
            final where = await page.evaluate<String>(
              '''
() => {
              const r = document.getElementById('link-t').getBoundingClientRect();
              return JSON.stringify([r.left + r.width / 2, r.top + r.height / 2]);
            }''',
            );
            final at = (jsonDecode(where) as List<Object?>).cast<num>();

            final pointer = _Pointer(page);
            await pointer.down(
              Point(at[0].toDouble(), at[1].toDouble()),
              atMs: 0,
            );
            for (var i = 1; i <= 8; i++) {
              await pointer.move(
                Point(at[0].toDouble() - i * 25, at[1].toDouble()),
                atMs: i * 100,
              );
            }
            await pointer.up(atMs: 900);

            final open = await settled('t', -132);
            expect(open.state, 'open');
            expect(
              await page.evaluate<String>('() => location.hash'),
              isEmpty,
              reason: 'the link was not followed',
            );
          },
        );
        test(
          'a press in a text field selects text, it does not swipe',
          () async {
            // Pulled toward the side that has actions: a row that took this
            // press would open.
            await mount([
              {'id': 't', 'trailing': 2, 'input': true},
            ]);
            final where = await page.evaluate<String>(
              '''
() => {
              const r = document.getElementById('input-t').getBoundingClientRect();
              return JSON.stringify([r.right - 20, r.top + r.height / 2]);
            }''',
            );
            final at = (jsonDecode(where) as List<Object?>).cast<num>();

            final pointer = _Pointer(page);
            await pointer.down(
              Point(at[0].toDouble(), at[1].toDouble()),
              atMs: 0,
            );
            for (var i = 1; i <= 8; i++) {
              await pointer.move(
                Point(at[0].toDouble() - i * 12, at[1].toDouble()),
                atMs: i * 100,
              );
            }
            await pointer.up(atMs: 900);
            await frames(2);

            final rest = await geo('t');
            expect(rest.offset, 0);
            expect(rest.state, 'closed');
          },
        );
      });

      group('clicks', () {
        test(
          'a drag swallows its own click; a tap closes an open row',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            await openByDrag('t', trailing: true, restsAt: -132);
            expect(
              await log(),
              isEmpty,
              reason: 'the release click is swallowed',
            );

            // A tap on the shifted row: it closes, and reaches nothing.
            final pointer = _Pointer(page);
            await pointer.tap(pageOf(150, 36));
            await settled('t', 0);
            expect(await log(), isEmpty, reason: 'the tap closed the row');

            // The next tap is an ordinary click: the content and the caller
            // hear it, in bubbling order.
            await pointer.tap(pageOf(150, 36));
            await frames(2);
            expect(await log(), ['t:content', 't:root-click']);
          },
        );

        test(
          'the click that ends a drag stops at the row; the next goes on up',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            // What a container around the row listens with: a click that
            // bubbles up through it is written down, with where it landed.
            await page.evaluate<void>('''
() => {
              window.__heard = [];
              document.body.addEventListener('click', (e) => {
                window.__heard.push(e.target.closest('[id]').id);
              });
            }''');
            Future<List<String>> heard() async {
              final json = await page.evaluate<String>(
                '() => JSON.stringify(window.__heard)',
              );

              return (jsonDecode(json) as List<Object?>).cast<String>();
            }

            // A slow short pull with the mouse, which the row comes back
            // from: the browser sends the click of the release to the root,
            // the element that holds the pointer, and it is the drag's own.
            final pointer = _Pointer(page);
            await pointer.down(pageOf(300, 36), atMs: 0);
            await pointer.move(pageOf(270, 36), atMs: 100);
            await pointer.move(pageOf(250, 36), atMs: 200);
            await pointer.move(pageOf(240, 36), atMs: 300);
            await frames(1);
            expect((await geo('t')).state, 'dragging');
            await pointer.up(atMs: 400);
            await settled('t', 0);
            expect(await heard(), isEmpty, reason: 'the drag’s click stopped');
            expect(await log(), isEmpty);

            // The flag went with that click: the next one is an ordinary
            // click, and it goes all the way up.
            await pointer.tap(pageOf(200, 36));
            await frames(2);
            expect(await log(), ['t:content', 't:root-click']);
            expect(await heard(), ['content-t']);
          },
        );
      });

      group('the scope', () {
        test(
          'moving one row closes the open one; a free row is independent',
          () async {
            await mount([
              {'id': 'a', 'trailing': 2},
              {'id': 'b', 'trailing': 2},
              {'id': 'free', 'trailing': 2, 'scope': false},
            ]);

            await openByDrag('a', trailing: true, restsAt: -132);
            expect((await geo('a')).state, 'open');

            // Arming a drag on B closes A while B is still being pulled.
            final pointer = _Pointer(page);
            await pointer.down(pageOf(300, 36, slot: 1), atMs: 0);
            await pointer.move(pageOf(270, 36, slot: 1), atMs: 100);
            await pointer.move(pageOf(240, 36, slot: 1), atMs: 200);
            final closing = await settled('a', 0);
            expect(closing.state, 'closed');
            expect((await geo('b')).state, 'dragging');
            await pointer.up(atMs: 1000);
            await settled('b', 0);

            // Open B, then a row outside the scope: B stays open.
            await openByDrag('b', trailing: true, restsAt: -132, slot: 1);
            await openByDrag('free', trailing: true, restsAt: -132, slot: 2);
            expect((await geo('b')).state, 'open');
            expect((await geo('free')).state, 'open');
            expect((await geo('a')).state, 'closed');
          },
        );
      });

      group('keyboard', () {
        test(
          'Tab opens a side; Escape closes it and keeps the place',
          () async {
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 2},
            ]);

            await page.keyboard.press(pptr.Key.tab);
            expect(await focused(), 'Pin');
            var rest = await settled('t', 72);
            expect(rest.state, 'open');
            expect(rest.side, 'leading');

            await page.keyboard.press(pptr.Key.tab);
            expect(await focused(), 'Delete');
            rest = await settled('t', -132);
            expect(rest.state, 'open');
            expect(rest.side, 'trailing');

            await page.keyboard.press(pptr.Key.escape);
            rest = await settled('t', 0);
            expect(rest.state, 'closed');
            expect(
              await focused(),
              'row-t',
              reason:
                  'focus goes to the row, not to a button clipped to nothing',
            );
          },
        );

        test(
          'Enter on an action runs it, closes the row and keeps the place',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);

            await page.keyboard.press(pptr.Key.tab);
            expect(await focused(), 'Delete');
            await settled('t', -132);
            await page.keyboard.press(pptr.Key.enter);

            final rest = await settled('t', 0);
            expect(rest.state, 'closed');
            expect(await log(), ['t:Delete']);
            expect(await focused(), 'row-t');
          },
        );

        test(
          'an action that moves focus on has moved it: the close takes none',
          () async {
            await mount([
              {'id': 'a', 'trailing': 2},
              {'id': 'b', 'input': true},
            ]);
            await tabTo('Delete');
            await settled('a', -132);

            // The handler of the action sends the user to a field, as an
            // action that opens an editor does.
            await page.evaluate<void>('''
() => {
              window.couiSwipePressed = () => {
                document.getElementById('input-b').focus();
              };
            }''');
            await page.keyboard.press(pptr.Key.enter);

            final rest = await settled('a', 0);
            expect(rest.state, 'closed');
            expect(await log(), ['a:Delete']);
            expect(
              await focused(),
              'input-b',
              reason: 'where the handler put it',
            );
          },
        );

        test(
          'Escape stops at the row only when it closed the row',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            // What a dialog around the row listens with: an ancestor of the
            // row, hearing what bubbles up through it. Every key the row lets
            // through is written down.
            await page.evaluate<void>('''
() => {
            window.__heard = [];
            document.body.addEventListener('keydown', (e) => {
              window.__heard.push(e.key);
            });
          }''');
            Future<List<String>> heard() async {
              final json = await page.evaluate<String>(
                '() => JSON.stringify(window.__heard)',
              );

              return (jsonDecode(json) as List<Object?>).cast<String>();
            }

            Future<void> forget() =>
                page.evaluate<void>('() => { window.__heard.length = 0; }');

            // The keys have to go through the row, so focus is on it: a key
            // pressed with focus anywhere else never meets the row's handler.
            await page.evaluate<void>(
              "() => document.getElementById('row-t').focus()",
            );
            expect(await focused(), 'row-t');
            await forget();

            // A closed row has nothing to close: Escape goes on up, and so
            // does every other key.
            await page.keyboard.press(pptr.Key.escape);
            expect(await heard(), ['Escape']);
            await page.keyboard.press(pptr.Key.keyA);
            expect(await heard(), ['Escape', 'a']);

            // An open row lets every other key through as well.
            await page.keyboard.press(pptr.Key.tab);
            expect(await focused(), 'Delete');
            await settled('t', -132);
            await forget();
            await page.keyboard.press(pptr.Key.keyA);
            expect(await heard(), ['a']);

            // And it takes Escape: it closes, and the dialog around it stays.
            await forget();
            await page.keyboard.press(pptr.Key.escape);
            final rest = await settled('t', 0);
            expect(rest.state, 'closed');
            expect(await heard(), isEmpty);
            expect(await focused(), 'row-t');

            // Closed again, the next Escape is not the row's.
            await page.keyboard.press(pptr.Key.escape);
            expect(await heard(), ['Escape']);
          },
        );
      });

      // A row can sit in the content of another. Its platters are its own, not
      // the row's around it, whatever bubbles up through that one: focus on
      // an action of the nested row opens the nested row, and a row the
      // scope lets go of because of it has no claim on the focus.
      group('a row nested in the content of another', () {
        const nested = [
          {
            'id': 't',
            'leading': 2,
            'trailing': 2,
            'nested': {'leading': 2, 'trailing': 2},
          },
        ];

        test(
          'focus on its action opens the nested row and not the one around',
          () async {
            await mount(nested);
            expect((await geo('t')).state, 'closed');
            expect((await geo('t-inner')).state, 'closed');

            await focusAction('t-inner', 'Reply');
            var inner = await settled('t-inner', 132);
            expect(inner.state, 'open');
            expect(inner.side, 'leading');
            var outer = await geo('t');
            expect(outer.state, 'closed', reason: 'the row around is not open');
            expect(outer.side, isNull);
            expect(outer.offset, 0);
            expect(outer.leadingPlatter, 0);
            expect(outer.trailingPlatter, 0);

            // The other side of the nested row. A row around that had taken
            // the scope for itself would have let the nested one go by now.
            await focusAction('t-inner', 'Hide');
            inner = await settled('t-inner', -132);
            expect(inner.state, 'open');
            expect(inner.side, 'trailing');
            outer = await geo('t');
            expect(outer.state, 'closed');
            expect(outer.offset, 0);
            expect(await log(), isEmpty, reason: 'nothing was pressed');
          },
        );

        test(
          'the row the nested one closes keeps its hands off the focus',
          () async {
            await mount(nested);

            // Pin and Mute are the outer row's own: its side opens under them.
            await tabTo('Mute');
            var outer = await settled('t', 132);
            expect(outer.state, 'open');
            expect(outer.side, 'leading');

            // The next stop is the nested row's first action. Its row opens,
            // which takes the scope and so closes the row around it — with
            // focus on an action that is not that row's.
            await page.keyboard.press(pptr.Key.tab);
            expect(await focused(), 'Reply');
            final inner = await settled('t-inner', 132);
            expect(inner.state, 'open');
            expect(inner.side, 'leading');
            outer = await settled('t', 0);
            expect(outer.state, 'closed', reason: 'the scope let it go');
            expect(
              await focused(),
              'Reply',
              reason: 'focus stays on the action of the nested row',
            );
          },
        );

        // On Flutter an action is a button that wins the press: the `onTap` of
        // a row around it never fires. The Web row answers the same for the
        // caller's `onClick` — the nested row's action must not reach the
        // caller of the row around it, by pointer or by `Enter`. The content
        // of the row around still hears the click, as it hears any button in
        // the content: stopping the event would hide it from every ancestor
        // too, and a page's own listeners (a click outside that dismisses an
        // overlay) have a claim on it.
        test('a click on its action is not the row’s around it', () async {
          await mount(nested);
          await focusAction('t-inner', 'Reply');
          await settled('t-inner', 132);
          await page.evaluate<void>('() => couiSwipeClear()');

          final center = await page.evaluate<String>(
            '''
() => {
              const r = document.querySelector('#row-t-inner button[aria-label="Reply"]')
                .getBoundingClientRect();
              return JSON.stringify([r.left + r.width / 2, r.top + r.height / 2]);
            }''',
          );
          final at = (jsonDecode(center) as List<Object?>).cast<num>();
          await _Pointer(page).tap(Point(at[0].toDouble(), at[1].toDouble()));

          await settled('t-inner', 0);
          expect(
            await log(),
            ['t:inner:Reply', 't:content'],
            reason:
                'the nested action ran and the content around heard the '
                'click, but the onClick of the row around did not',
          );
        });

        test('Enter on its action is not the row’s around it', () async {
          await mount(nested);
          await focusAction('t-inner', 'Reply');
          await settled('t-inner', 132);
          await page.evaluate<void>('() => couiSwipeClear()');

          await page.keyboard.press(pptr.Key.enter);

          await settled('t-inner', 0);
          expect(
            await log(),
            ['t:inner:Reply', 't:content'],
            reason:
                'the nested action ran and the content around heard the '
                'click, but the onClick of the row around did not',
          );
        });
      });

      // A rebuild that changes how many actions a side has, or that stops the
      // row being swipeable, closes the row or takes its platters out of the
      // document. A keyboard user on one of those actions keeps their place on
      // the row — and a user anywhere else is not moved. Each case is the real
      // focus of a real page, after a real rebuild: `couiSwipeMount` hands the
      // same rows to the entry again with other counts. The move itself waits
      // until the rebuild is over, so the cases read the page after it.
      group('a rebuild under a focused action', () {
        test(
          'a different number of leading actions leaves focus on the row',
          () async {
            await mount([
              {'id': 't', 'leading': 2, 'trailing': 1},
            ]);

            // On an action the rebuild removes.
            await tabTo('Mute');
            await settled('t', extent(2));
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 1},
            ]);
            expect(await focused(), 'row-t', reason: 'the action is gone');
            expect((await settled('t', 0)).state, 'closed');

            // On an action the rebuild keeps: it is clipped to nothing now.
            await tabTo('Pin');
            await settled('t', extent(1));
            await mount([
              {'id': 't', 'leading': 2, 'trailing': 1},
            ]);
            expect(await focused(), 'row-t', reason: 'the action is clipped');
            expect((await settled('t', 0)).state, 'closed');
          },
        );

        test(
          'a different number of trailing actions leaves focus on the row',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);

            // The DOM lists the trailing side backwards: Delete, Archive.
            await tabTo('Delete');
            await settled('t', -extent(2));
            await mount([
              {'id': 't', 'trailing': 1},
            ]);
            expect(await focused(), 'row-t', reason: 'the action is gone');
            expect((await settled('t', 0)).state, 'closed');

            await tabTo('Archive');
            await settled('t', -extent(1));
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            expect(await focused(), 'row-t', reason: 'the action is clipped');
            expect((await settled('t', 0)).state, 'closed');
          },
        );

        test(
          'a row disabled under a focused action keeps the focus on itself',
          () async {
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 2},
            ]);
            await tabTo('Delete');
            await settled('t', -extent(2));

            await mount([
              {'id': 't', 'leading': 1, 'trailing': 2, 'enabled': false},
            ]);
            expect(await focused(), 'row-t');
            final rest = await settled('t', 0);
            expect(rest.state, 'closed');
            expect(rest.leadingPlatter, isNull, reason: 'no platter at all');
            expect(rest.trailingPlatter, isNull);

            // And enabled again, it is still where the user is.
            await mount([
              {'id': 't', 'leading': 1, 'trailing': 2},
            ]);
            expect(await focused(), 'row-t');
          },
        );

        test(
          'a row left with nothing to swipe keeps the focus on itself',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            await tabTo('Delete');

            await mount([
              {'id': 't'},
            ]);
            expect(await focused(), 'row-t');
            expect((await geo('t')).trailingPlatter, isNull);
          },
        );

        test(
          'a row that already holds focus keeps it when it is disabled',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            await focusElement('row-t');
            expect(await focused(), 'row-t');

            await mount([
              {'id': 't', 'trailing': 2, 'enabled': false},
            ]);
            expect(await focused(), 'row-t', reason: 'disabled');
            await mount([
              {'id': 't'},
            ]);
            expect(await focused(), 'row-t', reason: 'no actions at all');
          },
        );

        test('the row a rebuild renames keeps the focus', () async {
          await mount([
            {'id': 't', 'trailing': 2},
          ]);
          await tabTo('Delete');

          // The rebuild gives the row another id and fewer actions at once:
          // the user is found by the id the row had, the row by the id it has.
          await mount([
            {'id': 'u', 'trailing': 1},
          ]);
          expect(await focused(), 'row-u');
        });

        test(
          'focus does not move until the rebuild has changed the row',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            await tabTo('Delete');
            await settled('t', -extent(2));

            // What the page sees while the rebuild runs, in order: every change
            // inside the row, and every focus event. A change the observer has
            // not delivered yet is still a change, so each focus event counts
            // what is queued as well.
            await page.evaluate<void>('''
() => {
            const root = document.getElementById('row-t');
            window.__order = { changes: 0, focusins: [] };
            const observer = new MutationObserver((records) => {
              window.__order.changes += records.length;
            });
            observer.observe(root, {
              subtree: true,
              childList: true,
              attributes: true,
              characterData: true,
            });
            document.addEventListener('focusin', (event) => {
              window.__order.changes += observer.takeRecords().length;
              window.__order.focusins.push({
                target: event.target.id || event.target.tagName,
                changesBefore: window.__order.changes,
              });
            }, true);
          }''');

            // The timer is the page's first task after the rebuild's: what has
            // focus when it runs says whether the hand-off waited for a task or
            // only for the end of the pass.
            await page.evaluate<void>('''
() => {
              couiSwipeMount(JSON.stringify([{id: 't', trailing: 1}]));
              setTimeout(() => {
                const active = document.activeElement;
                window.__atTimer = active ? (active.id || active.tagName) : null;
              }, 0);
            }''');
            await frames(3);

            expect(
              await page.evaluate<String>('() => window.__atTimer'),
              'row-t',
              reason: 'focus has moved by the next task',
            );
            final json = await page.evaluate<String>(
              '() => JSON.stringify(window.__order)',
            );
            final order = jsonDecode(json) as Map<String, Object?>;
            final focusins = (order['focusins']! as List<Object?>)
                .cast<Map<String, Object?>>();
            expect(focusins, isNotEmpty, reason: 'focus moved');
            expect(focusins.first['target'], 'row-t');
            expect(
              focusins.first['changesBefore'],
              greaterThan(0),
              reason:
                  "a focus event inside the rebuild runs the page's handlers "
                  'before the rebuild is done',
            );
            expect(await focused(), 'row-t');
          },
        );

        test(
          'focus the same rebuild gave to another element stays there',
          () async {
            await mount([
              {'id': 'a', 'trailing': 2},
              {'id': 'b', 'input': true},
            ]);
            await tabTo('Delete');
            await settled('a', -extent(2));

            // A host that moves focus itself, as part of the update that
            // rebuilds the row: after the row has been updated, before the
            // update is over.
            await duringUpdate("document.getElementById('input-b').focus();");
            await mount([
              {'id': 'a', 'trailing': 1},
              {'id': 'b', 'input': true},
            ]);
            expect(await focused(), 'input-b', reason: 'the host moved it');
            expect((await settled('a', 0)).state, 'closed');
          },
        );

        test('focus the same rebuild gave to the page is taken back', () async {
          await mount([
            {'id': 't', 'trailing': 2},
          ]);
          await tabTo('Delete');
          await settled('t', -extent(2));

          // The host leaves focus on the document element, which is not an
          // element a user can be working in.
          await duringUpdate('''
const html = document.documentElement;
html.tabIndex = -1;
html.focus();
window.__during = document.activeElement.tagName;
''');
          await mount([
            {'id': 't', 'trailing': 1},
          ]);
          expect(
            await page.evaluate<String>('() => window.__during'),
            'HTML',
            reason: 'the host really left focus on the document element',
          );
          expect(await focused(), 'row-t');
        });

        test('focus anywhere else is left where it is', () async {
          // In a text field of another row.
          await mount([
            {'id': 'a', 'trailing': 2},
            {'id': 'b', 'input': true},
          ]);
          await focusElement('input-b');
          await mount([
            {'id': 'a', 'trailing': 1},
            {'id': 'b', 'input': true},
          ]);
          expect(await focused(), 'input-b', reason: "another row's field");

          // In a text field of the row itself, outside its platters.
          await mount([
            {'id': 'a', 'trailing': 2, 'input': true},
          ]);
          await focusElement('input-a');
          await mount([
            {'id': 'a', 'trailing': 1, 'input': true},
          ]);
          expect(await focused(), 'input-a', reason: "the row's own content");

          // On an action of another row.
          await mount([
            {'id': 'a', 'trailing': 2},
            {'id': 'b', 'trailing': 2},
          ]);
          await page.evaluate<void>(
            '''
() => document.querySelector('#row-b button[aria-label="Delete"]').focus()''',
          );
          expect(await focused(), 'Delete');
          await mount([
            {'id': 'a', 'trailing': 1},
            {'id': 'b', 'trailing': 2},
          ]);
          expect(await focused(), 'Delete', reason: "another row's action");
          expect((await geo('b')).state, 'open', reason: 'and that row stays');

          // Nowhere at all: the rebuild does not give the page a focus.
          await mount([
            {'id': 'a', 'trailing': 2},
          ]);
          await page.evaluate<void>('() => document.activeElement.blur()');
          expect(await focused(), 'BODY');
          await mount([
            {'id': 'a', 'trailing': 1},
          ]);
          expect(await focused(), 'BODY', reason: 'no focus to keep');
        });

        test('a field the rebuild removes sends focus nowhere', () async {
          await mount([
            {'id': 'a', 'trailing': 2, 'input': true},
          ]);
          await focusElement('input-a');

          // The user was in the row's content, not on an action. The rebuild
          // takes the field away along with an action: that is the host's
          // doing, and the row is not where the user was.
          await mount([
            {'id': 'a', 'trailing': 1},
          ]);
          expect(await focused(), 'BODY');
        });

        test(
          'a row the rebuild replaces hands focus to nothing',
          () async {
            await mount([
              {'id': 't', 'trailing': 2, 'remount': 1},
            ]);
            await tabTo('Delete');
            await settled('t', -extent(2));

            // One task: the rebuild is told to replace the row by a new one
            // with the same id, and a tap on the old row's cover closes it —
            // so the old row has a hand-off waiting for the microtask after
            // the rebuild's, by which time it is gone.
            await page.evaluate<void>('''
() => {
              couiSwipeMount(JSON.stringify([{id: 't', trailing: 2, remount: 2}]));
              document.querySelector('#row-t [data-swipe-tap-catcher]').click();
            }''');
            await frames(3);

            expect(
              await page.evaluate<bool>(
                '''
() => document.getElementById('row-t').dataset.swipeState === 'closed' ''',
              ),
              isTrue,
              reason: 'the new row is a row of its own',
            );
            expect(await focused(), 'BODY', reason: 'the old action is gone');
          },
        );

        test(
          'a rebuild that changes neither the actions nor whether the row can '
          'be swiped does not touch focus',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            await tabTo('Delete');
            await settled('t', -extent(2));

            // The same rows again: new instances all the way down.
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            expect(await focused(), 'Delete', reason: 'the same rows');

            // Another property of the row.
            await mount([
              {'id': 't', 'trailing': 2, 'fullSwipe': false},
            ]);
            expect(await focused(), 'Delete', reason: 'another property');
            expect(
              (await geo('t')).state,
              'open',
              reason: 'the row stays open',
            );
          },
        );
      });

      // A row comes to rest closed — a pan or a flick that lets go of it, a
      // tap on the content that covers it, another row of its scope opening —
      // while a keyboard user is on one of its actions. The action is clipped
      // to nothing by then, so focus goes to the row. These are touch because
      // a finger does not move focus the way a mouse does: a mouse press on
      // the row would put focus on the row by itself and leave the hand-off
      // nothing to show.
      group('a row that comes to rest closed under a focused action', () {
        setUp(() async {
          await page.devTools.emulation.setTouchEmulationEnabled(
            true,
            maxTouchPoints: 1,
          );
        });

        const openPull = 'a slow pull past half the trailing platter opens it';
        const pullBack = 'a slow pull back past half closes an open row';
        const flickBack = 'a quick flick back closes an open row';
        const smallPullBack = 'a slow small pull back leaves an open row open';

        /// A finger plays the shared table's row [name] on the row in [slot].
        /// [shift] moves the stroke along the row: the table's strokes on an
        /// open row start over its content, which an open row has slid away
        /// from them. [scrollY] is how far the page is scrolled.
        Future<void> stroke(
          String name, {
          int slot = 0,
          double shift = 0,
          double scrollY = 0,
        }) async {
          final vector = gestures.firstWhere((g) => g['name'] == name);
          final events = (vector['events']! as List<Object?>)
              .cast<Map<String, Object?>>();
          final finger = _Finger(page);
          Point<double> at(Map<String, Object?> event) {
            final point = pageOf(
              (event['x']! as num).toDouble() + shift,
              (event['y']! as num).toDouble(),
              slot: slot,
            );

            return Point(point.x, point.y - scrollY);
          }

          for (final event in events) {
            final atMs = (event['at']! as num).toInt();
            switch (event['kind']! as String) {
              case 'down':
                await finger.down(at(event), atMs: atMs);
              case 'move':
                await finger.move(at(event), atMs: atMs);
              case 'up':
                await finger.up(atMs: atMs);
            }
          }
        }

        /// Opens the trailing side of the row the keyboard reaches first, the
        /// way a keyboard user does: Tab to its Delete.
        Future<void> openByKeyboard(String id) async {
          await tabTo('Delete');
          await settled(id, -extent(2));
          expect(await focused(), 'Delete');
        }

        test('a pan that lets the row go closed leaves focus on it', () async {
          await mount([
            {'id': 't', 'trailing': 2},
          ]);
          await openByKeyboard('t');

          await stroke(pullBack, shift: -50);

          final rest = await settled('t', 0);
          expect(rest.state, 'closed');
          expect(
            await focused(),
            'row-t',
            reason: 'the action it was on is clipped to nothing',
          );
        });

        test('a flick away that closes the row leaves focus on it', () async {
          await mount([
            {'id': 't', 'trailing': 2},
          ]);
          await openByKeyboard('t');

          await stroke(flickBack, shift: -50);

          final rest = await settled('t', 0);
          expect(rest.state, 'closed');
          expect(await focused(), 'row-t');
        });

        test('another row of the scope opening closes it and leaves focus on '
            'it', () async {
          await mount([
            {'id': 'a', 'trailing': 2},
            {'id': 'b', 'trailing': 2},
          ]);
          await openByKeyboard('a');

          await stroke(openPull, slot: 1);

          expect((await settled('a', 0)).state, 'closed');
          expect(await focused(), 'row-a');
          expect((await settled('b', -extent(2))).state, 'open');
          expect(await focused(), 'row-a', reason: 'the other row took none');
        });

        test(
          'a tap on the content that covers an open row leaves focus on it',
          () async {
            await mount([
              {'id': 't', 'trailing': 2},
            ]);
            await openByKeyboard('t');

            // A click that script sends: a real tap puts focus on the row by
            // itself, before the click, and shows nothing.
            await page.evaluate<void>(
              '''
() => document.querySelector('#row-t [data-swipe-tap-catcher]').click()''',
            );

            expect((await settled('t', 0)).state, 'closed');
            expect(await focused(), 'row-t');
          },
        );

        test('a pan that leaves the row open does not move focus', () async {
          await mount([
            {'id': 't', 'trailing': 2},
          ]);
          await openByKeyboard('t');

          await stroke(smallPullBack, shift: -50);

          final rest = await settled('t', -extent(2));
          expect(rest.state, 'open');
          expect(await focused(), 'Delete');
        });

        test('focus that is not on an action is left where it is', () async {
          await mount([
            {'id': 'a', 'trailing': 2, 'input': true},
            {'id': 'b', 'input': true},
          ]);

          // Nowhere at all: the page has no focus to keep.
          await stroke(openPull);
          await settled('a', -extent(2));
          expect(await focused(), 'BODY');
          await stroke(pullBack, shift: -50);
          expect((await settled('a', 0)).state, 'closed');
          expect(await focused(), 'BODY', reason: 'no focus to keep');

          // In the row's own content.
          await focusElement('input-a');
          await stroke(openPull);
          await settled('a', -extent(2));
          await stroke(pullBack, shift: -50);
          expect((await settled('a', 0)).state, 'closed');
          expect(await focused(), 'input-a', reason: "the row's own field");

          // In another row.
          await focusElement('input-b');
          await stroke(openPull);
          await settled('a', -extent(2));
          await stroke(pullBack, shift: -50);
          expect((await settled('a', 0)).state, 'closed');
          expect(await focused(), 'input-b', reason: "another row's field");
        });

        test('focus does not scroll the page to a row out of view', () async {
          await mount([
            for (final id in 'abcdefgh'.split('')) {'id': id, 'trailing': 2},
          ]);
          await openByKeyboard('a');

          // Row a is above the page now; its action still has focus.
          await page.evaluate<void>('() => window.scrollTo(0, 250)');
          await frames(2);
          expect(await focused(), 'Delete');
          final scrolled = await page.evaluate<num>('() => window.scrollY');
          expect(scrolled, 250, reason: 'the page is scrolled away from row a');

          // Another row opens and closes row a under it.
          await stroke(openPull, slot: 4, scrollY: 250);

          expect((await settled('a', 0)).state, 'closed');
          expect(await focused(), 'row-a');
          expect(
            await page.evaluate<num>('() => window.scrollY'),
            250,
            reason: 'the page stays where the user has it',
          );
        });
      });

      group('motion', () {
        Future<String> settleDuration() => page.evaluate<String>(
          '''
() => getComputedStyle(
            document.querySelector('#row-t > [data-swipe-row]'),
          ).transitionDuration''',
        );

        test('the settle takes the token duration', () async {
          await mount([
            {'id': 't', 'trailing': 2},
          ]);
          await openByDrag('t', trailing: true, restsAt: -132);

          expect(await settleDuration(), '0.2s');
        });

        test(
          'reduced motion settles at once, through the same variable',
          () async {
            await page.emulateMediaFeatures([
              pptr.MediaFeature.prefersReducedMotion('reduce'),
            ]);
            await mount([
              {'id': 't', 'trailing': 2},
            ]);

            expect(await settleDuration(), '0s');
            final pointer = _Pointer(page);
            await pointer.down(pageOf(300, 36), atMs: 0);
            for (var i = 1; i <= 8; i++) {
              await pointer.move(pageOf(300 - i * 25, 36), atMs: i * 100);
            }
            await pointer.up(atMs: 900);
            await frames(2);

            final rest = await geo('t');
            expect(rest.state, 'open');
            expect(
              rest.offset,
              closeTo(-132, 0.5),
              reason: 'no frames spent getting there',
            );
          },
        );
      });
    },
    skip: chromePath == null
        ? 'no local Chrome — the Web SwipeActions cannot be driven here'
        : false,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
