// MockupFoldable — what the widget does with its angle: which face is the
// device, where the content lives and what it is told about the fold, how
// the device gets from one angle to the next, and what input and assistive
// technology reach. Where each part is painted is the pose test's subject
// (`mockup_foldable_pose_test.dart`).
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mockup_foldable_harness.dart';

const Key _kContent = ValueKey('content');
const Key _kTarget = ValueKey('target');

/// One tick past the end of a move — the frame its ticker stops in.
const Duration _kTick = Duration(milliseconds: 1);

/// Counts the taps that reach it, and keeps the count in its own state.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: GestureDetector(
      key: _kTarget,
      onTap: () => setState(() => count += 1),
      child: const ColoredBox(
        color: Color(0xFF3366FF),
        child: SizedBox.square(dimension: 80),
      ),
    ),
  );
}

/// Reports the fold its screen is told about.
class _FoldProbe extends StatelessWidget {
  const _FoldProbe(this.onFold);

  final ValueChanged<CoreFoldLayout> onFold;

  @override
  Widget build(BuildContext context) {
    onFold(FoldScope.of(context));

    return const SizedBox.expand();
  }
}

Widget _foldable(
  double angle, {
  Widget child = const SizedBox.expand(key: _kContent),
  CoreMockupFoldableStyle style = kAtOnce,
}) =>
    MockupFoldable(foldAngle: angle, mockupFoldableStyle: style, child: child);

/// The device the content is on the screen of.
CoreMockupDevice _hostOf(WidgetTester tester, Finder content) => tester
    .widget<MockupDevice>(
      find.ancestor(of: content, matching: find.byType(MockupDevice)),
    )
    .device;

/// The pose the Core rules state for the stage on screen at [angle].
CoreMockupFoldPose _poseAt(WidgetTester tester, double angle) {
  final stage = stageOf(tester).size;

  return CoreMockupFoldPose.compute(
    angle: angle,
    width: stage.width,
    height: stage.height,
    thickness: CoreMockupFoldableStyle.defaultThickness,
    perspective: CoreMockupFoldableStyle.defaultPerspective,
  );
}

/// The matrix a part is drawn under.
Matrix4 _matrixOf(WidgetTester tester, Key part) => tester
    .widget<Transform>(
      find.descendant(of: find.byKey(part), matching: find.byType(Transform)),
    )
    .transform;

/// Whether the inner screen is drawn from a still, and so is bent.
bool _innerIsStill(WidgetTester tester) => tester
    .widget<SnapshotWidget>(find.byType(SnapshotWidget))
    .controller
    .allowSnapshotting;

void main() {
  group('MockupFoldable — the two faces', () {
    testWidgets('the stage is the open body at every angle; the cover is half '
        'as wide and as tall', (tester) async {
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.flat)));
      final open = stageOf(tester).size;
      expect(open.width, CoreMockupFoldableStyle.defaultWidth);
      expect(tester.getSize(faceOf(CoreMockupDevice.tablet)), open);

      for (final angle in const [144.0, 90.0, 60.0, 20.0, 0.0]) {
        await tester.pumpWidget(foldableApp(_foldable(angle)));
        expect(stageOf(tester).size, open, reason: '$angle°');
      }

      // Shut: the cover is the device.
      final cover = tester.renderObject<RenderBox>(
        faceOf(CoreMockupDevice.phone),
      );
      expect(cover.size.width, open.width / 2);
      expect(cover.size.height, closeTo(open.height, 1e-9));
    });

    testWidgets('draws with no MediaQuery above it, as a MockupDevice '
        'does', (tester) async {
      for (final angle in const [
        CoreMockupFold.flat,
        CoreMockupFold.halfOpen,
        CoreMockupFold.closed,
      ]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Theme(
              data: ThemeData(colorScheme: CoreThemePresets.lightColorScheme),
              child: _foldable(angle),
            ),
          ),
        );

        expect(tester.takeException(), isNull, reason: '$angle°');
        expect(find.byKey(_kContent), findsOneWidget, reason: '$angle°');
      }
    });

    testWidgets('the size follows the caller width and the theme scaling', (
      tester,
    ) async {
      await tester.pumpWidget(
        foldableApp(
          const MockupFoldable(
            width: 300,
            mockupFoldableStyle: kAtOnce,
            child: SizedBox.expand(),
          ),
          scaling: 1.5,
        ),
      );

      expect(stageOf(tester).size.width, 450);
      // The parts are of the scaled device: an edge is as deep as the scaled
      // thickness.
      await tester.pumpWidget(
        foldableApp(
          const MockupFoldable(
            foldAngle: CoreMockupFold.halfOpen,
            width: 300,
            mockupFoldableStyle: kAtOnce,
            child: SizedBox.expand(),
          ),
          scaling: 1.5,
        ),
      );
      expect(
        tester.getSize(edgeBox(kEdgeRightPart)).width,
        CoreMockupFoldableStyle.defaultThickness * 1.5,
      );
    });
  });

  group('MockupFoldable — where the content is', () {
    testWidgets('on the inner screen while the device is open, on the cover '
        'once it is nearly shut', (tester) async {
      const cases = [
        (CoreMockupFold.flat, CoreMockupDevice.tablet),
        (CoreMockupFold.halfOpen, CoreMockupDevice.tablet),
        (CoreMockupFold.coverUntil + 1, CoreMockupDevice.tablet),
        (CoreMockupFold.coverUntil, CoreMockupDevice.phone),
        (CoreMockupFold.closed, CoreMockupDevice.phone),
      ];
      for (final (angle, device) in cases) {
        await tester.pumpWidget(foldableApp(_foldable(angle)));
        expect(find.byKey(_kContent), findsOneWidget, reason: '$angle°');
        expect(
          _hostOf(tester, find.byKey(_kContent)),
          device,
          reason: '$angle°',
        );
      }
    });

    testWidgets('the inner screen is live only while it lies flat', (
      tester,
    ) async {
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.flat)));
      expect(_innerIsStill(tester), isFalse);

      await tester.pumpWidget(foldableApp(_foldable(179)));
      expect(_innerIsStill(tester), isTrue);

      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.flat)));
      expect(_innerIsStill(tester), isFalse);
    });

    testWidgets('the content keeps its state from flat to shut and back, and '
        'takes taps on both screens', (tester) async {
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.flat, child: const _Counter())),
      );
      final state = tester.state<_CounterState>(find.byType(_Counter));
      await tester.tap(find.byKey(_kTarget));
      expect(state.count, 1);

      // Shut: the same content, now under the cover's own transform.
      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.closed, child: const _Counter())),
      );
      expect(tester.state<_CounterState>(find.byType(_Counter)), same(state));
      expect(_hostOf(tester, find.byType(_Counter)), CoreMockupDevice.phone);
      await tester.tap(find.byKey(_kTarget));
      expect(state.count, 2);

      await tester.pumpWidget(
        foldableApp(_foldable(CoreMockupFold.flat, child: const _Counter())),
      );
      expect(tester.state<_CounterState>(find.byType(_Counter)), same(state));
      expect(state.count, 2);
      await tester.tap(find.byKey(_kTarget));
      expect(state.count, 3);
    });

    testWidgets('a bent inner screen takes no input', (tester) async {
      await tester.pumpWidget(
        foldableApp(
          _foldable(CoreMockupFold.halfOpen, child: const _Counter()),
        ),
      );
      final state = tester.state<_CounterState>(find.byType(_Counter));

      // Where the target is laid out, under the still …
      await tester.tap(find.byKey(_kTarget), warnIfMissed: false);
      // … and all across the stage, where the still shows it.
      final stage = stageOf(tester);
      for (var x = 20.0; x < stage.size.width; x += 40) {
        await tester.tapAt(
          stage.localToGlobal(Offset(x, stage.size.height / 2)),
        );
      }

      expect(state.count, 0);
    });
  });

  group('MockupFoldable — the fold the content is told about', () {
    Future<CoreFoldLayout> foldAt(
      WidgetTester tester,
      double angle, {
      List<ui.DisplayFeature> hostFolds = const [],
    }) async {
      late CoreFoldLayout seen;
      await tester.pumpWidget(
        foldableApp(
          _foldable(angle, child: _FoldProbe((fold) => seen = fold)),
          hostFolds: hostFolds,
        ),
      );

      return seen;
    }

    // What the Core rules state for a foldable this wide — the statement the
    // Web twin makes too.
    final layout = defaultFoldableLayout();

    void expectSameFold(CoreFoldLayout seen, CoreFoldLayout stated) {
      expect(seen.width, closeTo(stated.width, 1e-9));
      expect(seen.height, closeTo(stated.height, 1e-9));
      expect(seen.folds.length, stated.folds.length);
      for (var i = 0; i < stated.folds.length; i++) {
        expect(seen.folds[i].state, stated.folds[i].state);
        expect(
          seen.folds[i].bounds.left,
          closeTo(stated.folds[i].bounds.left, 1e-9),
        );
        expect(seen.folds[i].bounds.width, stated.folds[i].bounds.width);
        expect(
          seen.folds[i].bounds.height,
          closeTo(stated.folds[i].bounds.height, 1e-9),
        );
      }
      expect(seen.isSplit, stated.isSplit);
      expect(seen.posture, stated.posture);
      expect(seen.kind, stated.kind);
    }

    testWidgets('flat: one fold down the middle that does not split the '
        'screen', (tester) async {
      final seen = await foldAt(tester, CoreMockupFold.flat);

      expect(seen.fold, isNotNull);
      expect(seen.fold!.state, CoreFoldState.flat);
      expect(seen.fold!.bounds.left, closeTo(seen.width / 2, 1e-9));
      expect(seen.isSplit, isFalse);
      expect(seen.segments, hasLength(1));
      expect(seen.posture, CoreFoldPosture.flat);
      expectSameFold(seen, layout.foldLayoutAt(CoreMockupFold.flat));
    });

    testWidgets('half open: the fold splits the screen into two segments, '
        'held like a book', (tester) async {
      final seen = await foldAt(tester, CoreMockupFold.halfOpen);

      expect(seen.fold!.state, CoreFoldState.halfOpened);
      expect(seen.isSplit, isTrue);
      expect(seen.segments, hasLength(2));
      expect(seen.segments.first.width, closeTo(seen.width / 2, 1e-9));
      expect(seen.posture, CoreFoldPosture.book);
      expectSameFold(seen, layout.foldLayoutAt(CoreMockupFold.halfOpen));
    });

    testWidgets('shut: the cover has no fold', (tester) async {
      final seen = await foldAt(tester, CoreMockupFold.closed);

      expect(seen.folds, isEmpty);
      expect(seen.isSplit, isFalse);
      expectSameFold(seen, layout.foldLayoutAt(CoreMockupFold.closed));
      // The cover is the narrower screen.
      expect(
        seen.width,
        lessThan(layout.foldLayoutAt(CoreMockupFold.flat).width / 2),
      );
    });

    testWidgets('a fold of the page the mockup stands on is not a fold of '
        'its screen', (tester) async {
      const pageHinge = ui.DisplayFeature(
        bounds: Rect.fromLTWH(390, 0, 20, 600),
        type: ui.DisplayFeatureType.hinge,
        state: ui.DisplayFeatureState.postureHalfOpened,
      );

      final onCover = await foldAt(
        tester,
        CoreMockupFold.closed,
        hostFolds: const [pageHinge],
      );
      expect(onCover.folds, isEmpty);

      final onInner = await foldAt(
        tester,
        CoreMockupFold.flat,
        hostFolds: const [pageHinge],
      );
      expect(onInner.folds, hasLength(1));
      expect(onInner.fold!.bounds.width, 0);
      expect(onInner.fold!.state, CoreFoldState.flat);
    });

    testWidgets('the content is told as the device crosses from flat to '
        'half opened', (tester) async {
      final seen = await foldAt(tester, CoreMockupFold.flatFrom);
      expect(seen.fold!.state, CoreFoldState.flat);

      final below = await foldAt(tester, CoreMockupFold.flatFrom - 1);
      expect(below.fold!.state, CoreFoldState.halfOpened);
    });
  });

  group('MockupFoldable — getting to a new angle', () {
    testWidgets('a change of angle is a move through the angles between, '
        'for the style duration on the style curve', (tester) async {
      Widget at(double angle) => foldableApp(
        MockupFoldable(foldAngle: angle, child: const SizedBox.expand()),
      );
      final curve = CoreMockupFoldableStyle.defaultCurve.toValue();
      const duration = CoreMockupFoldableStyle.defaultDuration;

      await tester.pumpWidget(at(CoreMockupFold.flat));
      await tester.pumpWidget(at(CoreMockupFold.closed));
      // The move starts on the frame after the one that asked for it.
      await tester.pump();
      expect(_innerIsStill(tester), isFalse, reason: 'still flat at the start');

      await tester.pump(duration ~/ 2);
      final halfway =
          CoreMockupFold.flat +
          (CoreMockupFold.closed - CoreMockupFold.flat) * curve.transform(0.5);
      expect(halfway, inExclusiveRange(60, 120));
      final pose = _poseAt(tester, halfway);
      expect(pose.edgeLeft.visible, isTrue);
      expect(
        _matrixOf(tester, kEdgeLeftPart),
        matrixMoreOrLessEquals(Matrix4.fromList(pose.edgeLeft.matrix)),
      );
      expect(_innerIsStill(tester), isTrue);
      expect(tester.binding.hasScheduledFrame, isTrue);

      // The whole duration on: the device is shut, and the move is over one
      // frame later.
      await tester.pump(duration ~/ 2);
      final shut = Matrix4.fromList(
        _poseAt(tester, CoreMockupFold.closed).cover.matrix,
      );
      expect(_matrixOf(tester, kCoverPart), matrixMoreOrLessEquals(shut));
      await tester.pump(_kTick);
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_matrixOf(tester, kCoverPart), matrixMoreOrLessEquals(shut));
    });

    testWidgets('a new angle asked for on the way is headed for from where '
        'the device is', (tester) async {
      Widget at(double angle) => foldableApp(
        MockupFoldable(foldAngle: angle, child: const SizedBox.expand()),
      );
      const duration = CoreMockupFoldableStyle.defaultDuration;

      await tester.pumpWidget(at(CoreMockupFold.flat));
      await tester.pumpWidget(at(CoreMockupFold.closed));
      await tester.pump();
      await tester.pump(duration ~/ 2);
      final turnedAt = _matrixOf(tester, kEdgeLeftPart).clone();

      // Back to flat from halfway: the first frame of the new move is where
      // the old one was.
      await tester.pumpWidget(at(CoreMockupFold.flat));
      await tester.pump();
      expect(
        _matrixOf(tester, kEdgeLeftPart),
        matrixMoreOrLessEquals(turnedAt),
      );

      await tester.pumpAndSettle();
      expect(_innerIsStill(tester), isFalse);
      expect(find.byKey(kCoverPart), findsNothing);
    });

    testWidgets('with no duration the device is at the new angle at once', (
      tester,
    ) async {
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.flat)));
      await tester.pumpWidget(foldableApp(_foldable(CoreMockupFold.closed)));

      // In the frame that asked: no move to wait for.
      expect(
        _matrixOf(tester, kCoverPart),
        matrixMoreOrLessEquals(
          Matrix4.fromList(_poseAt(tester, CoreMockupFold.closed).cover.matrix),
        ),
      );
      expect(tester.binding.transientCallbackCount, 0);
      // One frame more is the focus tree taking in that the inner screen no
      // longer takes focus; after it nothing is left to draw.
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('under reduced motion the device is at the new angle at '
        'once', (tester) async {
      Widget at(double angle) => foldableApp(
        MockupFoldable(foldAngle: angle, child: const SizedBox.expand()),
        reducedMotion: true,
      );

      await tester.pumpWidget(at(CoreMockupFold.flat));
      await tester.pumpWidget(at(CoreMockupFold.closed));

      // In the frame that asked: no move to wait for.
      expect(
        _matrixOf(tester, kCoverPart),
        matrixMoreOrLessEquals(
          Matrix4.fromList(_poseAt(tester, CoreMockupFold.closed).cover.matrix),
        ),
      );
      expect(tester.binding.transientCallbackCount, 0);
      // One frame more is the focus tree taking in that the inner screen no
      // longer takes focus; after it nothing is left to draw.
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('an angle past either end is that end', (tester) async {
      await tester.pumpWidget(foldableApp(_foldable(400)));
      expect(_innerIsStill(tester), isFalse);
      expect(find.byKey(kCoverPart), findsNothing);

      await tester.pumpWidget(foldableApp(_foldable(-40)));
      expect(
        _matrixOf(tester, kCoverPart),
        matrixMoreOrLessEquals(
          Matrix4.fromList(_poseAt(tester, CoreMockupFold.closed).cover.matrix),
        ),
      );
    });

    testWidgets('open flat is the default', (tester) async {
      await tester.pumpWidget(
        foldableApp(const MockupFoldable(child: SizedBox.expand())),
      );

      expect(
        tester.widget<MockupFoldable>(find.byType(MockupFoldable)).foldAngle,
        CoreMockupFold.flat,
      );
      expect(_innerIsStill(tester), isFalse);
      expect(find.byKey(kCoverPart), findsNothing);
    });
  });

  group('MockupFoldable — assistive technology', () {
    testWidgets('reads the content on a flat inner screen and on the cover, '
        'and not on a bent screen', (tester) async {
      final handle = tester.ensureSemantics();
      const cases = [
        (CoreMockupFold.flat, true),
        (CoreMockupFold.halfOpen, false),
        (CoreMockupFold.coverUntil + 1, false),
        (CoreMockupFold.closed, true),
      ];
      for (final (angle, exposed) in cases) {
        await tester.pumpWidget(
          foldableApp(
            _foldable(
              angle,
              child: Semantics(
                label: 'home screen',
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.semantics.byLabel('home screen'),
          exposed ? findsOne : findsNothing,
          reason: '$angle°',
        );
        // The status island is drawn for the eye alone, whatever the angle.
        expect(find.text('9:41'), findsWidgets, reason: '$angle°');
        expect(find.semantics.byLabel('9:41'), findsNothing, reason: '$angle°');
      }
      handle.dispose();
    });
  });

  group('MockupFoldable — style', () {
    const red = Color(0xFFFF0000);
    const blue = Color(0xFF0000FF);

    Color edgeColor(WidgetTester tester) {
      Color? painted;
      expect(
        edgeBox(kEdgeRightPart),
        paints..everything((method, arguments) {
          if (method == #drawRRect) {
            painted = (arguments.last as Paint).color;
          }

          return true;
        }),
      );

      return painted!;
    }

    testWidgets('the project theme and the instance both reach the device, '
        'the instance last', (tester) async {
      const theme = CoreComponentTheme(
        mockupFoldable: CoreMockupFoldableTheme(
          style: CoreMockupFoldableStyle(
            thickness: 20,
            edgeColor: CoreColor(0xFFFF0000),
            duration: Duration.zero,
          ),
        ),
      );

      await tester.pumpWidget(
        foldableApp(
          const MockupFoldable(
            foldAngle: CoreMockupFold.halfOpen,
            child: SizedBox.expand(),
          ),
          componentTheme: theme,
        ),
      );
      expect(tester.getSize(edgeBox(kEdgeRightPart)).width, 20);
      expect(edgeColor(tester), red);

      await tester.pumpWidget(
        foldableApp(
          const MockupFoldable(
            foldAngle: CoreMockupFold.halfOpen,
            mockupFoldableStyle: CoreMockupFoldableStyle(
              thickness: 8,
              edgeColor: CoreColor(0xFF0000FF),
            ),
            child: SizedBox.expand(),
          ),
          componentTheme: theme,
        ),
      );
      expect(tester.getSize(edgeBox(kEdgeRightPart)).width, 8);
      expect(edgeColor(tester), blue);
    });

    testWidgets('a nested device style reaches the face it is for', (
      tester,
    ) async {
      Finder screenOf(CoreMockupDevice device, Color color) => find.descendant(
        of: faceOf(device),
        matching: find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == color,
        ),
      );

      await tester.pumpWidget(
        foldableApp(
          const MockupFoldable(
            foldAngle: CoreMockupFold.closed,
            mockupFoldableStyle: CoreMockupFoldableStyle(
              innerDeviceStyle: CoreMockupDeviceStyle(
                backgroundColor: CoreColor(0xFFFF0000),
              ),
              coverDeviceStyle: CoreMockupDeviceStyle(
                backgroundColor: CoreColor(0xFF0000FF),
              ),
              duration: Duration.zero,
            ),
            child: SizedBox.expand(),
          ),
        ),
      );

      expect(screenOf(CoreMockupDevice.phone, blue), findsOneWidget);
      expect(screenOf(CoreMockupDevice.tablet, red), findsOneWidget);
      expect(screenOf(CoreMockupDevice.phone, red), findsNothing);
    });

    testWidgets('the status the caller turns off is off on both faces', (
      tester,
    ) async {
      await tester.pumpWidget(
        foldableApp(
          const MockupFoldable(
            foldAngle: CoreMockupFold.closed,
            showStatus: false,
            mockupFoldableStyle: kAtOnce,
            child: SizedBox.expand(),
          ),
        ),
      );

      expect(find.text('9:41'), findsNothing);
    });

    test('the flags default to those of the contract, and copyWith keeps the '
        'ones it is not given', () {
      const foldable = MockupFoldable(child: SizedBox());

      expect(foldable.showCamera, CoreMockupFoldableContract.defaultShowCamera);
      expect(foldable.showStatus, CoreMockupFoldableContract.defaultShowStatus);
      expect(
        foldable.showGestureBar,
        CoreMockupFoldableContract.defaultShowGestureBar,
      );
      // The device shows its camera and its status, and no gesture bar.
      expect(foldable.showCamera, isTrue);
      expect(foldable.showStatus, isTrue);
      expect(foldable.showGestureBar, isFalse);

      final changed = foldable.copyWith(
        showStatus: false,
        showGestureBar: true,
      );
      expect(changed.showCamera, isTrue);
      expect(changed.showStatus, isFalse);
      expect(changed.showGestureBar, isTrue);
      expect(changed.copyWith(showCamera: false).showGestureBar, isTrue);
    });

    test('withStyle merges a patch into the style, the later patch last', () {
      final foldable = const MockupFoldable(child: SizedBox())
          .withStyle(const CoreMockupFoldableStyle(thickness: 20))
          .withStyle(
            const CoreMockupFoldableStyle(thickness: 8, perspective: 3),
          );

      expect(foldable.mockupFoldableStyle!.thickness, 8);
      expect(foldable.mockupFoldableStyle!.perspective, 3);
      expect(foldable.foldAngle, CoreMockupFold.flat);
    });
  });
}
