import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The brightness part of the geometry seat: a dark theme multiplies every
/// cast layer's opacity by `CoreShadow.darkStrength` (capped at 1) and leaves
/// the shadow's shape alone.
void main() {
  const light = CoreSurfaceGeometryConstraint();
  const dark = CoreSurfaceGeometryConstraint(brightness: .dark);

  group('a dark theme strengthens a shadow and keeps its shape', () {
    test('every layer of every rung is ×4, capped at 1', () {
      for (final token in [
        CoreShadow.xs,
        CoreShadow.sm,
        CoreShadow.md,
        CoreShadow.lg,
        CoreShadow.xl,
        CoreShadow.xl2,
        CoreShadow.xl3,
        CoreShadow.inset,
      ]) {
        final out = dark.shadow(token);
        expect(out, hasLength(token.length));
        for (var i = 0; i < token.length; i++) {
          final want = (token[i].opacity * CoreShadow.darkStrength).clamp(
            0.0,
            1.0,
          );
          expect(out[i].opacity, closeTo(want, 1e-12));
          expect(out[i].offsetX, token[i].offsetX);
          expect(out[i].offsetY, token[i].offsetY);
          expect(out[i].blurRadius, token[i].blurRadius);
          expect(out[i].spreadRadius, token[i].spreadRadius);
          expect(out[i].inset, token[i].inset);
        }
      }
    });

    test('the dark draws the v2 values — md 0.40, lg 0.50, xl 0.50', () {
      expect(dark.shadow(CoreShadow.md).single.opacity, closeTo(0.40, 1e-12));
      expect(dark.shadow(CoreShadow.lg).single.opacity, closeTo(0.50, 1e-12));
      expect(dark.shadow(CoreShadow.xl).single.opacity, closeTo(0.50, 1e-12));
    });

    test('an alpha that would pass 1 stops at 1', () {
      const heavy = [
        (
          offsetX: 0.0,
          offsetY: 4.0,
          blurRadius: 8.0,
          spreadRadius: 0.0,
          opacity: 0.6,
          inset: false,
        ),
      ];
      expect(dark.shadow(heavy).single.opacity, 1);
    });

    test('a light theme hands the stack back untouched', () {
      expect(identical(light.shadow(CoreShadow.md), CoreShadow.md), isTrue);
    });

    test('an empty stack stays empty in the dark', () {
      expect(dark.shadow(CoreShadow.none), isEmpty);
    });
  });

  group('the order: the style replaces, then the brightness multiplies', () {
    test('a stated opacity is still strengthened', () {
      const stated = CoreSurfaceGeometryConstraint(
        shadowOpacityOverride: 0.2,
        brightness: .dark,
      );
      expect(stated.shadow(CoreShadow.md).single.opacity, closeTo(0.8, 1e-12));
    });

    test('a hard-edged style that states 1 stays 1', () {
      final neo = resolveThemeGeometry(
        surfaceStyle: .neoBrutalism,
        brightness: .dark,
      );
      for (final layer in neo.shadow(CoreShadow.lg)) {
        expect(layer.opacity, 1);
      }
    });

    test('a mirror twin is as strong as the layer it follows', () {
      final soft = resolveThemeGeometry(
        surfaceStyle: .neumorphism,
        brightness: .dark,
      );
      final out = soft.shadow(CoreShadow.md);
      expect(out, hasLength(2));
      expect(out[1].opacity, out[0].opacity);
      expect(
        out[0].opacity,
        closeTo(CoreShadow.md.single.opacity * CoreShadow.darkStrength, 1e-12),
      );
    });
  });

  group('a cast the style contributes takes the strength alone', () {
    test('strengthen multiplies and caps, and bends nothing else', () {
      const cast = [
        (
          offsetX: 4.0,
          offsetY: 4.0,
          blurRadius: 0.0,
          spreadRadius: 0.0,
          opacity: 0.2,
          inset: false,
        ),
      ];
      final out = dark.strengthen(cast).single;
      expect(out.opacity, closeTo(0.8, 1e-12));
      expect((out.offsetX, out.offsetY, out.blurRadius), (4.0, 4.0, 0.0));
    });

    test('light and empty come back as the same instance', () {
      const cast = [
        (
          offsetX: 4.0,
          offsetY: 4.0,
          blurRadius: 0.0,
          spreadRadius: 0.0,
          opacity: 1.0,
          inset: false,
        ),
      ];
      expect(identical(light.strengthen(cast), cast), isTrue);
      expect(dark.strengthen(const []), isEmpty);
    });
  });

  group('the brightness is a value of the constraint', () {
    test('light is identity, dark is not', () {
      expect(light.isIdentity, isTrue);
      expect(dark.isIdentity, isFalse);
    });

    test('a dark default moves no corner and no inset', () {
      const corner = CoreBorderRadius.all(CoreRadius.radius12);
      const pad = CoreEdgeInsets.all(CoreSpace.space16);
      expect(identical(dark.borderRadius(corner), corner), isTrue);
      expect(identical(dark.insets(pad), pad), isTrue);
    });

    test('equality and hash see the brightness', () {
      expect(light, isNot(dark));
      expect(light.hashCode, isNot(dark.hashCode));
      expect(
        dark,
        const CoreSurfaceGeometryConstraint(brightness: CoreBrightness.dark),
      );
    });

    test(
      'copyWith and atBrightness carry it; the same brightness is a no-op',
      () {
        expect(light.copyWith(brightness: .dark), dark);
        expect(identical(dark.atBrightness(.dark), dark), isTrue);
        expect(light.atBrightness(.dark), dark);
      },
    );

    test('the seat folds it after the density and the style', () {
      expect(resolveThemeGeometry().isIdentity, isTrue);
      final seat = resolveThemeGeometry(density: .compact, brightness: .dark);
      expect(seat.brightness, CoreBrightness.dark);
      expect(seat.density, CoreDensity.compact);
      expect(
        seat.shadow(CoreShadow.md).single.opacity,
        closeTo(CoreShadow.md.single.opacity * CoreShadow.darkStrength, 1e-12),
      );
    });
  });
}
