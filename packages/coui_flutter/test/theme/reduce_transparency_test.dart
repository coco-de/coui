import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _styled({required bool reduceTransparency}) => applySurfaceStyle(
  ThemeData.fromCore(CoreThemePresets.light),
  surfaceStyle: CoreSurfaceStyleId.liquidGlass,
  highContrast: false,
  reduceTransparency: reduceTransparency,
);

void main() {
  group('reduce transparency reaches the surface seat', () {
    // The coupling was structural long before anything triggered it —
    // blur and saturation ride one backdrop pass, so dropping the pass
    // drops both. What was missing was the switch, on this platform
    // only: Web's stylesheet has answered `prefers-reduced-transparency`
    // for a while, and Flutter has no signal to read at all.
    //
    // So the kit takes the answer instead. These two states are the
    // whole of what that buys.

    test('off — the preset renders exactly as authored', () {
      final theme = _styled(reduceTransparency: false);
      final authored = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).functionalSurface!;

      expect(theme.functionalSurface!.opacity, authored.opacity);
      expect(theme.functionalSurface!.blurRadius, authored.blurRadius);
      expect(theme.functionalSurface!.saturation, authored.saturation);

      // The other role, stated rather than left implied — "exactly as
      // authored" is a claim about both of them, and under this style
      // both are the same glass. The flat theme fields are the content
      // role's.
      final content = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).surface!;
      expect(
        theme.surfaceOpacity,
        content.opacity.resolve(CoreBrightness.light),
      );
      expect(theme.surfaceBlur, content.blurRadius);
      expect(theme.surfaceOpacity, lessThan(1));
    });

    test('on — the fill goes opaque and the backdrop pass goes away', () {
      final theme = _styled(reduceTransparency: true);

      // The content role never had a pass to drop — it is flat under
      // this style regardless of the setting. Stated so the claim below
      // (about the functional role, which does have one) is not mistaken
      // for the content-role identity values this test used to check.
      expect(theme.surfaceOpacity, 1);
      expect(theme.surfaceBlur, isNull);
      expect(
        theme.surfaceSaturation,
        CoreSurfaceToken.identitySaturation,
      );

      // The functional role is where the pass actually was — this is
      // the fold the setting exists to trigger.
      final functional = theme.functionalSurface;
      expect(functional, isNotNull);
      expect(functional!.opacity, CoreSurfaceOpacity.opaque);
      expect(functional.blurRadius, isNull);
      expect(
        functional.saturation,
        CoreSurfaceToken.identitySaturation,
        reason:
            'chroma rides the pass that was just dropped — a surface '
            'that keeps amplifying it behind a backdrop nobody can see '
            'through is the same material with one symptom hidden',
      );
    });

    test('on — the bend goes with the pass', () {
      // The guide says the two accessibility folds also switch the bend
      // off. Under high contrast the seat already did; under reduce
      // transparency the renderer would mount no shader for a surface with
      // no backdrop pass, but the theme still carried the request — a
      // value nothing could draw, and the exact shape the Web rule does
      // not have (it zeroes the filter outright).
      expect(_styled(reduceTransparency: false).surfaceRefraction, isNotNull);
      expect(_styled(reduceTransparency: true).surfaceRefraction, isNull);
    });

    test('on — the edge band survives', () {
      // Decoration on a boundary, not transparency. Taking it would
      // leave the surface with no edge at all, which is worse than the
      // translucency the setting asked to remove.
      final theme = _styled(reduceTransparency: true);
      final authored = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).functionalSurface!;

      expect(theme.functionalSurface!.sheen, authored.sheen);
      expect(theme.functionalSurface!.sheen, isNotNull);

      // The content role wears the same band and keeps it the same way.
      expect(theme.surfaceSheen, authored.sheen);
    });

    test('on — a preset that states no transparency is left alone', () {
      // Nothing to remove. The seat must not rebuild an identical token
      // and it must not invent a fallback for a style that never asked
      // for one.
      final opaque = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.light),
        surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
        highContrast: false,
        reduceTransparency: true,
      );
      final asAuthored = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.light),
        surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
        highContrast: false,
      );

      expect(opaque.surfaceOpacity, asAuthored.surfaceOpacity);
      expect(opaque.surfaceBlur, asAuthored.surfaceBlur);
    });
  });

  group('and the policy itself is stated once', () {
    // Web writes its own CSS for this. The point of the shared method is
    // that a test can hold both sides to one statement instead of to two
    // copies of a rule that can drift apart.
    test('the core policy drops transparency and keeps the band', () {
      final authored = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.liquidGlass,
      ).functionalSurface!;
      final fallback = authored.withoutTransparency();

      expect(authored.usesTransparency, isTrue);
      expect(fallback.usesTransparency, isFalse);
      expect(fallback.opacity, CoreSurfaceOpacity.opaque);
      expect(fallback.blurRadius, isNull);
      expect(fallback.saturation, CoreSurfaceToken.identitySaturation);
      expect(fallback.sheen, authored.sheen);
      expect(fallback.drawsOwnEdge, authored.drawsOwnEdge);
    });
  });
}
