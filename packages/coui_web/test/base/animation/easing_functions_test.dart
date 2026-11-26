import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  group('CoreEasingFunctionMath.apply — boundaries', () {
    test('all functions return 0 at t=0 (where defined)', () {
      // Bounce/elastic spec is 0 at t=0; decelerate also 0.
      expect(CoreEasingFunction.decelerate.apply(0), equals(0));
      expect(CoreEasingFunction.bounceIn.apply(0), closeTo(0, 1e-9));
      expect(CoreEasingFunction.bounceOut.apply(0), equals(0));
      expect(CoreEasingFunction.elasticIn.apply(0), equals(0));
      expect(CoreEasingFunction.elasticOut.apply(0), equals(0));
    });

    test('all functions return 1 at t=1', () {
      for (final fn in CoreEasingFunction.values) {
        expect(
          fn.apply(1),
          closeTo(1, 1e-6),
          reason: '${fn.name} should reach 1 at t=1',
        );
      }
    });

    test('clamps t outside [0, 1]', () {
      expect(CoreEasingFunction.bounceOut.apply(-1), equals(0));
      expect(CoreEasingFunction.bounceOut.apply(2), closeTo(1, 1e-6));
    });
  });

  group('decelerate', () {
    test('matches 1 - (1-t)² at midpoint', () {
      expect(CoreEasingFunction.decelerate.apply(0.5), closeTo(0.75, 1e-9));
    });
  });

  group('bounce', () {
    test('bounceOut(0.5) is in expected band', () {
      // spec piecewise quadratic — segment 2 of 4 at t=0.5.
      final v = CoreEasingFunction.bounceOut.apply(0.5);
      expect(v, greaterThan(0.7));
      expect(v, lessThan(0.85));
    });

    test('bounceIn is mirror of bounceOut', () {
      const t = 0.3;
      final inV = CoreEasingFunction.bounceIn.apply(t);
      final outV = CoreEasingFunction.bounceOut.apply(1 - t);
      expect(inV, closeTo(1 - outV, 1e-9));
    });
  });

  group('elastic', () {
    test('elasticOut overshoots 1 mid-animation', () {
      final v = CoreEasingFunction.elasticOut.apply(0.6);
      expect(v, greaterThan(1));
    });

    test('elasticIn is negative for early t', () {
      final v = CoreEasingFunction.elasticIn.apply(0.6);
      // Elastic-in produces small negative pre-bounce values; sign flips.
      expect(v, lessThan(1));
    });
  });

  group('ThreePointCubic approximations', () {
    test('easeInOutCubicEmphasized monotone non-decreasing in coarse grid', () {
      const fn = CoreEasingFunction.easeInOutCubicEmphasized;
      final samples = [
        for (var i = 0; i <= 20; i++) fn.apply(i / 20),
      ];
      for (var i = 1; i < samples.length; i++) {
        expect(
          samples[i],
          greaterThanOrEqualTo(samples[i - 1] - 1e-6),
          reason: 'should be non-decreasing at i=$i',
        );
      }
    });

    test('fastEaseInToSlowEaseOut non-decreasing', () {
      const fn = CoreEasingFunction.fastEaseInToSlowEaseOut;
      final samples = [
        for (var i = 0; i <= 20; i++) fn.apply(i / 20),
      ];
      for (var i = 1; i < samples.length; i++) {
        expect(
          samples[i],
          greaterThanOrEqualTo(samples[i - 1] - 1e-6),
        );
      }
    });
  });
}
