// A Drawer panel dragged past its dock: the far edge stretches with less and
// less return, the docked edge stays on the screen edge, and letting go pulls
// the panel back on the curve Core states — without ever changing what
// dismisses. Driven with real pointer traces through the gesture arena, on all
// four sides, the plain, sheet and backdrop-host variants and right-to-left,
// and held to the vector table coui_core shares with the Web drawer.
//
// The Web seat's markup is in
// `packages/coui_web/test/components/overlay/drawer_rubber_band_test.dart` and
// a real-Chrome probe puts the shipped Web drawer through the same table.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The vector table coui_core shares with the Web seat and the Chrome probe
/// (cwd is `packages/coui_flutter` under `flutter test`).
const String _kVectorsPath =
    '../coui_core/test/fixtures/drawer_rubber_band_vectors.json';

/// A display's frame: how often a moving pointer is reported.
const Duration _kFrame = Duration(milliseconds: 16);

/// How close a painted edge has to be to the table. The table is rounded to
/// four decimals and a matrix is single precision.
const double _kEdgeTolerance = 0.05;

/// The curve of the return is Flutter's `Cubic`, which finds the parameter of
/// a point to within 1e-3; at the table's largest stretch that is a few
/// hundredths of a pixel.
const double _kSettleTolerance = 0.2;

const Duration _kSettle = Duration(milliseconds: 300);

/// Every side, with the unit step toward the edge it hides behind.
const Map<CoreDrawerSide, material.Offset> _kToward = {
  CoreDrawerSide.bottom: material.Offset(0, 1),
  CoreDrawerSide.top: material.Offset(0, -1),
  CoreDrawerSide.right: material.Offset(1, 0),
  CoreDrawerSide.left: material.Offset(-1, 0),
};

double _num(Object? value) => (value! as num).toDouble();

/// The drawer app: a button that opens a [side] drawer with the rubber band
/// per [rubberBand], whose panel is [extent] px long on its slide axis.
///
/// [sheet] draws the bottom-sheet parts (handle, title). [backdropHost]
/// mounts the app-shell host the backdrop transform renders the panel
/// through. [direction] and [reduceMotion] are parameters because a harness
/// that fixes them makes a claim about them unfalsifiable.
material.Widget _app(
  CoreDrawerSide side, {
  bool rubberBand = true,
  bool draggable = true,
  double? extent = 300,
  bool sheet = false,
  bool backdropHost = false,
  material.TextDirection direction = material.TextDirection.ltr,
  bool reduceMotion = false,
  material.Widget? content,
}) {
  final horizontal =
      side == CoreDrawerSide.left || side == CoreDrawerSide.right;
  final style = extent == null
      ? null
      : (horizontal
            ? CoreDrawerStyle(panelWidth: extent)
            : CoreDrawerStyle(panelHeight: extent));

  return material.MaterialApp(
    builder: (context, built) {
      final themed = Theme(
        data: const ThemeData(),
        child: backdropHost ? DrawerBackdropLayer(child: built!) : built!,
      );
      final directed = material.Directionality(
        textDirection: direction,
        child: themed,
      );

      return reduceMotion
          ? material.MediaQuery(
              data: material.MediaQuery.of(
                context,
              ).copyWith(disableAnimations: true),
              child: directed,
            )
          : directed;
    },
    home: material.Builder(
      builder: (context) => material.Center(
        child: material.ElevatedButton(
          onPressed: () => openDrawer<void>(
            context: context,
            side: side,
            rubberBand: rubberBand,
            draggable: draggable,
            drawerStyle: style,
            builder: (context) => Drawer(
              side: side,
              title: sheet ? 'Sheet' : null,
              showDragHandle: sheet,
              drawerStyle: style,
              content:
                  content ??
                  const material.SizedBox(
                    height: 120,
                    width: 120,
                    child: material.Text('content'),
                  ),
            ),
          ),
          child: const material.Text('open'),
        ),
      ),
    ),
  );
}

/// Pumps [app], opens its drawer and returns where the panel rests, docked.
Future<material.Rect> _open(WidgetTester tester, material.Widget app) async {
  await tester.pumpWidget(app);
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(Drawer), findsOneWidget);

  return tester.getRect(find.byType(Drawer));
}

material.Rect _rect(WidgetTester tester) => tester.getRect(find.byType(Drawer));

/// Where the painted panel is, read off its rect against [docked]:
///
/// * `slide` — how far the docked edge has moved toward the edge the panel
///   hides behind (a stretch must leave it at 0);
/// * `stretch` — how far the far edge has moved out beyond what that slide
///   explains.
({double slide, double stretch}) _pose(
  CoreDrawerSide side,
  material.Rect docked,
  material.Rect now,
) {
  final (dockShift, farOut) = switch (side) {
    CoreDrawerSide.bottom => (now.bottom - docked.bottom, docked.top - now.top),
    CoreDrawerSide.top => (docked.top - now.top, now.bottom - docked.bottom),
    CoreDrawerSide.right => (now.right - docked.right, docked.left - now.left),
    CoreDrawerSide.left => (docked.left - now.left, now.right - docked.right),
  };

  return (slide: dockShift, stretch: farOut + dockShift);
}

/// A finger that presses on the panel and drags it, with the pulls counted
/// from where it pressed.
///
/// The panel is the only thing under the finger that competes for the
/// gesture, so the drag is the finger's from its first pixel; a press on a
/// button inside the panel would first have to travel the framework's slop,
/// and a test that wants that says so.
class _Finger {
  _Finger._(this.tester, this.side, this.gesture, this.origin);

  final WidgetTester tester;
  final CoreDrawerSide side;
  final TestGesture gesture;

  /// Where the finger pressed: the pull is 0 here.
  final material.Offset origin;
  Duration _clock = Duration.zero;

  static Future<_Finger> press(
    WidgetTester tester,
    CoreDrawerSide side,
    material.Offset start,
  ) async {
    final gesture = await tester.startGesture(start);

    return _Finger._(tester, side, gesture, start);
  }

  /// Walks the pointer through [steps] (pulls from the recognition point), a
  /// move every frame, in straight lines at one pace over [duration].
  Future<void> walk(List<double> steps, Duration duration) async {
    final toward = _kToward[side]!;
    final segment = duration.inMicroseconds / steps.length;
    var from = 0.0;
    for (final to in steps) {
      final moves = math.max(1, (segment / _kFrame.inMicroseconds).ceil());
      final step = Duration(microseconds: (segment / moves).round());
      for (var i = 1; i <= moves; i++) {
        _clock += step;
        await gesture.moveTo(
          origin + toward * (from + (to - from) * i / moves),
          timeStamp: _clock,
        );
        await tester.pump(step);
      }
      from = to;
    }
  }

  /// Lifts, [hold] after the last move.
  Future<void> lift({Duration hold = Duration.zero}) async {
    if (hold > Duration.zero) await tester.pump(hold);
    await gesture.up(timeStamp: _clock + hold);
  }
}

/// Where a press on the panel lands: inside it, 24 px from the edge facing
/// the middle of the screen, which leaves the room a long pull needs.
material.Offset _grab(CoreDrawerSide side, material.Rect docked) =>
    switch (side) {
      CoreDrawerSide.bottom => docked.topCenter + const material.Offset(0, 24),
      CoreDrawerSide.top => docked.bottomCenter - const material.Offset(0, 24),
      CoreDrawerSide.right => docked.centerLeft + const material.Offset(24, 0),
      CoreDrawerSide.left => docked.centerRight - const material.Offset(24, 0),
    };

void main() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final gestures = doc['gestures']! as Map<String, Object?>;
  final extent = _num(gestures['extent']);
  final cases = (gestures['cases']! as List).cast<Map<String, Object?>>();
  final settleDurationMs =
      (doc['settle']! as Map<String, Object?>)['durationMs'];

  /// Runs one row of the gesture table on [side]: the drag, the pose it
  /// leaves, the release and what it does.
  Future<void> runCase(
    WidgetTester tester,
    CoreDrawerSide side,
    Map<String, Object?> c, {
    bool sheet = false,
    bool backdropHost = false,
    material.TextDirection direction = material.TextDirection.ltr,
  }) async {
    final docked = await _open(
      tester,
      _app(
        side,
        extent: extent,
        sheet: sheet,
        backdropHost: backdropHost,
        direction: direction,
      ),
    );
    if (backdropHost) {
      // The variant under test: the host draws the panel, in a navigator of
      // its own above the app's.
      expect(find.byType(material.Navigator), findsNWidgets(2));
    }
    final steps = (c['steps']! as List).map(_num).toList();
    final finger = await _Finger.press(tester, side, _grab(side, docked));
    await finger.walk(
      steps,
      Duration(milliseconds: (c['durationMs']! as num).toInt()),
    );

    // The pose the drag leaves: the table's, with the docked edge unmoved
    // whenever the panel is stretched.
    final want = c['pose']! as Map<String, Object?>;
    final pose = _pose(side, docked, _rect(tester));
    expect(pose.slide, closeTo(_num(want['slide']), _kEdgeTolerance));
    expect(pose.stretch, closeTo(_num(want['stretch']), _kEdgeTolerance));

    final holdMs = ((c['holdMs'] as num?) ?? 0).toInt();
    await finger.lift(hold: Duration(milliseconds: holdMs));

    if (c['dismisses']! as bool) {
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);

      return;
    }

    // Kept: the panel is where the finger left it until the next frame, then
    // comes back along the table's samples.
    expect(find.byType(Drawer), findsOneWidget);
    await tester.pump();
    var elapsed = 0;
    for (final row in (c['settle']! as List).cast<List<Object?>>()) {
      final at = (row[0]! as num).toInt();
      await tester.pump(Duration(milliseconds: at - elapsed));
      elapsed = at;
      final left = _pose(side, docked, _rect(tester));
      expect(
        math.max(left.slide, left.stretch),
        closeTo(_num(row[1]), _kSettleTolerance),
        reason: '$at ms after the release',
      );
    }
    await tester.pumpAndSettle();
    expect(_rect(tester), docked);
  }

  test('the table is for the settle duration Core ships', () {
    expect(
      settleDurationMs,
      CoreDrawerRubberBand.defaultSettleDuration.inMilliseconds,
    );
    expect(_kSettle, CoreDrawerRubberBand.defaultSettleDuration);
  });

  group('the shared gesture table, with real pointer traces', () {
    for (final side in _kToward.keys) {
      group('${side.name} drawer', () {
        for (final c in cases) {
          testWidgets(c['name']! as String, (tester) async {
            await runCase(tester, side, c);
          });
        }
      });
    }
  });

  group('the bottom sheet', () {
    // The sheet draws a handle and a header; the same pull stretches it the
    // same way.
    for (final c in cases.take(4)) {
      testWidgets(c['name']! as String, (tester) async {
        await runCase(tester, CoreDrawerSide.bottom, c, sheet: true);
      });
    }

    testWidgets('a content-sized sheet stretches by a fraction of its own '
        'height', (tester) async {
      final docked = await _open(
        tester,
        _app(CoreDrawerSide.bottom, extent: null, sheet: true),
      );
      final finger = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      await finger.walk([-60], const Duration(milliseconds: 600));

      // The closed form, with the table's own reach and tension.
      final constants = doc['constants']! as Map<String, Object?>;
      final limit = _num(constants['reach']) * docked.height;
      final pulled = _num(constants['tension']) * 60;
      final want = limit * pulled / (limit + pulled);
      final pose = _pose(CoreDrawerSide.bottom, docked, _rect(tester));
      expect(pose.slide, closeTo(0, _kEdgeTolerance));
      expect(pose.stretch, closeTo(want, _kEdgeTolerance));
      expect(pose.stretch, lessThan(limit));
      await finger.lift();
      await tester.pumpAndSettle();
      expect(_rect(tester), docked);
    });
  });

  group('the backdrop-transform variant (the panel is drawn by the host)', () {
    for (final side in _kToward.keys) {
      group('${side.name} drawer', () {
        for (final c in cases.take(3)) {
          testWidgets(c['name']! as String, (tester) async {
            await runCase(tester, side, c, backdropHost: true);
          });
        }
      });
    }
  });

  group('right to left', () {
    // The sides are the screen's, not the reading direction's: a left drawer
    // is docked to the left edge in a right-to-left locale, and the stretch
    // grows from there.
    for (final side in _kToward.keys) {
      for (final c in cases.take(2)) {
        testWidgets('${side.name}: ${c['name']}', (tester) async {
          await runCase(
            tester,
            side,
            c,
            direction: material.TextDirection.rtl,
          );
        });
      }
    }
  });

  group('the docked edge never leaves the screen edge', () {
    for (final side in _kToward.keys) {
      testWidgets('${side.name} drawer, at every step of a long pull', (
        tester,
      ) async {
        final docked = await _open(tester, _app(side));
        final finger = await _Finger.press(tester, side, _grab(side, docked));
        var previous = 0.0;
        for (final pull in [-5.0, -20.0, -60.0, -150.0, -400.0, -900.0]) {
          await finger.walk([pull], const Duration(milliseconds: 64));
          final pose = _pose(side, docked, _rect(tester));
          expect(pose.slide, closeTo(0, 0.01), reason: 'pull $pull');
          expect(pose.stretch, greaterThan(previous), reason: 'pull $pull');
          expect(
            pose.stretch,
            lessThan(CoreDrawerRubberBand.defaultReach * extent),
            reason: 'pull $pull',
          );
          previous = pose.stretch;
        }
        await finger.lift();
        await tester.pumpAndSettle();
      });
    }
  });

  group('what dismisses is the same with a rubber band', () {
    for (final side in _kToward.keys) {
      final toward = _kToward[side]!;

      testWidgets('a fling in the open direction never dismisses a '
          '${side.name} drawer', (tester) async {
        final docked = await _open(tester, _app(side));

        await tester.fling(find.byType(Drawer), -toward * 150, 2500);
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsOneWidget);
        expect(_rect(tester), docked);
      });

      testWidgets('a fling toward the edge still dismisses a ${side.name} '
          'drawer', (tester) async {
        await _open(tester, _app(side));

        await tester.fling(find.byType(Drawer), toward * 120, 1500);
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), findsNothing);
      });
    }

    testWidgets('a drag toward the edge is one for one, as without one', (
      tester,
    ) async {
      final docked = await _open(tester, _app(CoreDrawerSide.bottom));
      final finger = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      await finger.walk([37], const Duration(milliseconds: 700));

      final pose = _pose(CoreDrawerSide.bottom, docked, _rect(tester));
      expect(pose.slide, closeTo(37, _kEdgeTolerance));
      expect(pose.stretch, closeTo(0, _kEdgeTolerance));
      await finger.lift();
      await tester.pumpAndSettle();
    });

    testWidgets('a pull to just under half dismisses nothing, just over '
        'does', (tester) async {
      const threshold = CoreDrawerContract.defaultDragDismissThreshold;
      for (final (pull, dismisses) in [
        (extent * threshold - 12, false),
        (extent * threshold + 12, true),
      ]) {
        final docked = await _open(tester, _app(CoreDrawerSide.bottom));
        final finger = await _Finger.press(
          tester,
          CoreDrawerSide.bottom,
          _grab(CoreDrawerSide.bottom, docked),
        );
        await finger.walk([pull], const Duration(milliseconds: 1800));
        await finger.lift();
        await tester.pumpAndSettle();

        expect(find.byType(Drawer), dismisses ? findsNothing : findsOneWidget);
      }
    });
  });

  group('it is off unless it is asked for', () {
    test('the default is off on the widget, the route and the contract', () {
      expect(CoreDrawerContract.defaultRubberBand, isFalse);
      expect(
        const Drawer(content: material.SizedBox()).rubberBand,
        CoreDrawerContract.defaultRubberBand,
      );
    });

    test('copyWith carries the flag', () {
      const drawer = Drawer(content: material.SizedBox());

      expect(drawer.copyWith(rubberBand: true).rubberBand, isTrue);
      expect(drawer.copyWith().rubberBand, isFalse);
    });

    for (final side in _kToward.keys) {
      testWidgets('a ${side.name} drawer pulled past its dock stops dead', (
        tester,
      ) async {
        final docked = await _open(tester, _app(side, rubberBand: false));
        final finger = await _Finger.press(tester, side, _grab(side, docked));
        await finger.walk([-30, -90, -200], const Duration(milliseconds: 600));

        expect(_rect(tester), docked);
        await finger.lift();
        await tester.pumpAndSettle();
        expect(_rect(tester), docked);
      });
    }

    testWidgets('a panel that is not draggable has nothing to stretch', (
      tester,
    ) async {
      final docked = await _open(
        tester,
        _app(CoreDrawerSide.bottom, draggable: false),
      );
      final finger = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      await finger.walk([-60], const Duration(milliseconds: 600));

      expect(_rect(tester), docked);
      await finger.lift();
      await tester.pumpAndSettle();
    });
  });

  group('reduced motion', () {
    // The stretch while the finger is down is the finger's own motion — a
    // position that follows a position — so it stays. The return is a
    // transition, and a transition collapses: a released panel is at its dock.
    for (final side in _kToward.keys) {
      testWidgets('${side.name}: the stretch follows the finger, the return '
          'is instant', (tester) async {
        final docked = await _open(
          tester,
          _app(side, reduceMotion: true),
        );
        final finger = await _Finger.press(tester, side, _grab(side, docked));
        await finger.walk([-20, -40, -60], const Duration(milliseconds: 600));

        final pose = _pose(side, docked, _rect(tester));
        expect(pose.slide, closeTo(0, 0.01));
        expect(pose.stretch, closeTo(15.7143, _kEdgeTolerance));

        await finger.lift();
        // One frame, not the 300 ms the same release takes otherwise.
        await tester.pump();
        expect(_rect(tester), docked);
        expect(find.byType(Drawer), findsOneWidget);
      });
    }

    testWidgets('without it the same release is still on its way after a '
        'frame', (tester) async {
      final docked = await _open(tester, _app(CoreDrawerSide.bottom));
      final finger = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      await finger.walk([-20, -40, -60], const Duration(milliseconds: 600));
      await finger.lift();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(_rect(tester), isNot(docked));
      await tester.pumpAndSettle();
      expect(_rect(tester), docked);
    });

    testWidgets('a slide released short of half is instant as well', (
      tester,
    ) async {
      final docked = await _open(
        tester,
        _app(CoreDrawerSide.bottom, reduceMotion: true),
      );
      final finger = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      await finger.walk([60], const Duration(milliseconds: 900));
      expect(
        _pose(CoreDrawerSide.bottom, docked, _rect(tester)).slide,
        closeTo(60, _kEdgeTolerance),
      );
      await finger.lift();
      await tester.pump();

      expect(_rect(tester), docked);
    });
  });

  group('a finger that takes hold of a panel on its way back', () {
    testWidgets('carries on from where the panel is, without a jump', (
      tester,
    ) async {
      final docked = await _open(tester, _app(CoreDrawerSide.bottom));
      final first = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      await first.walk([-120], const Duration(milliseconds: 600));
      final from = _pose(CoreDrawerSide.bottom, docked, _rect(tester)).stretch;
      await first.lift();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));

      // Mid-return: some, not all, of the stretch is left.
      final mid = _pose(CoreDrawerSide.bottom, docked, _rect(tester)).stretch;
      expect(mid, lessThan(from - 1));
      expect(mid, greaterThan(1));

      final second = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      // Recognised: the panel has not moved a pixel because a finger came
      // down on it.
      expect(
        _pose(CoreDrawerSide.bottom, docked, _rect(tester)).stretch,
        closeTo(mid, 0.5),
      );

      await second.walk([-25], const Duration(milliseconds: 200));
      // The pull picks up from the pose: the overshoot that makes `mid`,
      // plus 25 more.
      final want = CoreDrawerRubberBand.stretchOf(
        CoreDrawerRubberBand.overshootOf(mid, extent: extent) + 25,
        extent: extent,
      );
      expect(
        _pose(CoreDrawerSide.bottom, docked, _rect(tester)).stretch,
        closeTo(want, 0.5),
      );
      await second.lift();
      await tester.pumpAndSettle();
      expect(_rect(tester), docked);
    });

    testWidgets('a slide that was on its way back is carried on as a slide', (
      tester,
    ) async {
      final docked = await _open(tester, _app(CoreDrawerSide.bottom));
      final first = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      await first.walk([100], const Duration(milliseconds: 1200));
      await first.lift();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final mid = _pose(CoreDrawerSide.bottom, docked, _rect(tester)).slide;
      expect(mid, inExclusiveRange(1, 99));

      // The panel is `mid` px down: a finger lands on what is still under it.
      final second = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked) + material.Offset(0, mid),
      );
      await second.walk([30], const Duration(milliseconds: 300));

      expect(
        _pose(CoreDrawerSide.bottom, docked, _rect(tester)).slide,
        closeTo(mid + 30, 0.5),
      );
      await second.lift();
      await tester.pumpAndSettle();
    });
  });

  group('content that scrolls keeps its drag', () {
    material.Widget list() => material.SizedBox(
      height: 160,
      child: material.ListView(
        children: [
          for (var i = 0; i < 30; i++)
            material.SizedBox(height: 40, child: material.Text('row $i')),
        ],
      ),
    );

    testWidgets('a drag that starts on the list scrolls it and stretches '
        'nothing', (tester) async {
      final docked = await _open(
        tester,
        _app(CoreDrawerSide.bottom, extent: null, sheet: true, content: list()),
      );
      final scrollable = find.byType(material.Scrollable);
      final before = tester
          .state<material.ScrollableState>(scrollable)
          .position
          .pixels;

      // Up is the open direction for a bottom sheet — and the way a list is
      // scrolled forward.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('row 2')),
      );
      await gesture.moveBy(const material.Offset(0, -40));
      await tester.pump(_kFrame);
      await gesture.moveBy(const material.Offset(0, -80));
      await tester.pump(_kFrame);

      expect(
        tester.state<material.ScrollableState>(scrollable).position.pixels,
        greaterThan(before),
      );
      expect(_rect(tester), docked);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_rect(tester), docked);
    });

    testWidgets('a drag that starts on the header stretches the panel', (
      tester,
    ) async {
      final docked = await _open(
        tester,
        _app(CoreDrawerSide.bottom, extent: null, sheet: true, content: list()),
      );
      final scrollable = find.byType(material.Scrollable);
      final before = tester
          .state<material.ScrollableState>(scrollable)
          .position
          .pixels;

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Sheet')),
      );
      await gesture.moveBy(const material.Offset(0, -30));
      await tester.pump(_kFrame);
      await gesture.moveBy(const material.Offset(0, -60));
      await tester.pump(_kFrame);

      expect(
        _pose(CoreDrawerSide.bottom, docked, _rect(tester)).stretch,
        greaterThan(5),
      );
      expect(
        tester.state<material.ScrollableState>(scrollable).position.pixels,
        before,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_rect(tester), docked);
    });
  });

  group('the state it leaves behind', () {
    testWidgets('a release in the middle of a return that is then dismissed '
        'leaves nothing running', (tester) async {
      final docked = await _open(tester, _app(CoreDrawerSide.bottom));
      final finger = await _Finger.press(
        tester,
        CoreDrawerSide.bottom,
        _grab(CoreDrawerSide.bottom, docked),
      );
      await finger.walk([-80], const Duration(milliseconds: 600));
      await finger.lift();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The route goes away while the panel is on its way back.
      material.Navigator.of(
        tester.element(find.byType(Drawer)),
        rootNavigator: true,
      ).pop();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
    });
  });
}
