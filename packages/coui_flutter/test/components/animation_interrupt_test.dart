import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'a live reduced-motion change completes once and keeps children',
    (
      tester,
    ) async {
      var reduced = false;
      var target = 1.0;
      var observed = -1.0;
      final completed = <double>[];
      late StateSetter update;
      final childKey = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child: AnimatedValueBuilder<double>(
                  initialValue: 0,
                  value: target,
                  duration: const Duration(milliseconds: 300),
                  onEnd: completed.add,
                  child: SizedBox(key: childKey),
                  builder: (context, value, child) {
                    observed = value;
                    return child!;
                  },
                ),
              );
            },
          ),
        ),
      );
      final childElement = childKey.currentContext;
      await tester.pump(const Duration(milliseconds: 100));
      expect(observed, inExclusiveRange(0, 1));
      update(() => reduced = true);
      await tester.pump();
      expect(observed, 1);
      expect(completed, [1]);
      expect(tester.hasRunningAnimations, isFalse);
      expect(childKey.currentContext, same(childElement));
      update(() => target = 2);
      await tester.pump();
      expect(observed, 2);
      expect(completed, [1, 2]);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'curve changes preserve completion and retarget from visible value',
    (
      tester,
    ) async {
      Curve curve = Curves.linear;
      var target = 1.0;
      var observed = 0.0;
      final completed = <double>[];
      late StateSetter update;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return AnimatedValueBuilder<double>(
              initialValue: 0,
              value: target,
              duration: const Duration(milliseconds: 200),
              curve: curve,
              onEnd: completed.add,
              builder: (context, value, child) {
                observed = value;
                return const SizedBox();
              },
            );
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      final before = observed;
      update(() {
        curve = Curves.easeOut;
        target = 2;
      });
      await tester.pump();
      expect(observed, closeTo(before, .001));
      await tester.pumpAndSettle();
      expect(observed, 2);
      expect(completed, [2]);
    },
  );

  testWidgets('a changed interpolator starts from the last painted value', (
    tester,
  ) async {
    double linear(double a, double b, double t) => a + (b - a) * t;
    double quadratic(double a, double b, double t) => a + (b - a) * t * t;
    var interpolate = linear;
    var observed = 0.0;
    late StateSetter update;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return AnimatedValueBuilder<double>(
            initialValue: 0,
            value: 1,
            duration: const Duration(milliseconds: 200),
            lerp: interpolate,
            builder: (context, value, child) {
              observed = value;
              return const SizedBox();
            },
          );
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(observed, closeTo(.4, .001));
    update(() => interpolate = quadratic);
    await tester.pump();
    expect(observed, closeTo(.4, .001));
    await tester.pumpAndSettle();
    expect(observed, 1);
  });

  testWidgets('raw interpolation does not restart on an unrelated rebuild', (
    tester,
  ) async {
    var observed = 0.0;
    late StateSetter update;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return AnimatedValueBuilder<double>.raw(
            initialValue: 0,
            value: 1,
            duration: const Duration(milliseconds: 200),
            builder: (context, from, to, progress, child) {
              observed = from + (to - from) * progress;
              return const SizedBox();
            },
          );
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(observed, closeTo(.5, .001));
    update(() {});
    await tester.pump();
    expect(observed, closeTo(.5, .001));
    await tester.pumpAndSettle();
    expect(observed, 1);
  });

  testWidgets(
    'reduced motion preserves display timing above the transition tier',
    (
      tester,
    ) async {
      var observed = 0.0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: AnimatedValueBuilder<double>(
            initialValue: 0,
            value: 1,
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              observed = value;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(observed, 0);
      await tester.pumpAndSettle();
      expect(observed, 1);
    },
  );
}
