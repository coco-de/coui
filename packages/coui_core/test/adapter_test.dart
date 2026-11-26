/// Adapter behaviour — one method, wired once per platform.
///
/// `resolveColorScheme` fills in the tokens an authored palette leaves
/// open. It is the whole interface: the four that used to sit beside it
/// (variant, motion, corner style, surface) are gone, each because the
/// thing it rewrote is stated somewhere else — a variant by the caller, a
/// corner by the surface geometry constraint, motion by the duration and
/// easing tiers, a surface treatment by the style recipe.
///
/// These tests call the adapter directly and check what it returns, so
/// they say nothing about whether anything downstream asks. For this
/// method that gap is closed elsewhere — the theme wires it once per
/// design system — but it is worth naming, because twenty-one tests of
/// that shape over a path with no caller is what kept the retired four
/// looking alive.
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

CoreColorScheme _createScheme() => CouiColorPresets.source.light();

void main() {
  group('CouiWebAdapter', () {
    const adapter = CouiAdapter();

    test('resolves surfaceContainer from base tokens', () {
      final scheme = _createScheme();
      final resolved = adapter.resolveColorScheme(
        scheme,
        .light,
      );

      expect(resolved.surfaceContainerLowest, isNotNull);
      expect(resolved.surfaceContainer, isNotNull);
      expect(resolved.surfaceContainerHighest, isNotNull);
    });

    test('resolves outline from neutral', () {
      final scheme = _createScheme();
      final resolved = adapter.resolveColorScheme(
        scheme,
        .light,
      );

      expect(resolved.outline, isNotNull);
    });
  });

  group('M3ExpressiveAdapter', () {
    const adapter = M3ExpressiveAdapter();

    test('resolves surfaceContainer levels', () {
      final scheme = _createScheme();
      final resolved = adapter.resolveColorScheme(
        scheme,
        .light,
      );

      expect(resolved.surfaceContainerLowest, isNotNull);
      expect(resolved.surfaceContainerLow, isNotNull);
      expect(resolved.surfaceContainer, isNotNull);
      expect(resolved.surfaceContainerHigh, isNotNull);
      expect(resolved.surfaceContainerHighest, isNotNull);
    });

    test('resolves inverse colors for light mode', () {
      final scheme = _createScheme();
      final resolved = adapter.resolveColorScheme(
        scheme,
        .light,
      );

      expect(resolved.inverseSurface, isNotNull);
      expect(resolved.inverseOnSurface, isNotNull);
    });
  });

  group('LiquidGlassAdapter', () {
    const adapter = LiquidGlassAdapter();

    test('passes the colour scheme through', () {
      // Translucency is stated by the surface style recipe, not by colour
      // slots — so the palette it is handed is the palette it returns.
      final scheme = _createScheme();
      final resolved = adapter.resolveColorScheme(scheme, .light);

      expect(resolved.primary, equals(scheme.resolved(.light).primary));
      expect(resolved.surface, equals(scheme.resolved(.light).surface));
    });
  });

  group('DesignSystemAdapterSelector', () {
    test('maps each DesignSystem to its adapter', () {
      expect(DesignSystem.coui.adapter, isA<CouiAdapter>());
      expect(DesignSystem.m3Expressive.adapter, isA<M3ExpressiveAdapter>());
      expect(DesignSystem.liquidGlass.adapter, isA<LiquidGlassAdapter>());
    });
  });
}
