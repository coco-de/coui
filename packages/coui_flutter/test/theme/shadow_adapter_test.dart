import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoreShadowLayerAdapter.toValue', () {
    test('maps offset/blur/spread/color tinted by opacity', () {
      const layer = (
        offsetX: 0.0,
        offsetY: 4.0,
        blurRadius: 8.0,
        spreadRadius: -2.0,
        opacity: 0.06,
        inset: false,
      );

      final shadow = layer.toValue(const Color(0xFF000000));

      expect(shadow.offset, equals(const Offset(0, 4)));
      // The CSS-convention blur radius is re-expressed so Flutter's
      // Skia sigma (radius × 0.57735 + 0.5) equals the CSS sigma
      // (radius / 2) — see [cssBlurRadiusToFlutter].
      expect(shadow.blurRadius, equals(cssBlurRadiusToFlutter(8)));
      expect(shadow.spreadRadius, equals(-2));
      expect(shadow.color.r, equals(0));
      expect(shadow.color.g, equals(0));
      expect(shadow.color.b, equals(0));
      expect(shadow.color.a, closeTo(0.06, 0.001));
      expect(shadow.blurStyle, equals(BlurStyle.normal));
    });

    test('inset=true maps to BlurStyle.inner', () {
      const layer = (
        offsetX: 0.0,
        offsetY: 2.0,
        blurRadius: 4.0,
        spreadRadius: 0.0,
        opacity: 0.06,
        inset: true,
      );

      final shadow = layer.toValue(const Color(0xFF000000));

      expect(shadow.blurStyle, equals(BlurStyle.inner));
    });
  });

  group('CoreShadowAdapter.toValue', () {
    test('converts each layer in CoreShadow.md', () {
      final shadows = CoreShadow.md.toValue(
        base: const Color(0xFF000000),
        geometry: const CoreSurfaceGeometryConstraint(),
      );
      expect(shadows, hasLength(1));
      expect(shadows.single.offset.dy, equals(8));
      expect(shadows.single.blurRadius, cssBlurRadiusToFlutter(24));
    });

    test('a dark geometry draws the same shape at ×4 alpha, capped at 1', () {
      const base = Color(0xFF000000);
      final light = CoreShadow.lg.toValue(
        base: base,
        geometry: const CoreSurfaceGeometryConstraint(),
      );
      final dark = CoreShadow.lg.toValue(
        base: base,
        geometry: const CoreSurfaceGeometryConstraint(brightness: .dark),
      );
      expect(dark.single.offset, light.single.offset);
      expect(dark.single.blurRadius, light.single.blurRadius);
      expect(dark.single.color.a, closeTo(0.5, 1e-6));
      expect(light.single.color.a, closeTo(0.125, 1e-6));
    });

    test('converts CoreShadow.none to empty list', () {
      final shadows = CoreShadow.none.toValue(
        base: const Color(0xFF000000),
        geometry: const CoreSurfaceGeometryConstraint(),
      );
      expect(shadows, isEmpty);
    });

    test('converts CoreShadow.inset to single inner-blur shadow', () {
      final shadows = CoreShadow.inset.toValue(
        base: const Color(0xFF000000),
        geometry: const CoreSurfaceGeometryConstraint(),
      );
      expect(shadows, hasLength(1));
      expect(shadows.first.blurStyle, equals(BlurStyle.inner));
    });

    test('every elevated token converts layer for layer', () {
      for (final token in [
        CoreShadow.xs,
        CoreShadow.sm,
        CoreShadow.md,
        CoreShadow.lg,
        CoreShadow.xl,
        CoreShadow.xl2,
        CoreShadow.xl3,
      ]) {
        expect(
          token.toValue(
            base: const Color(0xFF000000),
            geometry: const CoreSurfaceGeometryConstraint(),
          ),
          hasLength(token.length),
        );
      }
      // The attached lifts are two layers, the floating rungs one.
      expect(CoreShadow.sm, hasLength(2));
      expect(CoreShadow.md, hasLength(1));
    });
  });

  group('cssBlurRadiusToFlutter', () {
    test('painted Skia sigma equals the CSS sigma', () {
      for (final cssBlur in [2.0, 4.0, 6.0, 8.0, 15.0, 25.0]) {
        final flutterRadius = cssBlurRadiusToFlutter(cssBlur);
        final paintedSigma = flutterRadius * 0.57735 + 0.5;
        expect(
          paintedSigma,
          closeTo(cssBlur / 2, 0.0001),
          reason: 'css blur $cssBlur',
        );
      }
    });

    test('clamps to 0 when the CSS sigma is at or below the Skia '
        'intercept', () {
      expect(cssBlurRadiusToFlutter(0), equals(0));
      expect(cssBlurRadiusToFlutter(1), equals(0));
    });
  });
}
