// The Web drawer's rubber band, driven by real pointer input in Chrome: pulled
// past its dock the panel's far edge stretches with less and less return while
// the docked edge stays on the viewport edge, letting go brings it back on the
// browser's own transition, and none of it changes what dismisses — on every
// side.
//
// The VM cannot reach the Web drawer's drag path — it needs a real
// `PointerEvent`, real layout, a real pointer capture and a real CSS
// transition (see `packages/coui_web/test/components/overlay/
// drawer_rubber_band_test.dart`) — so the arithmetic the pointer handlers run,
// the transform they emit and the curve the browser walks back on can only be
// judged here. The numbers are Core's, pinned by
// `packages/coui_core/test/fixtures/drawer_rubber_band_vectors.json`; the
// Flutter drawer is held to the same table by its own test. This file puts the
// compiled shipped drawer through the same rows.
//
// ## How the pointer is driven, and why its clock is stamped
//
// The strokes go through the DevTools input domain: trusted events the
// browser routes through hit testing and pointer capture exactly as it does a
// real mouse. Each carries an explicit `timestamp`, which Chrome hands to the
// page as `PointerEvent.timeStamp`; a speed is a distance over a time, and the
// time the drawer reads is the event's own clock, so stamping it makes the
// stroke's speed the table's speed whatever the machine is doing. One event is
// sent per frame, so what the page sees is what was sent.
//
// ## How the return is read
//
// A CSS transition runs on the browser's clock, which a probe on a loaded
// machine cannot sample reliably. So the probe takes the transition off the
// clock: it finds the `CSSTransition` on the panel's `transform`, pauses it,
// and sets its `currentTime` to each instant of the table in turn. What the
// browser then lays out is the panel at exactly that instant of the curve it
// was handed — the number is the browser's, the instant is the table's.
//
// ## What each group guards
//
//   the table      the pose the stroke leaves (the far edge out by the
//                  table's stretch, the docked edge where it was) and what the
//                  lift does; fails if the arithmetic, the sign of the pull
//                  for an edge, or the scale about the docked edge is wrong.
//   the return     the panel at each sampled instant after the lift; fails if
//                  the duration or the curve is not Core's, or if the return
//                  is not a transition at all.
//   reduced motion the stretch still follows the pointer, the return is
//                  already over after a frame.
//   taking hold    a pointer that lands on a returning panel carries on from
//                  where the panel is, not from the dock.
//   cancel         the browser taking the pointer puts the panel back and
//                  dismisses nothing.
//   touch          a finger that scrolls the body scrolls it and stretches
//                  nothing; one on the header stretches the panel.
//   off            a drawer that did not ask for it stops dead.
//   right to left  a left or right drawer keeps its physical edge when the
//                  document reads right to left.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:coui_web/coui_web.dart' show CoreDrawerRubberBand, ThemeConfig;
import 'package:puppeteer/protocol/input.dart'
    show InputApi, MouseButton, TimeSinceEpoch, TouchPoint;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// The vector table shared with Core, the Flutter drawer and the Web VM test
/// (cwd is the repository root under `dart test tool/parity/test`).
const String _kVectorsPath =
    'packages/coui_core/test/fixtures/drawer_rubber_band_vectors.json';

const String _kEntryPath = 'tool/parity/src/web/drawer_rubber_band_entry.dart';

/// Tall and wide enough that a pull of the table's longest row, from a panel
/// docked on any side, stays inside the viewport.
const int _kViewportWidth = 1000;
const int _kViewportHeight = 1000;

/// A display's frame: how often a browser reports a moving pointer.
const Duration _kFrame = Duration(milliseconds: 16);

/// Longer than the drawer's 350 ms slide-out, with room for a busy machine,
/// so "gone" is settled when read.
const Duration _kAfterLift = Duration(milliseconds: 900);

/// A stroke longer than this runs on two sides only. The two together cover
/// both axes and both signs; the shorter strokes, which are cheap, run on all
/// four.
const int _kLongStrokeMs = 1000;

/// A painted edge against the table: it is rounded to four decimals and a
/// browser lays out in 1/64 px.
const double _kEdgeTolerance = 0.1;

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

/// The unit step of a position that moves toward the edge the panel hides
/// behind, per side.
const Map<String, Point<double>> _kTowardEdge = {
  'bottom': Point(0, 1),
  'top': Point(0, -1),
  'right': Point(1, 0),
  'left': Point(-1, 0),
};

typedef _Rect = ({double left, double top, double width, double height});
typedef _Pose = ({double slide, double stretch});

double _num(Object? value) => (value! as num).toDouble();

/// One pointer, with a clock of its own: every event it sends is stamped
/// `origin + clock`, and the clock moves exactly as far as the stroke says.
class _Pointer {
  _Pointer(this._page)
    : _input = _page.devTools.input,
      _origin = DateTime.now().millisecondsSinceEpoch / 1000;

  final pptr.Page _page;
  final InputApi _input;
  final double _origin;
  Duration _clock = Duration.zero;
  Point<double> _at = const Point(0, 0);

  TimeSinceEpoch get _stamp => TimeSinceEpoch(
    _origin + _clock.inMicroseconds / Duration.microsecondsPerSecond,
  );

  Future<void> _frame() => _page.evaluate<void>(
    '() => new Promise(resolve => requestAnimationFrame(() => resolve()))',
  );

  Future<void> down(Point<double> at) async {
    _at = at;
    await _input.dispatchMouseEvent(
      'mouseMoved',
      at.x,
      at.y,
      timestamp: _stamp,
    );
    await _input.dispatchMouseEvent(
      'mousePressed',
      at.x,
      at.y,
      button: MouseButton.left,
      buttons: 1,
      clickCount: 1,
      timestamp: _stamp,
    );
    await _frame();
  }

  Future<void> move(Point<double> to, {required Duration after}) async {
    _clock += after;
    _at = to;
    await _input.dispatchMouseEvent(
      'mouseMoved',
      to.x,
      to.y,
      button: MouseButton.left,
      buttons: 1,
      timestamp: _stamp,
    );
    await _frame();
  }

  /// Lifts where the pointer is, [after] later on the pointer's clock.
  Future<void> up({Duration after = Duration.zero}) async {
    _clock += after;
    await _input.dispatchMouseEvent(
      'mouseReleased',
      _at.x,
      _at.y,
      button: MouseButton.left,
      buttons: 0,
      clickCount: 1,
      timestamp: _stamp,
    );
  }

  /// Walks the pointer from [origin] along [toward] through [steps] (pulls
  /// from [origin]), a move every frame, in straight lines at one pace over
  /// [duration].
  Future<void> walk(
    Point<double> origin,
    Point<double> toward,
    List<double> steps,
    Duration duration,
  ) async {
    final segment = duration.inMicroseconds / steps.length;
    var from = 0.0;
    for (final to in steps) {
      final moves = math.max(1, (segment / _kFrame.inMicroseconds).ceil());
      final step = Duration(microseconds: (segment / moves).round());
      for (var i = 1; i <= moves; i++) {
        final pull = from + (to - from) * i / moves;
        await move(
          Point(origin.x + toward.x * pull, origin.y + toward.y * pull),
          after: step,
        );
      }
      from = to;
    }
  }
}

/// One finger, stamped on the same kind of clock as [_Pointer]: touch emulation
/// has to be on for the browser to treat these as touch (`pointerType: touch`,
/// `touch-action` honoured, the pointer held by the element it landed on).
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

  /// Carries the finger from [from] by [step] a frame, [frames] times.
  Future<void> drag(
    Point<double> from,
    Point<double> step,
    int frames, {
    int startMs = 0,
  }) async {
    await down(from, atMs: startMs);
    for (var i = 1; i <= frames; i++) {
      await move(
        Point(from.x + step.x * i, from.y + step.y * i),
        atMs: startMs + i * _kFrame.inMilliseconds,
      );
    }
    await up(atMs: startMs + (frames + 1) * _kFrame.inMilliseconds);
  }
}

void main() {
  final repoRoot = Directory.current.path;
  final chromePath = _systemChromePath();
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final constants = doc['constants']! as Map<String, Object?>;
  final gestures = doc['gestures']! as Map<String, Object?>;
  final extent = _num(gestures['extent']);
  final cases = (gestures['cases']! as List).cast<Map<String, Object?>>();

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

  /// The panel's rect and its computed `transform`, read together.
  Future<({_Rect rect, String transform})?> readPanel() async {
    final json = await page.evaluate<String?>('''
() => {
      const panel = document.querySelector('[role="dialog"]');
      if (!panel) return null;
      const r = panel.getBoundingClientRect();
      return JSON.stringify([
        r.left, r.top, r.width, r.height, getComputedStyle(panel).transform
      ]);
    }''');
    if (json == null) return null;
    final v = jsonDecode(json) as List;

    return (
      rect: (
        left: (v[0] as num).toDouble(),
        top: (v[1] as num).toDouble(),
        width: (v[2] as num).toDouble(),
        height: (v[3] as num).toDouble(),
      ),
      transform: v[4] as String,
    );
  }

  Future<_Rect?> panelRect() async => (await readPanel())?.rect;

  Future<int> dismissedCount() =>
      page.evaluate<int>('() => couiDrawerDismissed()');

  /// Waits for the panel to come to rest inside the viewport and returns the
  /// rect it rests at.
  Future<_Rect> settledPanelRect() async {
    _Rect? previous;
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final rect = await panelRect();
      final inside =
          rect != null &&
          rect.left >= -1 &&
          rect.top >= -1 &&
          rect.left + rect.width <= _kViewportWidth + 1 &&
          rect.top + rect.height <= _kViewportHeight + 1;
      if (inside && rect == previous) return rect;
      previous = rect;
    }
    fail('the panel never came to rest inside the viewport');
  }

  /// Opens a [side] drawer and returns the rect it rests at, docked.
  Future<_Rect> openDocked(
    String side, {
    bool rubberBand = true,
    bool sheet = false,
    bool scrolling = false,
  }) async {
    await page.evaluate<void>(
      '(spec) => couiRubberBandOpen(spec)',
      args: [
        jsonEncode({
          'side': side,
          'extent': extent,
          'rubberBand': rubberBand,
          'sheet': sheet,
          'scrolling': scrolling,
        }),
      ],
    );
    await page.waitForFunction(
      '() => document.querySelector(\'[role="dialog"]\') !== null',
    );
    final rect = await settledPanelRect();
    final along = side == 'bottom' || side == 'top' ? rect.height : rect.width;
    expect(
      along,
      closeTo(extent, 1),
      reason: 'the table is stated for a panel $extent px long on its axis',
    );
    expect(await dismissedCount(), 0);

    return rect;
  }

  /// Where the painted panel is against [docked]: how far the docked edge has
  /// moved toward the edge the panel hides behind (`slide`; a stretch must
  /// leave it at 0), and how far the far edge has moved out beyond what that
  /// slide explains (`stretch`).
  _Pose poseOf(String side, _Rect docked, _Rect now) {
    final right = now.left + now.width;
    final bottom = now.top + now.height;
    final dockedRight = docked.left + docked.width;
    final dockedBottom = docked.top + docked.height;
    final (dockShift, farOut) = switch (side) {
      'bottom' => (bottom - dockedBottom, docked.top - now.top),
      'top' => (docked.top - now.top, bottom - dockedBottom),
      'right' => (right - dockedRight, docked.left - now.left),
      _ => (docked.left - now.left, right - dockedRight),
    };

    return (slide: dockShift, stretch: farOut + dockShift);
  }

  /// Where a press on the panel lands: inside it, 24 px from the edge facing
  /// the middle of the screen, which leaves the room a long pull needs.
  Point<double> grab(String side, _Rect docked) => switch (side) {
    'bottom' => Point(docked.left + docked.width / 2, docked.top + 24),
    'top' => Point(
      docked.left + docked.width / 2,
      docked.top + docked.height - 24,
    ),
    'right' => Point(docked.left + 24, docked.top + docked.height / 2),
    _ => Point(docked.left + docked.width - 24, docked.top + docked.height / 2),
  };

  /// Pauses the panel's `transform` transition the moment it exists and
  /// returns whether there was one — the return after a lift is a CSS
  /// transition, and a probe that is not paused on it can only sample the
  /// browser's clock.
  Future<bool> pauseReturn() => page.evaluate<bool>('''
() => new Promise(resolve => {
      const panel = document.querySelector('[role="dialog"]');
      let tries = 0;
      const check = () => {
        const a = panel && panel.getAnimations().find(
          x => x instanceof CSSTransition && x.transitionProperty === 'transform'
        );
        if (a) { a.pause(); resolve(true); return; }
        if (++tries > 60) { resolve(false); return; }
        requestAnimationFrame(check);
      };
      check();
    })''');

  /// The paused return's own timing, as the browser holds it.
  Future<({num duration, num delay})> returnTiming() async {
    final json = await page.evaluate<String>('''
() => {
      const panel = document.querySelector('[role="dialog"]');
      const a = panel.getAnimations().find(
        x => x instanceof CSSTransition && x.transitionProperty === 'transform'
      );
      const t = a.effect.getTiming();
      return JSON.stringify([t.duration, t.delay]);
    }''');
    final v = jsonDecode(json) as List;

    return (duration: v[0] as num, delay: v[1] as num);
  }

  /// The panel [ms] into the paused return.
  Future<({_Rect rect, String transform})> returnAt(num ms) async {
    final json = await page.evaluate<String>(
      '''
(ms) => {
      const panel = document.querySelector('[role="dialog"]');
      const a = panel.getAnimations().find(
        x => x instanceof CSSTransition && x.transitionProperty === 'transform'
      );
      a.pause();
      a.currentTime = ms;
      const r = panel.getBoundingClientRect();
      return JSON.stringify([
        r.left, r.top, r.width, r.height, getComputedStyle(panel).transform
      ]);
    }''',
      args: [ms],
    );
    final v = jsonDecode(json) as List;

    return (
      rect: (
        left: (v[0] as num).toDouble(),
        top: (v[1] as num).toDouble(),
        width: (v[2] as num).toDouble(),
        height: (v[3] as num).toDouble(),
      ),
      transform: v[4] as String,
    );
  }

  /// Lets the paused return run out.
  Future<void> finishReturn() async {
    await page.evaluate<void>('''
() => {
      const panel = document.querySelector('[role="dialog"]');
      const a = panel.getAnimations().find(
        x => x instanceof CSSTransition && x.transitionProperty === 'transform'
      );
      if (a) a.finish();
    }''');
    await frames(3);
  }

  /// The scale a `matrix(...)` value puts the slide axis at.
  double scaleOnAxis(String side, String transform) {
    if (transform == 'none') return 1;
    final values = RegExp(r'matrix\((.*)\)').firstMatch(transform)!.group(1)!;
    final m = values.split(',').map((v) => double.parse(v.trim())).toList();

    return side == 'left' || side == 'right' ? m[0] : m[3];
  }

  /// Runs a stroke of a table row on [side] and returns the pointer still
  /// held, with the clock where the stroke ended.
  Future<_Pointer> stroke(
    String side,
    _Rect docked,
    List<double> steps,
    Duration duration,
  ) async {
    final toward = _kTowardEdge[side]!;
    final start = grab(side, docked);
    final pointer = _Pointer(page);
    await pointer.down(start);
    await pointer.walk(start, toward, steps, duration);
    await frames(2);

    return pointer;
  }

  group(
    'the Web drawer rubber band, with real pointer input in Chrome',
    () {
      setUpAll(() async {
        fixture = Directory.systemTemp.createTempSync('coui-drawer-band-');
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
        // return is part of what is being judged.
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
          '() => typeof couiRubberBandOpen === "function"',
        );
      });

      tearDown(() => page.close());

      tearDownAll(() async {
        await browser.close();
        fixture.deleteSync(recursive: true);
      });

      test('the table is for the numbers Core ships', () {
        expect(_num(constants['reach']), CoreDrawerRubberBand.defaultReach);
        expect(_num(constants['tension']), CoreDrawerRubberBand.defaultTension);
        expect(
          constants['settleMs'],
          CoreDrawerRubberBand.defaultSettleDuration.inMilliseconds,
        );
      });

      for (final side in _kTowardEdge.keys) {
        group('$side drawer', () {
          for (final c in cases) {
            final durationMs = (c['durationMs']! as num).toInt();
            if (durationMs > _kLongStrokeMs &&
                side != 'bottom' &&
                side != 'left') {
              continue;
            }
            test(c['name']! as String, () async {
              final docked = await openDocked(side);
              final steps = (c['steps']! as List).map(_num).toList();

              final pointer = await stroke(
                side,
                docked,
                steps,
                Duration(milliseconds: durationMs),
              );

              // The pose the stroke leaves: the table's, with the docked
              // edge unmoved whenever the panel is stretched.
              final want = c['pose']! as Map<String, Object?>;
              final during = (await readPanel())!;
              final pose = poseOf(side, docked, during.rect);
              expect(
                pose.slide,
                closeTo(_num(want['slide']), _kEdgeTolerance),
                reason: 'the docked edge moved',
              );
              expect(
                pose.stretch,
                closeTo(_num(want['stretch']), _kEdgeTolerance),
                reason: 'the far edge is not where the table puts it',
              );
              if (_num(want['stretch']) > 0) {
                expect(
                  scaleOnAxis(side, during.transform),
                  closeTo(1 + _num(want['stretch']) / extent, 1e-4),
                  reason: 'a stretch is a scale about the docked edge',
                );
              }

              await pointer.up(
                after: Duration(
                  milliseconds: ((c['holdMs'] as num?) ?? 0).toInt(),
                ),
              );

              if (c['dismisses']! as bool) {
                await Future<void>.delayed(_kAfterLift);
                await frames(2);
                expect(await panelRect(), isNull);
                expect(await dismissedCount(), 1);

                return;
              }

              // Kept: it comes back on a transition, sampled at the table's
              // instants.
              expect(
                await pauseReturn(),
                isTrue,
                reason: 'the return to the dock is a CSS transition',
              );
              for (final row in (c['settle']! as List).cast<List<Object?>>()) {
                final at = (row[0]! as num).toInt();
                final sampled = await returnAt(at);
                final left = poseOf(side, docked, sampled.rect);
                expect(
                  math.max(left.slide, left.stretch),
                  closeTo(_num(row[1]), _kEdgeTolerance),
                  reason: '$at ms into the return',
                );
              }
              await finishReturn();
              expect(await panelRect(), docked);
              expect(await dismissedCount(), 0);
            });
          }
        });
      }

      group('the return', () {
        for (final side in _kTowardEdge.keys) {
          test('$side: is the duration and the curve Core states', () async {
            final docked = await openDocked(side);
            final pointer = await stroke(side, docked, [
              -60,
            ], const Duration(milliseconds: 300));
            await pointer.up();
            expect(await pauseReturn(), isTrue);

            final timing = await returnTiming();
            expect(
              timing.duration,
              CoreDrawerRubberBand.defaultSettleDuration.inMilliseconds,
            );
            expect(timing.delay, 0);
            await finishReturn();
          });
        }

        test(
          'a stretched panel keeps the docked edge for the whole way back',
          () async {
            const side = 'bottom';
            final docked = await openDocked(side);
            final pointer = await stroke(side, docked, [
              -150,
            ], const Duration(milliseconds: 500));
            await pointer.up();
            expect(await pauseReturn(), isTrue);

            for (var ms = 0; ms <= 300; ms += 30) {
              final sampled = await returnAt(ms);
              final pose = poseOf(side, docked, sampled.rect);
              expect(pose.slide, closeTo(0, 0.01), reason: '$ms ms');
              expect(
                sampled.rect.width,
                closeTo(docked.width, 0.01),
                reason: '$ms ms: the panel is not widened',
              );
            }
            await finishReturn();
          },
        );
      });

      group('reduced motion', () {
        for (final side in _kTowardEdge.keys) {
          test('$side: the stretch follows the pointer, the return is '
              'instant', () async {
            await page.emulateMediaFeatures([
              pptr.MediaFeature.prefersReducedMotion('reduce'),
            ]);
            final docked = await openDocked(side);
            final pointer = await stroke(side, docked, [
              -20,
              -40,
              -60,
            ], const Duration(milliseconds: 600));

            final pose = poseOf(side, docked, (await panelRect())!);
            expect(pose.slide, closeTo(0, 0.01));
            expect(
              pose.stretch,
              closeTo(15.7143, _kEdgeTolerance),
              reason: 'direct manipulation is not decoration',
            );

            await pointer.up();
            await frames(3);
            expect(
              await panelRect(),
              docked,
              reason: 'the transition tier collapses',
            );
            expect(
              await pauseReturn(),
              isFalse,
              reason: 'there is no transition to wait for',
            );
            expect(await dismissedCount(), 0);
          });
        }
      });

      group('a pointer that takes hold of a panel on its way back', () {
        test('carries on from where the panel is, without a jump', () async {
          const side = 'bottom';
          final docked = await openDocked(side);
          final first = await stroke(side, docked, [
            -120,
          ], const Duration(milliseconds: 600));
          await first.up();
          expect(await pauseReturn(), isTrue);
          final mid = poseOf(side, docked, (await returnAt(90)).rect).stretch;
          expect(mid, greaterThan(1));
          expect(mid, lessThan(20.625));

          // Down on the panel as it is — the transition stays held at 90 ms.
          final second = _Pointer(page);
          final toward = _kTowardEdge[side]!;
          final at = grab(side, docked);
          await second.down(at);
          await frames(2);
          expect(
            poseOf(side, docked, (await panelRect())!).stretch,
            closeTo(mid, 0.5),
            reason: 'a finger came down; the panel did not move',
          );

          // 25 px more of pull on top of the pull that makes `mid`.
          final limit = _num(constants['reach']) * extent;
          final tension = _num(constants['tension']);
          final overshoot = limit * mid / (tension * (limit - mid));
          final pulled = tension * (overshoot + 25);
          final want = limit * pulled / (limit + pulled);
          await second.walk(at, toward, [
            -25,
          ], const Duration(milliseconds: 200));
          await frames(2);
          expect(
            poseOf(side, docked, (await panelRect())!).stretch,
            closeTo(want, 0.5),
          );

          await second.up();
          expect(await pauseReturn(), isTrue);
          await finishReturn();
          expect(await panelRect(), docked);
          expect(await dismissedCount(), 0);
        });

        test('a returning slide is carried on as a slide', () async {
          const side = 'bottom';
          final docked = await openDocked(side);
          final first = await stroke(side, docked, [
            100,
          ], const Duration(milliseconds: 1200));
          await first.up();
          expect(await pauseReturn(), isTrue);
          final mid = poseOf(side, docked, (await returnAt(90)).rect).slide;
          expect(mid, inExclusiveRange(1, 99));

          final second = _Pointer(page);
          final at = grab(side, docked) + Point<double>(0, mid);
          await second.down(at);
          await second.walk(at, _kTowardEdge[side]!, [
            30,
          ], const Duration(milliseconds: 300));
          await frames(2);

          expect(
            poseOf(side, docked, (await panelRect())!).slide,
            closeTo(mid + 30, 0.5),
          );
          await second.up();
          await pauseReturn();
          await finishReturn();
        });
      });

      group('the browser taking the pointer away', () {
        test('puts the panel back and dismisses nothing', () async {
          const side = 'bottom';
          final docked = await openDocked(side);
          final pointer = await stroke(side, docked, [
            -80,
          ], const Duration(milliseconds: 400));
          final stretched = poseOf(side, docked, (await panelRect())!).stretch;
          expect(stretched, greaterThan(10));

          // What a scroll the browser starts, or a system gesture, does to a
          // pointer in flight.
          await page.evaluate<void>('''
() => document.querySelector('[role="dialog"]').dispatchEvent(
      new PointerEvent('pointercancel', {pointerId: 1, bubbles: true})
    )''');
          await frames(2);
          expect(await pauseReturn(), isTrue);
          await finishReturn();
          expect(await panelRect(), docked);

          await pointer.up();
          await Future<void>.delayed(_kAfterLift);
          expect(await panelRect(), docked);
          expect(await dismissedCount(), 0);
        });
      });

      group('it is off unless it is asked for', () {
        for (final side in _kTowardEdge.keys) {
          test('$side drawer pulled past its dock stops dead', () async {
            final docked = await openDocked(side, rubberBand: false);
            final pointer = await stroke(side, docked, [
              -30,
              -90,
              -200,
            ], const Duration(milliseconds: 600));

            expect(await panelRect(), docked);
            expect(
              (await readPanel())!.transform,
              anyOf('none', startsWith('matrix(1, 0, 0, 1, 0, 0')),
            );
            await pointer.up();
            await frames(3);
            expect(await panelRect(), docked);
            expect(await dismissedCount(), 0);
          });
        }
      });

      group('a document that reads right to left', () {
        // `CoreDrawerSide` is a physical edge, so a drawer docked to the left
        // stays on the left and stretches away from it whatever the direction
        // of the text; a logical `start` / `end` would swap the two.
        for (final side in ['left', 'right']) {
          test('$side drawer: the same edge, the same stretch', () async {
            await page.evaluate<void>(
              '''() => { document.documentElement.dir = 'rtl'; }''',
            );
            final docked = await openDocked(side);
            final along = side == 'left'
                ? docked.left
                : docked.left + docked.width;
            expect(
              along,
              closeTo(side == 'left' ? 0 : _kViewportWidth, 1),
              reason: 'the panel is docked to the $side edge of the viewport',
            );

            final pointer = await stroke(side, docked, [
              -20,
              -40,
              -60,
            ], const Duration(milliseconds: 600));

            final pose = poseOf(side, docked, (await panelRect())!);
            expect(
              pose.slide,
              closeTo(0, 0.01),
              reason: 'the docked edge moved',
            );
            expect(pose.stretch, closeTo(15.7143, _kEdgeTolerance));

            await pointer.up();
            expect(await pauseReturn(), isTrue);
            await finishReturn();
            expect(await panelRect(), docked);
            expect(await dismissedCount(), 0);
          });
        }
      });

      group('touch', () {
        setUp(() async {
          // A touch is turned into a scroll by the browser's own gesture
          // recogniser, which only knows the real window: a touch below the
          // window's edge is seen by the page but never scrolls anything. The
          // viewport is kept inside it, where the mouse tests' taller one is
          // not.
          await page.setViewport(
            const pptr.DeviceViewport(width: 800, height: 600),
          );
          await page.devTools.emulation.setTouchEmulationEnabled(
            true,
            maxTouchPoints: 1,
          );
          // Record the largest stretch the panel is ever drawn at, frame by
          // frame, because a gesture the browser synthesises is over before
          // a probe can look.
          await page.evaluate<void>('''
() => {
            window.__maxScale = 1;
            const tick = () => {
              const panel = document.querySelector('[role="dialog"]');
              if (panel) {
                const t = getComputedStyle(panel).transform;
                const m = t.startsWith('matrix(')
                  ? t.slice(7, -1).split(',').map(Number) : null;
                if (m) window.__maxScale = Math.max(window.__maxScale, m[3]);
              }
              requestAnimationFrame(tick);
            };
            requestAnimationFrame(tick);
          }''');
        });

        Future<double> maxStretch() async =>
            ((await page.evaluate<num>('() => window.__maxScale')).toDouble() -
                1) *
            extent;

        test('a finger that scrolls the body scrolls it and stretches '
            'nothing', () async {
          const side = 'bottom';
          final docked = await openDocked(side, sheet: true, scrolling: true);
          final before = await page.evaluate<num>('''
() => document.querySelector('[role="dialog"] .overflow-auto').scrollTop''');

          // Up is the open direction for a bottom sheet — and the way a body
          // is scrolled forward. The browser takes the touch for the scroll
          // once it has moved a slop's worth.
          await _Finger(page).drag(
            Point(
              docked.left + docked.width / 2,
              docked.top + docked.height - 40,
            ),
            const Point(0, -5),
            30,
          );
          await frames(3);
          await Future<void>.delayed(const Duration(milliseconds: 500));

          expect(
            await page.evaluate<num>('''
() => document.querySelector('[role="dialog"] .overflow-auto').scrollTop'''),
            greaterThan(before),
            reason: 'the body scrolled',
          );
          // The panel may have followed the finger for the slop the browser
          // waits before it calls the touch a scroll; the 150 px of the scroll
          // itself would have drawn it 22 px out.
          expect(await maxStretch(), lessThan(10));
          expect(await panelRect(), docked);
          expect(await dismissedCount(), 0);
        });

        test(
          'a finger on the header stretches the panel, not the body',
          () async {
            const side = 'bottom';
            final docked = await openDocked(side, sheet: true, scrolling: true);

            await _Finger(page).drag(
              Point(docked.left + docked.width / 2, docked.top + 40),
              const Point(0, -5),
              30,
            );
            await frames(3);

            expect(await maxStretch(), greaterThan(10));
            expect(
              await page.evaluate<num>('''
() => document.querySelector('[role="dialog"] .overflow-auto').scrollTop'''),
              0,
            );
            await Future<void>.delayed(const Duration(milliseconds: 600));
            expect(await panelRect(), docked);
            expect(await dismissedCount(), 0);
          },
        );
      });
    },
    skip: chromePath == null
        ? 'no local Chrome — the Web drawer cannot be driven here'
        : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
