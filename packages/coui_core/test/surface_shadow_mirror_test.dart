import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A single cast layer, thrown down and to the right.
const _cast = (
  offsetX: 2.0,
  offsetY: 4.0,
  blurRadius: 8.0,
  spreadRadius: 0.0,
  opacity: 0.2,
  inset: false,
);

/// A layer describing light inside the shape.
const _inset = (
  offsetX: 0.0,
  offsetY: 2.0,
  blurRadius: 4.0,
  spreadRadius: 0.0,
  opacity: 0.3,
  inset: true,
);

CoreSurfaceGeometryConstraint _geometryOf(CoreSurfaceStyleId id) =>
    CoreSurfaceRecipe.of(id).geometry;

void main() {
  group('a mirrored stack casts in both directions', () {
    test('each cast layer gains an opposite-facing twin', () {
      // The reason a scale could not express this: the second direction
      // is not present in the authored value at any magnitude.
      const mirror = CoreSurfaceGeometryConstraint(shadowMirror: true);
      final result = mirror.shadow(const [_cast]);

      expect(result, hasLength(2));
      expect(result[0].offsetX, _cast.offsetX);
      expect(result[1].offsetX, -_cast.offsetX);
      expect(result[1].offsetY, -_cast.offsetY);
    });

    test('and the twin keeps everything except the direction', () {
      const mirror = CoreSurfaceGeometryConstraint(shadowMirror: true);
      final twin = mirror.shadow(const [_cast])[1];

      expect(twin.blurRadius, _cast.blurRadius);
      expect(twin.spreadRadius, _cast.spreadRadius);
      expect(twin.opacity, _cast.opacity);
    });

    test('a component that casts nothing still casts nothing', () {
      // What keeps this a derivation rather than a re-authoring. A
      // preset that replaced the stack would give every flat surface in
      // the kit a shadow it never asked for.
      const mirror = CoreSurfaceGeometryConstraint(shadowMirror: true);

      expect(mirror.shadow(const []), isEmpty);
    });

    test('an inset layer passes through without a twin', () {
      // Mirroring one would put a cast shadow where a highlight was
      // asked for — the opposite of what the layer states.
      const mirror = CoreSurfaceGeometryConstraint(shadowMirror: true);

      expect(mirror.shadow(const [_inset]), hasLength(1));
    });

    test('the scale still applies, and to the twin as well', () {
      const both = CoreSurfaceGeometryConstraint(
        shadowBlurScale: 2,
        shadowMirror: true,
      );
      final result = both.shadow(const [_cast]);

      expect(result[0].blurRadius, _cast.blurRadius * 2);
      expect(result[1].blurRadius, _cast.blurRadius * 2);
    });
  });

  group('the statement reaches the style that needs it', () {
    test('neumorphism mirrors, and nothing else does', () {
      // The dual shadow is this style's signature. A test that only
      // exercised the constraint directly would pass with the recipe
      // never stating it — which is the shape of every dead axis field
      // this project has found.
      for (final id in CoreSurfaceStyleId.values) {
        expect(
          _geometryOf(id).shadowMirror,
          id == CoreSurfaceStyleId.neumorphism,
          reason: '${id.name} disagrees',
        );
      }
    });

    test('and a component stack comes back doubled under it', () {
      final under = _geometryOf(
        CoreSurfaceStyleId.neumorphism,
      ).shadow(const [_cast]);
      final plain = _geometryOf(
        CoreSurfaceStyleId.defaultId,
      ).shadow(const [_cast]);

      expect(under, hasLength(2));
      expect(plain, hasLength(1));
    });
  });

  group('the statement is part of the value', () {
    test('two constraints differing only in it are not equal', () {
      // A theme axis swaps one constraint for another and the framework
      // decides whether to rebuild by comparing them. A field left out
      // of equality computes correctly and changes nothing on screen.
      const a = CoreSurfaceGeometryConstraint();
      const b = CoreSurfaceGeometryConstraint(shadowMirror: true);

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
      expect(a.isIdentity, isTrue);
      expect(b.isIdentity, isFalse);
    });

    test('copyWith carries it', () {
      const base = CoreSurfaceGeometryConstraint(shadowMirror: true);

      expect(base.copyWith(shadowBlurScale: 3).shadowMirror, isTrue);
    });
  });
}
