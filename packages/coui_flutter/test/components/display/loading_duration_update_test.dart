import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  _zeroDurationCoverage();
  for (final variant in CoreLoadingVariant.values) {
    testWidgets('$variant applies a new duration to the running animation', (
      tester,
    ) async {
      final duration = ValueNotifier(const Duration(milliseconds: 1000));
      addTearDown(duration.dispose);
      await pumpTestApp(
        tester,
        ValueListenableBuilder<Duration>(
          valueListenable: duration,
          builder: (context, value, child) => Loading(
            variant: variant,
            loadingStyle: CoreLoadingStyle(duration: value),
          ),
        ),
      );
      await tester.pump();
      final animation =
          tester
                  .widget<AnimatedBuilder>(
                    find.descendant(
                      of: find.byType(Loading),
                      matching: find.byType(AnimatedBuilder),
                    ),
                  )
                  .animation
              as Animation<double>;
      await tester.pump(const Duration(milliseconds: 250));
      expect(animation.value, closeTo(.25, .000001));

      duration.value = const Duration(milliseconds: 2000);
      await tester.pump();
      expect(animation.value, closeTo(.25, .000001));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        animation.value,
        closeTo(.375, .000001),
        reason: '250ms must advance one eighth of the new 2s cycle',
      );

      duration.value = const Duration(milliseconds: 400);
      await tester.pump();
      expect(animation.value, closeTo(.375, .000001));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        animation.value,
        closeTo(.625, .000001),
        reason: '100ms must advance one quarter of the new 400ms cycle',
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(animation.value, closeTo(.125, .000001));
    });
  }
}

AnimationController _controller(WidgetTester tester) =>
    tester
            .widget<AnimatedBuilder>(
              find.descendant(
                of: find.byType(Loading),
                matching: find.byType(AnimatedBuilder),
              ),
            )
            .animation
        as AnimationController;

Future<Uint8List> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
}

Future<void> _expectResting(
  WidgetTester tester,
  AnimationController controller,
  GlobalKey boundary,
) async {
  expect(tester.takeException(), isNull);
  expect(controller.isAnimating, isFalse);
  expect(controller.value, 0);
  final loading = tester.widget<Loading>(find.byType(Loading));
  final opacities = tester.widgetList<Opacity>(
    find.descendant(of: find.byType(Loading), matching: find.byType(Opacity)),
  );
  switch (loading.variant) {
    case CoreLoadingVariant.dots:
      expect(opacities.map((widget) => widget.opacity), [1, 1, 1]);
    case CoreLoadingVariant.pulse:
      expect(opacities.single.opacity, CoreLoadingStyle.defaultPulseHaloAlpha);
      final transform = tester
          .widget<Transform>(
            find.descendant(
              of: find.byType(Loading),
              matching: find.byType(Transform),
            ),
          )
          .transform;
      expect(transform.storage[0], 1);
      expect(transform.storage[5], 1);
    case CoreLoadingVariant.bar:
      final transform = tester
          .widget<Transform>(
            find.descendant(
              of: find.byType(Loading),
              matching: find.byType(Transform),
            ),
          )
          .transform;
      expect(transform.storage[12], 0);
    case CoreLoadingVariant.spinner:
      break;
  }
  final first = await _pixels(tester, boundary);
  await tester.pump(const Duration(milliseconds: 625));
  expect(controller.value, 0);
  expect(await _pixels(tester, boundary), orderedEquals(first));
  expect(tester.binding.hasScheduledFrame, isFalse);
}

void _zeroDurationCoverage() {
  for (final variant in CoreLoadingVariant.values) {
    testWidgets(
      '$variant handles explicit zero and repeated duration changes',
      (
        tester,
      ) async {
        final duration = ValueNotifier(Duration.zero);
        addTearDown(duration.dispose);
        final boundary = GlobalKey();
        await pumpTestApp(
          tester,
          RepaintBoundary(
            key: boundary,
            child: ValueListenableBuilder<Duration>(
              valueListenable: duration,
              builder: (context, value, child) => Loading(
                variant: variant,
                loadingStyle: CoreLoadingStyle(duration: value),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final controller = _controller(tester);
        await _expectResting(tester, controller, boundary);
        for (var i = 0; i < 3; i++) {
          duration.value = const Duration(milliseconds: 400);
          await tester.pump();
          expect(controller.isAnimating, isTrue);
          await tester.pump(const Duration(milliseconds: 100));
          expect(controller.value, closeTo(.25, .000001));
          duration.value = Duration.zero;
          await tester.pump();
          await _expectResting(tester, controller, boundary);
        }
        duration.value = const Duration(milliseconds: 400);
        await tester.pump();
        expect(controller.isAnimating, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets(
      '$variant starts at rest when reduced motion zeroes its period',
      (
        tester,
      ) async {
        final boundary = GlobalKey();
        await pumpTestApp(
          tester,
          RepaintBoundary(
            key: boundary,
            child: Loading(
              variant: variant,
              loadingStyle: const CoreLoadingStyle(
                duration: Duration(milliseconds: 400),
              ),
            ),
          ),
          disableAnimations: true,
        );
        expect(tester.takeException(), isNull);
        await _expectResting(tester, _controller(tester), boundary);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('$variant stops and resumes as reduced motion changes live', (
      tester,
    ) async {
      final reduce = ValueNotifier(false);
      addTearDown(reduce.dispose);
      final boundary = GlobalKey();
      await pumpTestApp(
        tester,
        RepaintBoundary(
          key: boundary,
          child: ValueListenableBuilder<bool>(
            valueListenable: reduce,
            builder: (context, value, child) => MediaQuery(
              data: MediaQueryData(disableAnimations: value),
              child: Loading(
                variant: variant,
                loadingStyle: const CoreLoadingStyle(
                  duration: Duration(milliseconds: 400),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final controller = _controller(tester);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(controller.value, closeTo(.25, .000001));
        reduce.value = true;
        await tester.pump();
        await _expectResting(tester, controller, boundary);
        reduce.value = false;
        await tester.pump();
        expect(controller.isAnimating, isTrue);
      }
      reduce.value = true;
      await tester.pump();
      await _expectResting(tester, controller, boundary);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('$variant retains its display period under reduced motion', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Loading(variant: variant),
        disableAnimations: true,
      );
      await tester.pump();
      final controller = _controller(tester);
      expect(controller.isAnimating, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.value, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }
}
