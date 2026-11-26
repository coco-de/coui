// The Web drawer's release, driven by real pointer input in Chrome: a quick
// short stroke dismisses it, a slow one snaps back, on every side.
//
// The VM cannot reach the Web drawer's drag path — it needs a real
// `PointerEvent`, real layout and a real pointer capture (see
// `packages/coui_web/test/components/overlay/drawer_sheet_test.dart`) — so
// the tracker, the sign and the clock the pointer handlers feed the release
// rule with can only be judged here. The rule and the tracker are Core's and
// pinned by `packages/coui_core/test/fixtures/drag_release_vectors.json`; the
// Flutter sheet is held to the same `gestures` table by its own test. This
// file puts the compiled shipped drawer through the same rows.
//
// ## How the pointer is driven, and why its clock is stamped
//
// The strokes go through the DevTools input domain: trusted events the
// browser routes through hit testing and pointer capture exactly as it does
// a real mouse. Each carries an explicit `timestamp`, and Chrome hands that
// to the page as `PointerEvent.timeStamp`. A speed is a distance over a
// time, and the time the drawer reads is the event's own clock — so stamping
// it makes the stroke's speed the table's speed whatever the machine is
// doing, instead of a race between this process and the renderer.
//
// One event is sent per frame (the probe waits a frame between them).
// Chrome aligns `pointermove` to frames and delivers one event per frame for
// whatever it received in between, so pacing the sends keeps the stroke the
// page sees the stroke that was sent, instead of whatever coalescing leaves
// of it.
//
// ## What each case asserts
//
//   mid-drag    the panel followed the pointer by `travel` px toward its
//               edge (none if the stroke ran the other way) — so a panel
//               that "snaps back" was judged, not a drag that never began.
//   after lift  dismissed (the panel left the page and the open future
//               completed) or still docked at the rect it started from.
//
// What each kind of case guards: the rows with a quick stroke fail if the
// tracker's reading is not handed to the release; the left and top rows fail
// if that reading is not re-signed for the edge the panel hides behind; the
// slow row fails if the event's milliseconds are read as anything but
// milliseconds; the hold row fails if the reading is taken at the last move
// instead of at the lift; and the late-delivery case fails if the drawer
// times the gesture by when its handlers ran instead of by the events' own
// clock.
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Point;

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:puppeteer/protocol/input.dart'
    show InputApi, MouseButton, TimeSinceEpoch;
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';

/// The vector table shared with Core, Flutter and the VM Web test (cwd is the
/// repository root under `dart test tool/parity/test`).
const String _kVectorsPath =
    'packages/coui_core/test/fixtures/drag_release_vectors.json';

const String _kEntryPath = 'tool/parity/src/web/drawer_fling_entry.dart';

const int _kViewportWidth = 800;
const int _kViewportHeight = 700;

/// A display's frame: how often a browser reports a moving pointer.
const Duration _kFrame = Duration(milliseconds: 16);

/// Longer than the drawer's 350 ms slide-out, with room for a busy machine,
/// so "gone" and "back where it was docked" are both settled when read.
const Duration _kAfterLift = Duration(milliseconds: 900);

/// A stroke longer than this runs on two sides only. The two together cover
/// both axes and both signs; the quick strokes, which are cheap, run on all
/// four.
const int _kQuickStrokeMs = 200;

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

/// Where each side's panel hides: the unit step of a position that moves
/// toward the edge the panel hides behind.
const Map<String, Point<double>> _kTowardEdge = {
  'bottom': Point(0, 1),
  'top': Point(0, -1),
  'right': Point(1, 0),
  'left': Point(-1, 0),
};

/// The panel's rect along its slide axis, read off the page.
typedef _Rect = ({double left, double top, double width, double height});

/// One pointer, with a clock of its own.
///
/// Every event it sends is stamped `origin + clock`, where the origin is "now"
/// when the pointer is created — Chrome only honours a stamp that is a
/// plausible wall-clock time — and the clock moves exactly as far as the
/// stroke says, not as far as the process happened to take.
class _Pointer {
  _Pointer(this._page)
    : _input = _page.devTools.input,
      _origin = DateTime.now().millisecondsSinceEpoch / 1000;

  final pptr.Page _page;
  final InputApi _input;
  final double _origin;
  Duration _clock = Duration.zero;

  TimeSinceEpoch get _stamp => TimeSinceEpoch(
    _origin + _clock.inMicroseconds / Duration.microsecondsPerSecond,
  );

  /// Waits for the next frame, so the browser delivers what was sent so far
  /// as its own event.
  Future<void> _frame() => _page.evaluate<void>(
    '() => new Promise(resolve => requestAnimationFrame(() => resolve()))',
  );

  Future<void> down(Point<double> at) async {
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

  /// Moves to [to], [after] later on the pointer's clock, and gives the
  /// browser [delivery] of real time to hand the page the event.
  Future<void> move(
    Point<double> to, {
    required Duration after,
    Duration delivery = Duration.zero,
  }) async {
    _clock += after;
    await _input.dispatchMouseEvent(
      'mouseMoved',
      to.x,
      to.y,
      button: MouseButton.left,
      buttons: 1,
      timestamp: _stamp,
    );
    await _frame();
    if (delivery > Duration.zero) await Future<void>.delayed(delivery);
  }

  /// Lifts at [at], [after] later on the pointer's clock — the pointer rests
  /// that long first.
  Future<void> up(Point<double> at, {Duration after = Duration.zero}) async {
    _clock += after;
    await _input.dispatchMouseEvent(
      'mouseReleased',
      at.x,
      at.y,
      button: MouseButton.left,
      buttons: 0,
      clickCount: 1,
      timestamp: _stamp,
    );
  }
}

void main() {
  final repoRoot = Directory.current.path;
  final chromePath = _systemChromePath();
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final gestures = doc['gestures']! as Map<String, Object?>;
  final extent = (gestures['extent']! as num).toDouble();
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

  Future<_Rect?> panelRect() async {
    final json = await page.evaluate<String?>('''
() => {
      const panel = document.querySelector('[role="dialog"]');
      if (!panel) return null;
      const r = panel.getBoundingClientRect();
      return JSON.stringify([r.left, r.top, r.width, r.height]);
    }''');
    if (json == null) return null;
    final v = (jsonDecode(json) as List).cast<num>();

    return (
      left: v[0].toDouble(),
      top: v[1].toDouble(),
      width: v[2].toDouble(),
      height: v[3].toDouble(),
    );
  }

  Future<int> dismissedCount() =>
      page.evaluate<int>('() => couiDrawerDismissed()');

  /// Waits for the panel to come to rest inside the viewport and returns the
  /// rect it rests at. The slide-in is a 350 ms transition that starts a frame
  /// after the panel mounts, and a busy machine can delay both.
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
  Future<_Rect> openDocked(String side) async {
    await page.evaluate<void>(
      '(side, extent) => couiDrawerOpen(side, extent)',
      args: [side, extent],
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

  /// How far the panel has moved from [docked] toward its edge, in px.
  Future<double> displacement(String side, _Rect docked) async {
    final now = await panelRect();
    if (now == null) return double.nan;
    final toward = _kTowardEdge[side]!;

    return (now.left - docked.left) * toward.x +
        (now.top - docked.top) * toward.y;
  }

  /// A stroke of [travel] px toward the edge in [duration] on the pointer's
  /// clock, one move per frame, starting 24 px inside the panel's leading edge
  /// (the edge facing the middle of the screen, which leaves the room a long
  /// stroke needs).
  ///
  /// [delivery] is real time spent on each move on top of the frame wait —
  /// the late-delivery case: the stamps say a flick, the wall clock says it
  /// dawdled. [hold] is how long the pointer rests, by its own clock, between
  /// the last move and the lift.
  Future<double> stroke(
    String side,
    _Rect docked, {
    required double travel,
    required Duration duration,
    Duration delivery = Duration.zero,
    Duration hold = Duration.zero,
  }) async {
    final toward = _kTowardEdge[side]!;
    final start = switch (side) {
      'bottom' => Point(docked.left + docked.width / 2, docked.top + 24),
      'top' => Point(
        docked.left + docked.width / 2,
        docked.top + docked.height - 24,
      ),
      'right' => Point(docked.left + 24, docked.top + docked.height / 2),
      _ => Point(
        docked.left + docked.width - 24,
        docked.top + docked.height / 2,
      ),
    };
    final pointer = _Pointer(page);
    await pointer.down(start);

    final steps = (duration.inMicroseconds / _kFrame.inMicroseconds).ceil();
    var at = start;
    for (var i = 1; i <= steps; i++) {
      final progress = i / steps;
      at = Point(
        start.x + toward.x * travel * progress,
        start.y + toward.y * travel * progress,
      );
      await pointer.move(
        at,
        after: Duration(
          microseconds: (duration.inMicroseconds / steps).round(),
        ),
        delivery: delivery,
      );
    }
    await frames(2);
    final moved = await displacement(side, docked);
    await pointer.up(at, after: hold);

    return moved;
  }

  /// Reads what the lift did: `true` when the drawer left, `false` when it is
  /// back at [docked].
  Future<bool> dismissedAfterLift(_Rect docked) async {
    await Future<void>.delayed(_kAfterLift);
    await frames(2);
    final rect = await panelRect();
    if (rect == null) {
      expect(await dismissedCount(), 1, reason: 'the open future completes');
      return true;
    }
    expect(await dismissedCount(), 0);
    const back = 'a drawer that stays comes back to where it was docked';
    expect(rect.left, closeTo(docked.left, 1), reason: back);
    expect(rect.top, closeTo(docked.top, 1), reason: back);
    expect(rect.width, closeTo(docked.width, 1), reason: back);
    expect(rect.height, closeTo(docked.height, 1), reason: back);

    return false;
  }

  group(
    'the Web drawer release, with real pointer input in Chrome',
    () {
      setUpAll(() async {
        fixture = Directory.systemTemp.createTempSync('coui-drawer-fling-');
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
        // slide is part of what is being judged.
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
          '() => typeof couiDrawerOpen === "function"',
        );
      });

      tearDown(() => page.close());

      tearDownAll(() async {
        await browser.close();
        fixture.deleteSync(recursive: true);
      });

      for (final side in _kTowardEdge.keys) {
        group('$side drawer', () {
          for (final c in cases) {
            final durationMs = (c['durationMs']! as num).toInt();
            if (durationMs > _kQuickStrokeMs &&
                side != 'bottom' &&
                side != 'left') {
              continue;
            }
            test(c['name']! as String, () async {
              final docked = await openDocked(side);
              final travel = (c['travel']! as num).toDouble();

              final moved = await stroke(
                side,
                docked,
                travel: travel,
                duration: Duration(milliseconds: durationMs),
                hold: Duration(
                  milliseconds: ((c['holdMs'] as num?) ?? 0).toInt(),
                ),
              );

              // The panel follows the pointer toward its edge, and only
              // that way.
              expect(
                moved,
                closeTo(travel > 0 ? travel : 0, 2),
                reason: 'the panel followed the pointer',
              );
              expect(await dismissedAfterLift(docked), c['dismisses']);
            });
          }
        });
      }

      group("the pointer clock is the event's", () {
        test('a flick that reaches the page late is still a flick', () async {
          // 120 px stamped 60 ms apart in four events, each delivered 100 ms
          // after the last in wall-clock time: a drawer that timed the
          // gesture by when its handlers ran would see 120 px over ~400 ms,
          // 300 px/s, under the 400 px/s a flick needs.
          const side = 'bottom';
          final docked = await openDocked(side);

          await stroke(
            side,
            docked,
            travel: 120,
            duration: const Duration(milliseconds: 60),
            delivery: const Duration(milliseconds: 100),
          );

          expect(await dismissedAfterLift(docked), isTrue);
        });
      });
    },
    skip: chromePath == null
        ? 'no local Chrome — the Web drawer cannot be driven here'
        : false,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
