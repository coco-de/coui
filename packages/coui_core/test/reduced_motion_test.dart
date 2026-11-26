import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreReducedMotion — off', () {
    test('leaves every duration untouched', () {
      for (final ms in [0, 1, 100, 150, 200, 300, 500, 1000, 1500, 5000]) {
        final d = Duration(milliseconds: ms);
        expect(CoreReducedMotion.resolve(d, reduce: false), equals(d));
      }
    });
  });

  group('CoreReducedMotion — on', () {
    test('suppresses every duration alias', () {
      // The aliases are the vocabulary component transitions are written in,
      // so they are exactly what the preference is about.
      for (final ms in [
        CoreDuration.instant,
        CoreDuration.fast,
        CoreDuration.normal,
        CoreDuration.moderate,
        CoreDuration.slow,
      ]) {
        expect(
          CoreReducedMotion.resolve(
            Duration(milliseconds: ms),
            reduce: true,
          ),
          equals(Duration.zero),
          reason: '${ms}ms is transition motion and should collapse.',
        );
      }
    });

    test('suppresses transition-tier values that have no alias', () {
      // Not every transition duration got an alias, but they are all still
      // transitions — the tier decides, not whether someone named it.
      for (final ms in [
        CoreDuration.ms50,
        CoreDuration.ms250,
        CoreDuration.ms350,
        CoreDuration.ms400,
        CoreDuration.ms450,
      ]) {
        expect(
          CoreReducedMotion.resolve(Duration(milliseconds: ms), reduce: true),
          equals(Duration.zero),
        );
      }
    });

    test('preserves display-tier durations', () {
      // A spinner that stops spinning no longer says "still working", and a
      // progress bar that freezes reads as a hang. Suppressing these would
      // trade one accessibility failure for another.
      for (final ms in [
        CoreDuration.ms1000,
        CoreDuration.indeterminate,
        CoreDuration.ms3000,
        CoreDuration.ms5000,
      ]) {
        final d = Duration(milliseconds: ms);
        expect(
          CoreReducedMotion.resolve(d, reduce: true),
          equals(d),
          reason: '${ms}ms is display timing, not motion.',
        );
      }
    });

    test('the tier boundary is exactly ms500 / ms1000', () {
      expect(
        CoreReducedMotion.resolve(
          const Duration(milliseconds: CoreDuration.ms500),
          reduce: true,
        ),
        equals(Duration.zero),
      );
      expect(
        CoreReducedMotion.resolve(
          const Duration(milliseconds: CoreDuration.ms1000),
          reduce: true,
        ),
        equals(const Duration(milliseconds: CoreDuration.ms1000)),
      );
      expect(
        CoreReducedMotion.transitionCeilingMs,
        equals(CoreDuration.ms500),
      );
    });

    test('zero stays zero', () {
      // A caller that already opted out of animating should not depend on
      // whether the preference is set.
      expect(
        CoreReducedMotion.resolve(Duration.zero, reduce: true),
        equals(Duration.zero),
      );
    });

    test('negative durations are left alone', () {
      const d = Duration(milliseconds: -100);
      expect(CoreReducedMotion.resolve(d, reduce: true), equals(d));
    });
  });

  group('CoreReducedMotion.isTransitionMotion', () {
    test('classifies the tiers', () {
      expect(
        CoreReducedMotion.isTransitionMotion(
          const Duration(milliseconds: CoreDuration.fast),
        ),
        isTrue,
      );
      expect(
        CoreReducedMotion.isTransitionMotion(
          const Duration(milliseconds: CoreDuration.indeterminate),
        ),
        isFalse,
      );
      expect(CoreReducedMotion.isTransitionMotion(Duration.zero), isFalse);
    });

    test('agrees with resolve', () {
      for (final ms in [0, 50, 150, 500, 501, 1000, 1500, 5000]) {
        final d = Duration(milliseconds: ms);
        final suppressed = CoreReducedMotion.resolve(d, reduce: true) != d;
        expect(
          suppressed,
          equals(CoreReducedMotion.isTransitionMotion(d)),
          reason:
              'isTransitionMotion must describe exactly what resolve does '
              'to ${ms}ms, or docs and behaviour drift apart.',
        );
      }
    });
  });
}
