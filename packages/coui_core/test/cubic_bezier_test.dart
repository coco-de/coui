// A `CoreCubicBezier` is four control points; `transform` (the Core evaluator,
// `CoreCubicBezierTransform`) reads the curve the way CSS `cubic-bezier()` does.
// The lift of a context menu's source is a value at a given time that two seats
// and a table must agree on (`context_menu_lift_vectors.json`), so the easing
// is evaluated in Core and not left to each platform's animation machinery.
//
// The expected values were computed by an independent reference: bisection on
// x(s) in double precision, with more steps than the evaluator takes.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreCubicBezier.transform', () {
    // name, curve, then (t, expected) pairs.
    final rows = <(String, CoreCubicBezier, List<(double, double)>, double)>[
      (
        'ease',
        CoreEasing.ease,
        [
          (0.05, 0.0329515413),
          (0.25, 0.4085105914),
          (0.5, 0.8024033876),
          (0.75, 0.9604589783),
          (0.95, 0.9986245415),
        ],
        1e-7,
      ),
      (
        'exit (easeIn)',
        CoreEasing.exit,
        [
          (0.05, 0.0044746153),
          (0.25, 0.0934646507),
          (0.5, 0.3153568126),
          (0.75, 0.6218618692),
          (0.95, 0.917757796),
        ],
        1e-7,
      ),
      (
        'enter (easeOut)',
        CoreEasing.enter,
        [
          (0.05, 0.082242204),
          (0.25, 0.3781381308),
          (0.5, 0.6846431874),
          (0.75, 0.9065353493),
          (0.95, 0.9955253847),
        ],
        1e-7,
      ),
      (
        'move (easeInOut)',
        CoreEasing.move,
        [
          (0.05, 0.0048297497),
          (0.25, 0.129161931),
          (0.5, 0.5),
          (0.75, 0.870838069),
          (0.95, 0.9951702503),
        ],
        1e-7,
      ),
      (
        'feedback (easeOutBack, overshoots 1)',
        CoreEasing.feedback,
        [
          (0.05, 0.2407254745),
          (0.25, 0.8466805122),
          (0.5, 1.0675526851),
          (0.75, 1.075874906),
          (0.95, 1.0193786709),
        ],
        1e-7,
      ),
      (
        // Nearly vertical in the middle: x barely moves while y races, so
        // the same error in x is a larger one in y.
        'easeOutExpo',
        CoreEasing.easeOutExpo,
        [
          (0.05, 0.2558604473),
          (0.25, 0.843514323),
          (0.5, 0.9778245915),
          (0.75, 0.9982713535),
        ],
        1e-5,
      ),
      (
        'easeInQuint',
        CoreEasing.easeInQuint,
        [
          (0.05, 0.0033269295),
          (0.25, 0.0184242221),
          (0.5, 0.054947389),
          (0.75, 0.1872974836),
          (0.95, 0.7075577407),
        ],
        1e-5,
      ),
    ];

    for (final (name, curve, points, tolerance) in rows) {
      for (final (t, expected) in points) {
        test('$name at $t', () {
          expect(curve.transform(t), closeTo(expected, tolerance));
        });
      }
    }

    test('starts at 0 and ends at 1', () {
      for (final curve in [
        CoreEasing.enter,
        CoreEasing.exit,
        CoreEasing.move,
        CoreEasing.feedback,
      ]) {
        expect(curve.transform(0), 0);
        expect(curve.transform(1), 1);
      }
    });

    test('holds a time outside 0..1 to the end it is past', () {
      expect(CoreEasing.enter.transform(-0.5), 0);
      expect(CoreEasing.enter.transform(1.5), 1);
    });

    test('the straight line is the identity', () {
      for (final t in [0.0, 0.1, 0.37, 0.5, 0.99, 1.0]) {
        expect(CoreEasing.linear.transform(t), closeTo(t, 1e-12));
      }
    });

    test('an in-out curve is symmetric about its middle', () {
      for (final t in [0.05, 0.2, 0.33, 0.45]) {
        expect(
          CoreEasing.move.transform(t) + CoreEasing.move.transform(1 - t),
          closeTo(1, 1e-6),
        );
      }
    });

    // Where a curve is flat in x - the start of one whose first control point
    // sits on the axis (`enter`), the end of one whose second does (`exit`) -
    // x(s) barely moves for a first step of s, so a solver that steps on the
    // slope is least trustworthy there. Those are the first instants of the
    // lift's rise and the last of the panel's fold, and a wrong answer there
    // would be a jump at the very start of the movement. The reference is
    // bisection on x, 200 steps.
    group('where the curve is flat in x', () {
      double reference(CoreCubicBezier c, double t) {
        double along(double a, double b, double s) =>
            3 * (1 - s) * (1 - s) * s * a + 3 * (1 - s) * s * s * b + s * s * s;
        var low = 0.0;
        var high = 1.0;
        for (var i = 0; i < 200; i++) {
          final middle = (low + high) / 2;
          if (along(c.x1, c.x2, middle) < t) {
            low = middle;
          } else {
            high = middle;
          }
        }
        final s = (low + high) / 2;

        return along(c.y1, c.y2, s);
      }

      for (final t in [1e-3, 1e-4, 1e-5, 1e-6, 1e-7, 1e-8]) {
        test('enter at $t', () {
          expect(
            CoreEasing.enter.transform(t),
            closeTo(reference(CoreEasing.enter, t), 1e-9),
          );
          // And it is not the straight line: this curve rises faster than time
          // from the first instant.
          expect(CoreEasing.enter.transform(t), greaterThan(t));
        });
        test('exit at ${1 - t}', () {
          expect(
            CoreEasing.exit.transform(1 - t),
            closeTo(reference(CoreEasing.exit, 1 - t), 1e-9),
          );
          // The way out arrives later than time does, right to the end.
          expect(CoreEasing.exit.transform(1 - t), lessThan(1 - t));
        });
      }
    });

    test('the curves the lift is made of never go backwards', () {
      for (final curve in [CoreEasing.enter, CoreEasing.exit]) {
        var previous = 0.0;
        for (var i = 1; i <= 200; i++) {
          final value = curve.transform(i / 200);
          expect(value, greaterThanOrEqualTo(previous));
          previous = value;
        }
      }
    });
  });
}
