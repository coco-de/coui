import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

// The fill share of a surface is a pair: the two modes need different
// amounts of it, and a field that could be read without naming a mode is a
// field that gets read as the light one under a dark palette.
//
// What is held here is the pair itself and the recipe's statement of it.
// That a renderer *reads* the mode-aware value is held where each renderer
// lives — a test over the Core token cannot see a consumer.

CoreSurfaceRecipe _glass() =>
    CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);

void main() {
  group('CoreSurfaceOpacity', () {
    test('resolves the value for the mode that is asked about', () {
      const pair = CoreSurfaceOpacity(light: 0.5, dark: 0.6);

      expect(pair.resolve(CoreBrightness.light), 0.5);
      expect(pair.resolve(CoreBrightness.dark), 0.6);
    });

    test('same states one value for both modes', () {
      const pair = CoreSurfaceOpacity.same(0.7);

      expect(pair.light, 0.7);
      expect(pair.dark, 0.7);
      expect(pair.resolve(CoreBrightness.light), 0.7);
      expect(pair.resolve(CoreBrightness.dark), 0.7);
    });

    test('is opaque only when no mode lets anything through', () {
      expect(CoreSurfaceOpacity.opaque.isOpaque, isTrue);
      // Either mode being translucent is translucency: this is the question
      // the reduce-transparency fallback asks, and a surface that is opaque
      // in light and glass in dark still has something for it to remove.
      expect(const CoreSurfaceOpacity(light: 1, dark: 0.6).isOpaque, isFalse);
      expect(const CoreSurfaceOpacity(light: 0.5, dark: 1).isOpaque, isFalse);
      expect(const CoreSurfaceOpacity.same(0.9).isOpaque, isFalse);
    });

    test('compares by value and by both fields', () {
      const a = CoreSurfaceOpacity(light: 0.5, dark: 0.6);

      expect(a, const CoreSurfaceOpacity(light: 0.5, dark: 0.6));
      expect(
        a.hashCode,
        const CoreSurfaceOpacity(light: 0.5, dark: 0.6).hashCode,
      );
      // Each field alone must break equality. A pair that ignored `dark`
      // would let a dark-only retune compare equal to the old value, and the
      // framework would decide nothing needs rebuilding.
      expect(a, isNot(const CoreSurfaceOpacity(light: 0.4, dark: 0.6)));
      expect(a, isNot(const CoreSurfaceOpacity(light: 0.5, dark: 0.7)));
      expect(
        a.hashCode,
        isNot(const CoreSurfaceOpacity(light: 0.5, dark: 0.7).hashCode),
      );
    });

    test('copyWith replaces only what it is given', () {
      const a = CoreSurfaceOpacity(light: 0.5, dark: 0.6);

      expect(
        a.copyWith(dark: 0.8),
        const CoreSurfaceOpacity(light: 0.5, dark: 0.8),
      );
      expect(
        a.copyWith(light: 0.4),
        const CoreSurfaceOpacity(light: 0.4, dark: 0.6),
      );
      expect(a.copyWith(), a);
    });

    test('serializes both modes', () {
      expect(
        const CoreSurfaceOpacity(light: 0.5, dark: 0.6).toJson(),
        {'light': 0.5, 'dark': 0.6},
      );
    });
  });

  group('the token carries the pair', () {
    test('a token that states no fill is opaque in both modes', () {
      for (final token in const [
        CoreSurfaceToken.flat(),
        CoreSurfaceToken.tonalElevation(elevation: 2),
        CoreSurfaceToken(type: SurfaceType.flat),
      ]) {
        expect(token.opacity, CoreSurfaceOpacity.opaque);
        expect(token.usesTransparency, isFalse);
      }
    });

    test('equality sees a change in the dark fill alone', () {
      const light = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity(light: 0.5, dark: 0.6),
        blur: 4,
      );
      const darker = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity(light: 0.5, dark: 0.7),
        blur: 4,
      );

      expect(light, isNot(darker));
      expect(light.hashCode, isNot(darker.hashCode));
      expect(light.copyWith(opacity: darker.opacity), darker);
    });

    test(
      'opaque in light and glass in dark still uses transparency',
      () {
        const token = CoreSurfaceToken(
          type: SurfaceType.glass,
          opacity: CoreSurfaceOpacity(light: 1, dark: 0.6),
        );

        expect(token.usesTransparency, isTrue);
        expect(token.withoutTransparency().opacity, CoreSurfaceOpacity.opaque);
        expect(token.withoutTransparency().usesTransparency, isFalse);
      },
    );

    test('serializes the pair rather than one number', () {
      const token = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity(light: 0.5, dark: 0.6),
        blur: 4,
      );

      expect(token.toJson()['opacity'], {'light': 0.5, 'dark': 0.6});
    });
  });

  group('the shipped glass states light 0.5 and dark 0.6', () {
    test('on the floating and the content material', () {
      for (final role in CoreSurfaceRole.values) {
        final material = _glass().surfaceFor(role)!;

        // Light is exactly the value the single number used to be — the
        // change is dark-only, and this is where that is held as a value.
        expect(
          material.opacity.light,
          CoreOpacity.opacity50,
          reason: role.name,
        );
        expect(material.opacity.dark, CoreOpacity.opacity60, reason: role.name);
      }
    });

    test('and on the nested material at every depth', () {
      // A nested glass that disagreed with its parent would be a second
      // material; the nesting table drops the backdrop pass and keeps the
      // rest, and the fill is part of the rest.
      for (final role in CoreSurfaceRole.values) {
        final top = _glass().surfaceFor(role)!;

        for (final depth in [1, 2, 9]) {
          final nested = _glass().surfaceFor(role, depth: depth)!;

          expect(nested.opacity, top.opacity, reason: '${role.name} @ $depth');
          expect(nested.blurRadius, isNull, reason: '${role.name} @ $depth');
        }
      }
    });

    test('and no other style states a translucent fill in either mode', () {
      for (final id in CoreSurfaceStyleId.values) {
        if (id == CoreSurfaceStyleId.liquidGlass) continue;
        final recipe = CoreSurfaceRecipe.of(id);

        for (final role in CoreSurfaceRole.values) {
          final material = recipe.surfaceFor(role);

          expect(
            material == null || material.opacity.isOpaque,
            isTrue,
            reason: '${id.name}/${role.name} states a translucent fill',
          );
        }
      }
    });

    test('an app that states a fill gets exactly that fill in both modes', () {
      final tuned = const CoreSurfaceTuning(
        surfaceOpacity: 0.7,
      ).applyTo(_glass()).surfaceFor(CoreSurfaceRole.functional)!;

      expect(tuned.opacity.resolve(CoreBrightness.light), 0.7);
      expect(tuned.opacity.resolve(CoreBrightness.dark), 0.7);
    });

    test('and an app that states nothing keeps the preset pair', () {
      final tuned = const CoreSurfaceTuning(
        surfaceBlur: 32,
      ).applyTo(_glass()).surfaceFor(CoreSurfaceRole.functional)!;

      expect(
        tuned.opacity,
        _glass().surfaceFor(CoreSurfaceRole.functional)!.opacity,
      );
    });
  });
}
