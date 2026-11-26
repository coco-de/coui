import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreEasing — CSS standard (5)', () {
    test('linear (0,0,1,1)', () {
      expect(CoreEasing.linear.x1, equals(0));
      expect(CoreEasing.linear.y1, equals(0));
      expect(CoreEasing.linear.x2, equals(1));
      expect(CoreEasing.linear.y2, equals(1));
    });

    test('ease (0.25, 0.1, 0.25, 1)', () {
      expect(CoreEasing.ease.x1, equals(0.25));
      expect(CoreEasing.ease.y1, equals(0.1));
      expect(CoreEasing.ease.x2, equals(0.25));
      expect(CoreEasing.ease.y2, equals(1));
    });

    test('easeIn / easeOut / easeInOut have spec coordinates', () {
      expect(CoreEasing.easeIn, equals((x1: 0.42, y1: 0.0, x2: 1.0, y2: 1.0)));
      expect(
        CoreEasing.easeOut,
        equals((x1: 0.0, y1: 0.0, x2: 0.58, y2: 1.0)),
      );
      expect(
        CoreEasing.easeInOut,
        equals((x1: 0.42, y1: 0.0, x2: 0.58, y2: 1.0)),
      );
    });
  });

  group('CoreEasing — Flutter special', () {
    test('fastOutSlowIn matches Material Design standard', () {
      expect(
        CoreEasing.fastOutSlowIn,
        equals((x1: 0.4, y1: 0.0, x2: 0.2, y2: 1.0)),
      );
    });
  });

  group('CoreEasing — Back overshoot has negative/over-1 coords', () {
    test('easeInBack has negative y1', () {
      expect(CoreEasing.easeInBack.y1 < 0, isTrue);
    });

    test('easeOutBack has y2 > 1', () {
      expect(CoreEasing.easeOutBack.y2 > 1, isTrue);
    });

    test('easeInOutBack overshoots both ends', () {
      expect(CoreEasing.easeInOutBack.y1 < 0, isTrue);
      expect(CoreEasing.easeInOutBack.y2 > 1, isTrue);
    });
  });

  group('CoreEasing scale record (kebab-case)', () {
    test('CSS standard keys', () {
      expect(CoreEasing.scale.linear, equals('linear'));
      expect(CoreEasing.scale.easeIn, equals('ease-in'));
      expect(CoreEasing.scale.easeOut, equals('ease-out'));
      expect(CoreEasing.scale.easeInOut, equals('ease-in-out'));
    });

    test('Flutter special key (kebab-case)', () {
      expect(CoreEasing.scale.fastOutSlowIn, equals('fast-out-slow-in'));
    });
  });

  group('CoreEasingFunction enum (9 non-cubic-bezier)', () {
    test('contains exactly 9 functions', () {
      expect(CoreEasingFunction.values, hasLength(9));
    });

    test('includes bounce/elastic/decelerate/threePointCubic', () {
      expect(
        CoreEasingFunction.values,
        contains(CoreEasingFunction.decelerate),
      );
      expect(
        CoreEasingFunction.values,
        contains(CoreEasingFunction.bounceIn),
      );
      expect(
        CoreEasingFunction.values,
        contains(CoreEasingFunction.bounceOut),
      );
      expect(
        CoreEasingFunction.values,
        contains(CoreEasingFunction.bounceInOut),
      );
      expect(CoreEasingFunction.values, contains(CoreEasingFunction.elasticIn));
      expect(
        CoreEasingFunction.values,
        contains(CoreEasingFunction.elasticOut),
      );
      expect(
        CoreEasingFunction.values,
        contains(CoreEasingFunction.elasticInOut),
      );
      expect(
        CoreEasingFunction.values,
        contains(CoreEasingFunction.easeInOutCubicEmphasized),
      );
      expect(
        CoreEasingFunction.values,
        contains(CoreEasingFunction.fastEaseInToSlowEaseOut),
      );
    });
  });

  group('CoreEasing alias tier (semantic)', () {
    test('each alias is pinned to its raw curve', () {
      expect(CoreEasing.move, equals(CoreEasing.easeInOut));
      expect(CoreEasing.enter, equals(CoreEasing.easeOut));
      expect(CoreEasing.exit, equals(CoreEasing.easeIn));
      expect(CoreEasing.feedback, equals(CoreEasing.easeOutBack));
    });

    test('entering and exiting aliases are not the same curve', () {
      // The pair carries the whole point of the tier — something arriving
      // settles, something leaving does not. Collapsing them would make the
      // alias names decorative.
      expect(CoreEasing.enter, isNot(equals(CoreEasing.exit)));
    });

    test('spring overshoots past its endpoint', () {
      // An overshoot curve is exactly one whose second control point sits
      // beyond y = 1; that is what makes it read as tactile.
      expect(CoreEasing.feedback.y2, greaterThan(1));
    });

    test('linear serves as its own alias and stays unaccelerated', () {
      expect(CoreEasing.linear, equals((x1: 0.0, y1: 0.0, x2: 1.0, y2: 1.0)));
    });
  });

  group('CoreCubicBezierTransform — a curve read as a timing function', () {
    test('starts at nothing done and ends at everything done', () {
      for (final curve in [
        CoreEasing.linear,
        CoreEasing.easeOut,
        CoreEasing.easeInOut,
        CoreEasing.fastOutSlowIn,
        CoreEasing.easeOutBack,
      ]) {
        expect(curve.transform(0), 0);
        expect(curve.transform(1), 1);
      }
    });

    test('holds at the ends outside the duration', () {
      expect(CoreEasing.easeOut.transform(-0.5), 0);
      expect(CoreEasing.easeOut.transform(1.5), 1);
    });

    test('the straight line is the identity', () {
      for (var t = 0.0; t <= 1; t += 0.05) {
        expect(CoreEasing.linear.transform(t), closeTo(t, 1e-12));
      }
    });

    test("ease-out reads the browser's numbers", () {
      // cubic-bezier(0, 0, 0.58, 1), computed outside Dart.
      const samples = [
        (0.05, 0.082242204042017),
        (0.1, 0.160572154233753),
        (0.25, 0.378138130829510),
        (0.5, 0.684643187427461),
        (0.75, 0.906535349211890),
        (0.9, 0.982973390348437),
      ];
      for (final (t, progress) in samples) {
        expect(
          CoreEasing.easeOut.transform(t),
          closeTo(progress, 1e-9),
          reason: 't = $t',
        );
      }
    });

    test('ease-in-out is symmetric about the middle', () {
      expect(CoreEasing.easeInOut.transform(0.5), closeTo(0.5, 1e-12));
      for (final t in [0.1, 0.25, 0.4]) {
        expect(
          CoreEasing.easeInOut.transform(t) +
              CoreEasing.easeInOut.transform(1 - t),
          closeTo(1, 1e-9),
        );
      }
    });

    test('a decelerating curve is ahead of the clock, an accelerating one '
        'behind', () {
      for (final t in [0.1, 0.3, 0.5, 0.7, 0.9]) {
        expect(CoreEasing.easeOut.transform(t), greaterThan(t));
        expect(CoreEasing.easeIn.transform(t), lessThan(t));
      }
    });

    test('never goes backwards on a curve that does not overshoot', () {
      for (final curve in [
        CoreEasing.easeOut,
        CoreEasing.easeIn,
        CoreEasing.easeInOut,
        CoreEasing.fastOutSlowIn,
        CoreEasing.easeInOutCubic,
      ]) {
        var previous = -1.0;
        for (var t = 0.0; t <= 1; t += 0.01) {
          final progress = curve.transform(t);
          expect(progress, greaterThanOrEqualTo(previous));
          previous = progress;
        }
      }
    });

    test('a curve that overshoots goes past the end on its way', () {
      expect(
        [
          for (var t = 0.0; t <= 1; t += 0.02)
            CoreEasing.easeOutBack.transform(t),
        ].any((progress) => progress > 1),
        isTrue,
      );
    });

    test('refuses an x control point outside 0 to 1', () {
      expect(
        () => (x1: 1.5, y1: 0.0, x2: 0.5, y2: 1.0).transform(0.5),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
