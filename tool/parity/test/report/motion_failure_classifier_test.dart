import 'package:test/test.dart';

import '../../src/report/failure_category.dart';
import '../../src/report/motion_failure_classifier.dart';

void main() {
  group('classifyMotionFailure', () {
    test(
      'expectDurationWithinTransitionTierTokens message -> motion-timing',
      () {
        final category = classifyMotionFailure(
          'Duration: 137ms is not one of the CoreDuration transition-tier '
          'primitives ({0, 50, 100, ...}) — looks like a raw literal rather '
          'than a token reference.',
        );

        expect(category, FailureCategory.motionTiming);
      },
    );

    test(
      'expectTransitionDurationMatchesToken message -> motion-timing',
      () {
        final category = classifyMotionFailure(
          'Element: transition duration for "opacity" is 300ms, expected '
          '150ms (a CoreDuration token) — computed contract is X.',
        );

        expect(category, FailureCategory.motionTiming);
      },
    );

    test('expectNoImmediateFinalValueJump message -> motion-missing', () {
      final category = classifyMotionFailure(
        'Dialog jumped straight from 0.0 to 1.0 with no intermediate frame '
        'in between — looks like it settled instantly instead of '
        'animating. Samples: [0ms=0.0, 200ms=1.0]',
      );

      expect(category, FailureCategory.motionMissing);
    });

    test('expectMonotonicProgression message -> motion-missing', () {
      final category = classifyMotionFailure(
        'Animation regressed at t=100ms: 0.4 < previous 0.6 (expected '
        'non-decreasing toward 1.0). Samples: [...]',
      );

      expect(category, FailureCategory.motionMissing);
    });

    test('expectTransitionDeclaredForProperty message -> motion-missing', () {
      final category = classifyMotionFailure(
        'Element: no transition declared for "opacity" — computed contract '
        'is ComputedTransitionContract(properties: [none], ...).',
      );

      expect(category, FailureCategory.motionMissing);
    });

    test('unrecognized message defaults to motion-missing', () {
      final category = classifyMotionFailure(
        'Expected: <true>\nActual: <false>\n',
      );

      expect(category, FailureCategory.motionMissing);
    });
  });
}
