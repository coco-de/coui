// The rim is the crest of the wall catching the light: a stroke along the
// contour whose brightness is a function of the outline's normal. Both
// renderers evaluate the function here, so what is pinned is the function
// and the contour sampling — not either platform's gradient.
library;

import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _upperLeft = CoreSurfaceEdgeBevel(
  thickness: 2,
  lightAngle: -45,
  lightIntensity: 0.8,
  rimWidth: 1,
  rimIntensity: 0.9,
);

void main() {
  group('the rim is a specular lobe around the light', () {
    test('peaks where the contour faces the light head-on', () {
      // -45 and 315 are the same normal; the function has to agree.
      expect(_upperLeft.rimAlphaAt(-45), closeTo(0.9, 1e-9));
      expect(_upperLeft.rimAlphaAt(315), closeTo(0.9, 1e-9));
    });

    test('is dark where the contour runs parallel to the light', () {
      expect(_upperLeft.rimAlphaAt(45), closeTo(0, 1e-9));
      expect(_upperLeft.rimAlphaAt(225), closeTo(0, 1e-9));
    });

    test('and the far side catches the counter share, not nothing', () {
      // A rim lit from one side only reads as a shadow on the other. The
      // far side is the same share the crescents use, so the two
      // treatments cannot disagree about how much light gets round.
      expect(
        _upperLeft.rimAlphaAt(135),
        closeTo(0.9 * CoreSurfaceEdgeBevel.counterShare, 1e-9),
      );
    });

    test('the straight edges sit between the peak and the trough', () {
      // Sharpness 2 puts a lit edge at cos²(45°) = half the peak. That is
      // the number that makes a pill read as one lit object rather than
      // four glints — pinned as a relation, so retuning the exponent is a
      // Core edit with a visible consequence rather than a silent one.
      final top = _upperLeft.rimAlphaAt(0);
      final left = _upperLeft.rimAlphaAt(270);

      expect(top, closeTo(left, 1e-9));
      expect(top, closeTo(0.9 * 0.5, 1e-9));
    });

    test('a rim with no width or no intensity draws nothing', () {
      expect(_upperLeft.copyWith(rimWidth: 0).drawsRim, isFalse);
      expect(_upperLeft.copyWith(rimIntensity: 0).drawsRim, isFalse);
      expect(_upperLeft.copyWith(rimWidth: 0).rimAlphaAt(-45), 0);
      expect(
        _upperLeft
            .copyWith(rimIntensity: 0)
            .rimSweep(
              width: 100,
              height: 40,
              radius: 8,
            ),
        isEmpty,
      );
    });
  });

  group('the sweep is the contour, sampled where the normal turns', () {
    final stops = _upperLeft.rimSweep(width: 200, height: 60, radius: 12);

    test('runs from the top round to the top, non-decreasing', () {
      expect(stops.first.angle, 0);
      expect(stops.last.angle, 360);
      for (var i = 1; i < stops.length; i++) {
        expect(
          stops[i].angle,
          greaterThanOrEqualTo(stops[i - 1].angle),
          reason: 'stop $i went backwards',
        );
      }
    });

    test('closes on the same value it opened with', () {
      // Both ends are the top edge; a seam there would be a visible notch
      // at twelve o\'clock on every panel.
      expect(stops.first.alpha, closeTo(stops.last.alpha, 1e-9));
    });

    test(
      'the top-left arc carries the peak and the bottom-right the trough',
      () {
        // The whole point of sampling by contour: on a 200×60 bar with a
        // 12px radius the lit arc is a sliver of sweep, and an even sweep
        // would step over it. The peak has to be *present* in the list.
        final peak = stops.map((s) => s.alpha).reduce(math.max);
        final trough = stops.map((s) => s.alpha).reduce(math.min);

        expect(peak, closeTo(0.9, 1e-6));
        expect(trough, closeTo(0, 1e-6));
        // The peak lives in the last quadrant of sweep (top-left arc).
        final atPeak = stops.firstWhere((s) => (s.alpha - peak).abs() < 1e-6);
        expect(atPeak.angle, inInclusiveRange(270, 360));
      },
    );

    test('a straight edge is carried by its two arc ends alone', () {
      // Between the top-right arc\'s first stop and the top-left arc\'s
      // last there is nothing but the closing stops at 0 and 360 — the
      // top edge has a constant normal, and two equal stops say so.
      // On 200×60 with a 12px radius the arc starts at (88, -30) from
      // the centre — a sweep of about 71°. Everything before it is the
      // top edge, carried by the two equal stops.
      final topRightStart = stops[1];
      expect(topRightStart.alpha, closeTo(stops.first.alpha, 1e-9));
      expect(topRightStart.angle, closeTo(71.18, 0.05));
    });

    test('a square corner is a hard step, not a missing arc', () {
      final square = _upperLeft.rimSweep(width: 100, height: 100, radius: 0);
      // Every arc collapses to one sweep angle carrying both edges\'
      // values; the list still spans the full circle.
      expect(square.first.angle, 0);
      expect(square.last.angle, 360);
      final atTopRight = square
          .where((s) => (s.angle - 45).abs() < 1e-6)
          .map((s) => s.alpha)
          .toSet();
      expect(
        atTopRight.length,
        greaterThan(1),
        reason: 'no step at the corner',
      );
    });

    test('a radius past the shorter side is clamped, not trusted', () {
      final pill = _upperLeft.rimSweep(width: 200, height: 40, radius: 9999);
      final capsule = _upperLeft.rimSweep(width: 200, height: 40, radius: 20);

      expect(pill, capsule);
    });
  });

  group('the shipped glass states a rim', () {
    test('on both roles, because both are the one material', () {
      final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);
      for (final role in CoreSurfaceRole.values) {
        final bevel = recipe.surfaceFor(role)!.sheen!.bevel!;

        expect(bevel.drawsRim, isTrue, reason: role.name);
        // Two pixels: one read on a pill's arc and vanished on a card's
        // straight edge at 1×. Retuning is a recipe edit and this line.
        expect(bevel.rimWidth, CoreStrokeWidth.stroke2, reason: role.name);
        expect(bevel.rimIntensity, 1, reason: role.name);
      }
    });

    test('and the rim participates in equality and serialisation', () {
      // The axis rule: a field `==` cannot see is a field a retune cannot
      // reach — the framework compares, finds nothing changed, and keeps
      // the old rim on screen.
      final shipped = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).surfaceFor(.functional)!.sheen!.bevel!;

      expect(shipped.copyWith(rimIntensity: 0.1), isNot(shipped));
      expect(shipped.copyWith(rimWidth: 3), isNot(shipped));
      expect(shipped.toJson()['rimWidth'], shipped.rimWidth);
      expect(shipped.toJson()['rimIntensity'], shipped.rimIntensity);
    });
  });
}
