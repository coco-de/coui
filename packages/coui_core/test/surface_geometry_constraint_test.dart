import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  const identity = CoreSurfaceGeometryConstraint();
  const square = CoreSurfaceGeometryConstraint(radiusCap: 0);
  const thick = CoreSurfaceGeometryConstraint(
    strokeFloor: CoreStrokeWidth.stroke3,
  );

  group('identity costs nothing', () {
    test('it reports itself as identity', () {
      expect(identity.isIdentity, isTrue);
      expect(square.isIdentity, isFalse);
      expect(thick.isIdentity, isFalse);
    });

    test("it returns the caller's own radius instance", () {
      // Not merely equal — the same object. A fresh instance per component
      // per build on the default surface would be pure waste, and anything
      // upstream comparing by identity would see spurious change.
      const value = CoreBorderRadius.all(CoreRadius.radius16);
      expect(identical(identity.borderRadius(value), value), isTrue);
    });

    test('it leaves scalars alone', () {
      expect(identity.radius(16), 16);
      expect(identity.stroke(1), 1);
    });
  });

  group('capping radius', () {
    test('square corners reach every corner', () {
      const mixed = CoreBorderRadius.only(topLeft: 16, bottomRight: 8);
      final capped = square.borderRadius(mixed);
      expect(capped.topLeft, 0);
      expect(capped.topRight, 0);
      expect(capped.bottomLeft, 0);
      expect(capped.bottomRight, 0);
    });

    test('a value below the cap is untouched', () {
      const gentle = CoreSurfaceGeometryConstraint(radiusCap: 0);
      expect(gentle.radius(0), 0);
    });

    test('an off-scale value is capped too', () {
      // The whole reason this is a transform and not a token mapping: a
      // caller who wrote a deliberate 13 still gets square corners.
      expect(square.radius(13), 0);
      expect(square.radius(4.7), 0);
    });

    test('nothing can exceed the pill sentinel', () {
      expect(
        identity.radius(CoreRadius.radius9999 + 1000),
        CoreRadius.radius9999,
      );
    });

    test('a non-zero bound is accepted, and reads on the ladder', () {
      // This used to throw. The stated reason was that size scaling
      // multiplies afterwards, so a cap of 4 renders as 5 on a 1.25
      // theme — true, but it treats the bound as a promise about
      // rendered pixels. It is a statement about *where on the ladder*
      // a material sits, and that stays true at any scaling because
      // every other dimension moves with it.
      const ranged = CoreSurfaceGeometryConstraint(
        radiusFloor: 4,
        radiusCap: 16,
      );

      expect(ranged.radius(CoreRadius.radius64), lessThanOrEqualTo(16));
    });

    test('a floor above the cap is refused', () {
      // The one range with no values in it.
      expect(
        () => CoreSurfaceGeometryConstraint(radiusFloor: 32, radiusCap: 8),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('flooring stroke', () {
    test('a thin border is raised', () {
      expect(thick.stroke(1), CoreStrokeWidth.stroke3);
    });

    test('an already-thick border is left alone', () {
      expect(thick.stroke(CoreStrokeWidth.stroke4), CoreStrokeWidth.stroke4);
    });

    test('a suppressed border stays suppressed', () {
      // Variants express "no border" by collapsing the width. Raising those
      // to the floor would draw borders exactly where a design had removed
      // them — and would re-inflate the transparent-border collapse that
      // exists so an invisible border does not eat layout.
      expect(thick.stroke(0), 0);
    });

    test('the floor is applied after scaling, not before', () {
      // Floored first, a scaling below 1 would shrink the result back under
      // the floor and the preset's minimum would hold on some devices only.
      expect(thick.stroke(1, scaling: 0.5), CoreStrokeWidth.stroke3);
      expect(thick.stroke(1, scaling: 2), CoreStrokeWidth.stroke3);
      expect(
        thick.stroke(CoreStrokeWidth.stroke2, scaling: 2),
        CoreStrokeWidth.stroke4,
      );
    });

    test('scaling still applies without a floor', () {
      expect(identity.stroke(2, scaling: 1.5), 3);
    });
  });

  // Below a 2x screen half a logical pixel is a sub-pixel line, fainter than
  // its colour, so the design draws the hairline one pixel wide there — the
  // Web's `--coui-stroke-width-0_5` reads the screen the same way.
  group('the hairline follows the screen', () {
    test('a 1x screen draws it one pixel wide', () {
      expect(
        identity.atDevicePixelRatio(1).stroke(CoreStrokeWidth.stroke0_5),
        CoreStrokeWidth.stroke1,
      );
    });

    test('a 2x screen and denser draw it at its own width', () {
      for (final ratio in [2.0, 3.0]) {
        expect(
          identity.atDevicePixelRatio(ratio).stroke(CoreStrokeWidth.stroke0_5),
          CoreStrokeWidth.stroke0_5,
        );
      }
    });

    test('a 1x screen draws the active boundary one pixel wide', () {
      expect(
        identity.atDevicePixelRatio(1).stroke(CoreStrokeWidth.stroke1_5),
        CoreStrokeWidth.stroke1,
      );
    });

    test('a 2x screen and denser draw the active boundary at its own '
        'width', () {
      for (final ratio in [2.0, 3.0]) {
        expect(
          identity.atDevicePixelRatio(ratio).stroke(CoreStrokeWidth.stroke1_5),
          CoreStrokeWidth.stroke1_5,
        );
      }
    });

    test('no whole-pixel step moves', () {
      final oneX = identity.atDevicePixelRatio(1);
      for (final px in [
        CoreStrokeWidth.stroke1,
        CoreStrokeWidth.stroke2,
        CoreStrokeWidth.stroke3,
      ]) {
        expect(oneX.stroke(px), px);
      }
    });

    test('a style floor still lifts the 1x active boundary', () {
      expect(
        thick.atDevicePixelRatio(1).stroke(CoreStrokeWidth.stroke1_5),
        CoreStrokeWidth.stroke3,
      );
    });

    test('scaling multiplies the widened line, and a floor still lifts it', () {
      final oneX = identity.atDevicePixelRatio(1);
      expect(oneX.stroke(CoreStrokeWidth.stroke0_5, scaling: 2), 2);
      expect(
        thick.atDevicePixelRatio(1).stroke(CoreStrokeWidth.stroke0_5),
        CoreStrokeWidth.stroke3,
      );
    });

    test('a dense screen hands the same constraint back', () {
      expect(identical(identity.atDevicePixelRatio(3), identity), isTrue);
      expect(identity.atDevicePixelRatio(3).isIdentity, isTrue);
    });

    // A screen switch that compared equal would never rebuild the theme.
    test('the screen it is folded for is part of its value', () {
      final oneX = identity.atDevicePixelRatio(1);
      expect(oneX, isNot(equals(identity)));
      expect(oneX.hashCode, isNot(equals(identity.hashCode)));
      expect(oneX.isIdentity, isFalse);
      expect(oneX.copyWith(radiusCap: 0).hairline, CoreStrokeWidth.stroke1);
      expect(
        oneX.copyWith(radiusCap: 0).activeBoundary,
        CoreStrokeWidth.stroke1,
      );
    });

    // Each half-pixel step is its own part of the value: a constraint that
    // folded only one of them must not compare equal to one that folded
    // both, or a theme rebuilt for the other would be skipped.
    test('the active boundary is part of its value on its own', () {
      final onlyHairline = identity.copyWith(hairline: CoreStrokeWidth.stroke1);
      final both = identity.atDevicePixelRatio(1);
      expect(onlyHairline, isNot(equals(both)));
      expect(onlyHairline.hashCode, isNot(equals(both.hashCode)));
      expect(
        identity.copyWith(activeBoundary: CoreStrokeWidth.stroke1).isIdentity,
        isFalse,
      );
    });
  });

  group('value equality', () {
    test('constraints that differ compare unequal', () {
      // A preset switch that compares equal to the old one never reaches
      // the screen — the framework skips the rebuild and the axis looks
      // broken in a way no screenshot explains.
      expect(square, isNot(equals(thick)));
      expect(square.hashCode, isNot(equals(thick.hashCode)));
      expect(identity, isNot(equals(square)));
    });

    test('identical declarations compare equal', () {
      expect(
        const CoreSurfaceGeometryConstraint(radiusCap: 0),
        equals(const CoreSurfaceGeometryConstraint(radiusCap: 0)),
      );
    });

    test('copyWith carries both fields', () {
      final both = square.copyWith(strokeFloor: CoreStrokeWidth.stroke3);
      expect(both.radiusCap, 0);
      expect(both.strokeFloor, CoreStrokeWidth.stroke3);
    });
  });
}
