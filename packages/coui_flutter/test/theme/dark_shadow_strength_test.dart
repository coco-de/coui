import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The Flutter seat of the dark shadow strength: `applySurfaceStyle` folds
/// the base theme's brightness into `ThemeData.geometry`, and every cast a
/// resolver converts through that geometry draws its alpha ×
/// `CoreShadow.darkStrength` (capped at 1) — the same value the Web dark
/// scope sets on `--coui-shadow-strength`.
void main() {
  const semantic = CouiSemanticColors.from(CouiColorPresets.source);
  final light = ThemeData(colorScheme: semantic.light.resolved(.light));
  final dark = ThemeData(colorScheme: semantic.dark.resolved(.dark));

  group('the fold carries the brightness', () {
    test('a light base keeps the identity geometry', () {
      final styled = applySurfaceStyle(
        light,
        surfaceStyle: .defaultStyle,
        highContrast: false,
      );
      expect(styled.geometry, light.geometry);
      expect(styled.geometry.isIdentity, isTrue);
    });

    test('a dark base gets a dark geometry, even on the default style', () {
      final styled = applySurfaceStyle(
        dark,
        surfaceStyle: .defaultStyle,
        highContrast: false,
      );
      expect(styled.geometry.brightness, CoreBrightness.dark);
      expect(
        styled.geometry,
        resolveThemeGeometry(brightness: .dark),
      );
    });

    test('a style keeps its own bends and adds the strength', () {
      final styled = applySurfaceStyle(
        dark,
        surfaceStyle: .neumorphism,
        highContrast: false,
      );
      expect(
        styled.geometry,
        resolveThemeGeometry(surfaceStyle: .neumorphism, brightness: .dark),
      );
    });

    test('high contrast dark is still dark', () {
      final styled = applySurfaceStyle(
        dark,
        surfaceStyle: .defaultStyle,
        highContrast: true,
      );
      expect(styled.geometry.brightness, CoreBrightness.dark);
    });
  });

  group('what reaches paint', () {
    Future<ResolvedPopup> popupUnder(
      WidgetTester tester,
      ThemeData base,
    ) async {
      late ResolvedPopup resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: applySurfaceStyle(
              base,
              surfaceStyle: .defaultStyle,
              highContrast: false,
            ),
            child: Builder(
              builder: (context) {
                resolved = resolvePopup(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return resolved;
    }

    testWidgets('a popup panel casts lg at 0.125 in light and 0.5 in dark', (
      tester,
    ) async {
      final lit = await popupUnder(tester, light);
      final dim = await popupUnder(tester, dark);

      expect(lit.boxShadow, hasLength(1));
      expect(dim.boxShadow, hasLength(1));
      final litAlpha = lit.boxShadow.single.color.a;
      final dimAlpha = dim.boxShadow.single.color.a;
      // The shadow token's own alpha is 1 in both modes; the layer carries
      // the strength.
      expect(litAlpha, closeTo(CoreShadow.lg.single.opacity, 1e-3));
      expect(
        dimAlpha,
        closeTo(CoreShadow.lg.single.opacity * CoreShadow.darkStrength, 1e-3),
      );
      // Same shape: the brightness moves no offset and no blur.
      expect(dim.boxShadow.single.offset, lit.boxShadow.single.offset);
      expect(dim.boxShadow.single.blurRadius, lit.boxShadow.single.blurRadius);
    });

    testWidgets('a contributed cast is strengthened by the same rule', (
      tester,
    ) async {
      late ThemeData seen;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data:
                applySurfaceStyle(
                  dark,
                  surfaceStyle: .defaultStyle,
                  highContrast: false,
                ).copyWith(
                  geometry: () => const CoreSurfaceGeometryConstraint(
                    controlShadow: [
                      (
                        offsetX: 2.0,
                        offsetY: 2.0,
                        blurRadius: 0.0,
                        spreadRadius: 0.0,
                        opacity: 0.2,
                        inset: false,
                      ),
                    ],
                    brightness: .dark,
                  ),
                ),
            child: Builder(
              builder: (context) {
                seen = Theme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      final cast = resolveInjectedCast(seen);
      expect(cast, hasLength(1));
      expect(cast.single.color.a, closeTo(0.8, 1e-3));
    });
  });
}
