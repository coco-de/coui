// One vocabulary across the design tool and both platforms.
//
// The material is authored against a glass panel with named sliders —
// Refraction, Depth, Dispersion, a light angle and a light strength. Those
// numbers were being converted by hand on the way in, differently in each
// place they were written, which is the failure mode this file guards: a
// value that means one thing in a design and another in the recipe built
// from it, with no output anywhere saying they differ.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The band the liquid-glass style states.
///
/// Read off the *functional* role. The recipe calls the band "a property of
/// the style rather than of either role", but only one role carries a
/// material for it to sit on — the content layer is a standard material and
/// states no band at all.
CoreSurfaceEdgeSheen _glassSheen() => CoreSurfaceRecipe.of(
  CoreSurfaceStyleId.liquidGlass,
).surfaceFor(CoreSurfaceRole.functional)!.sheen!;

void main() {
  group('a panel number arrives unconverted', () {
    test('the sliders map onto the normalised quantities', () {
      // Both directions of the same statement: the constructor divides, and
      // the fields it fills are the ones the renderers read. A conversion
      // that landed on the wrong field would still divide correctly.
      const request = CoreSurfaceRefraction.figma(
        refraction: 80,
        depth: 20,
        dispersion: 50,
      );

      expect(request.strength, closeTo(0.8, 1e-9));
      expect(request.bezel, closeTo(0.2, 1e-9));
      expect(request.dispersion, closeTo(0.5, 1e-9));
    });

    test('and it is the same value as writing the fraction by hand', () {
      // The named constructor is sugar, not a second model. If the two
      // forms ever produced unequal values, a recipe would render
      // differently depending on which spelling its author reached for.
      const viaPanel = CoreSurfaceRefraction.figma(
        refraction: 80,
        depth: 20,
        dispersion: 50,
        fallbackBlurAdd: 4,
      );
      const viaFields = CoreSurfaceRefraction(
        bezel: 0.2,
        strength: 0.8,
        dispersion: 0.5,
        fallbackBlurAdd: 4,
      );

      expect(viaPanel, viaFields);
      expect(viaPanel.hashCode, viaFields.hashCode);
    });

    test('and a depth past the geometry does not build', () {
      // The slider runs to 100 and the geometry runs out at 50: past half
      // the shorter side the two bands meet and there is no flat interior
      // left. Better to fail at the call site than to render a surface with
      // no middle.
      expect(
        () => CoreSurfaceRefraction.figma(
          refraction: 80,
          depth: double.parse('60'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('and the shipped recipe is written in those numbers', () {
      // The point of the whole exercise. Someone comparing the design and
      // this recipe should be comparing the same digits.
      final shipped = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).refraction!;

      expect(shipped.strength, closeTo(0.8, 1e-9));
      expect(shipped.bezel, closeTo(0.27, 1e-9));
      expect(shipped.dispersion, closeTo(0.5, 1e-9));
    });
  });

  group('the edge wall is a light, not four crescents', () {
    test('the angle decides which edges are lit', () {
      // The inversion this derivation exists to hold: screen coordinates
      // put y downward, so light *from* above travels with positive y, and
      // an inset layer offset downward lights the *top* edge. Spelled out
      // per layer it goes wrong one layer at a time.
      const upperLeft = CoreSurfaceEdgeBevel(
        thickness: 2,
        lightAngle: -45,
        lightIntensity: 0.8,
      );

      final lit = upperLeft.toLayers().first;
      expect(
        lit.offsetX,
        greaterThan(0),
        reason: 'light from the left must throw its crescent rightward',
      );
      expect(
        lit.offsetY,
        greaterThan(0),
        reason: 'light from above must throw its crescent downward',
      );
    });

    test('and moving the light moves every layer together', () {
      // The edit that used to go half-done. One number now, and the far
      // side has to follow the near one or the wall reads as two lights.
      const fromAbove = CoreSurfaceEdgeBevel(
        thickness: 2,
        lightAngle: 0,
        lightIntensity: 0.8,
      );
      const fromBelow = CoreSurfaceEdgeBevel(
        thickness: 2,
        lightAngle: 180,
        lightIntensity: 0.8,
      );

      final above = fromAbove.toLayers();
      final below = fromBelow.toLayers();

      expect(above.first.offsetY, closeTo(-below.first.offsetY, 1e-9));
      expect(above[1].offsetY, closeTo(-below[1].offsetY, 1e-9));
    });

    test('and the far side is lit, but not as much', () {
      // Neither extreme is the look. A wall lit on one side only reads as a
      // shadow; two equal sides read as the uniform ring this treatment
      // exists to be distinguishable from.
      const bevel = CoreSurfaceEdgeBevel(
        thickness: 2,
        lightAngle: -45,
        lightIntensity: 0.8,
      );

      final layers = bevel.toLayers();
      expect(layers[1].opacity, greaterThan(0));
      expect(layers[1].opacity, lessThan(layers.first.opacity));
    });

    test('and a bevel with no light draws nothing at all', () {
      // Otherwise "the wall is drawn" is satisfied by layers that are
      // always present and always invisible.
      const dark = CoreSurfaceEdgeBevel(
        thickness: 2,
        lightAngle: -45,
        lightIntensity: 0,
      );

      expect(dark.toLayers(), isEmpty);
    });

    test('and every layer it draws is inset', () {
      // An outer layer here would be an outline around the surface rather
      // than a wall inside its edge — and the band element it lands on is
      // explicitly not allowed to draw a boundary.
      final layers = _glassSheen().bevel!.toLayers();

      expect(layers, isNotEmpty);
      expect(layers.every((l) => l.inset), isTrue);
    });

    test('and the shipped light is stated in the panel s own terms', () {
      final bevel = _glassSheen().bevel!;

      expect(bevel.lightAngle, -45);
      expect(bevel.lightIntensity, closeTo(0.8, 1e-9));
    });
  });
}
