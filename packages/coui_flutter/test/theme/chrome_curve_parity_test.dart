// Chrome changes shape the same way on both platforms.
//
// Flutter's implicitly-animated widgets default to `Curves.linear`. The
// kit's CSS transitions do not — they are emitted with `CoreEasing.move`,
// which is ease-in-out. Same duration, different shape: the two panes
// start and finish together and disagree in between.
//
// That is invisible on either platform alone, and it lasted because
// nothing looks wrong until the two are side by side. Measured: 52 of the
// kit's 76 implicit animations ran linear, and every suite was green.
//
// `check_implicit_animation_curve.sh` counts the call sites. This reads
// the curve back off a resolved value, which is the half a grep cannot do
// — a site can name a curve and name the wrong one.
import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether two curves describe the same motion.
///
/// Sampled rather than compared, because `Cubic` inherits identity
/// equality — two `Cubic(0.42, 0, 0.58, 1)` built a line apart are not
/// `==`, and a test that compared them directly failed while printing two
/// identical values.
bool _sameShape(Curve a, Curve b) {
  for (var i = 0; i <= 20; i++) {
    if ((a.transform(i / 20) - b.transform(i / 20)).abs() > 1e-6) return false;
  }

  return true;
}

void main() {
  group('the resolved chrome curve is the shared alias', () {
    testWidgets('the surface every other surface composes states it', (
      tester,
    ) async {
      late ResolvedOutlinedContainer resolved;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Builder(
            builder: (context) {
              resolved = resolveOutlinedContainer(context);

              return const SizedBox();
            },
          ),
        ),
      );

      expect(_sameShape(resolved.curve, CoreEasing.move.toValue()), isTrue);
      expect(
        _sameShape(resolved.curve, Curves.linear),
        isFalse,
        reason: 'the framework default is what this exists to replace',
      );
    });

    test('and the alias really is a curve, not the identity', () {
      // Guards the assertion above against a vocabulary change that made
      // `move` linear — the test would keep passing while every animation
      // in the kit went back to sliding at a constant rate.
      final curve = CoreEasing.move.toValue();

      // Sampled at a quarter, not at the midpoint. An ease-in-out curve is
      // symmetric, so the midpoint is the one place it agrees with linear
      // exactly — asserting there passes for both and proves nothing. It
      // was written that way first, and it failed against a correct curve.
      expect(curve.transform(0.25), lessThan(0.25 - 1e-3));
      expect(curve.transform(0.75), greaterThan(0.75 + 1e-3));
      expect(curve.transform(0), closeTo(0, 1e-6));
      expect(curve.transform(1), closeTo(1, 1e-6));
    });
  });

  group('and it reaches the widget that animates', () {
    testWidgets('the surface hands it to both of its animated boxes', (
      tester,
    ) async {
      // Reading the resolver proves the value exists; this proves it was
      // passed. The two are different failures and only one of them is
      // visible on screen.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
        ),
      );

      final boxes = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();

      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        expect(
          _sameShape(box.curve, Curves.linear),
          isFalse,
          reason: 'an animated box left on the framework default',
        );
      }
    });
  });
}
