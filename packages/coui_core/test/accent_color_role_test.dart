import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// `accent` / `onAccent` are names for the tertiary fill pair.
///
/// A second scheme field would be a parallel palette. These tests pin
/// the alias: every mode — a brand palette through the standard mapping
/// and CoUI's own source — resolves the two names to the same channels.
/// CoUI has no second hue, so its tertiary pair (and therefore its accent)
/// is `primary`; a chromatic brand's accent is its own tertiary, not its
/// primary.
void main() {
  const coui = CouiColorPresets.source;

  final modes = <String, CoreColorScheme Function()>{
    'standard light': kBrandFixtureSource.light,
    'standard dark': kBrandFixtureSource.dark,
    'standard HC light': kBrandFixtureSource.highContrastLight,
    'standard HC dark': kBrandFixtureSource.highContrastDark,
    'CoUI light': coui.light,
    'CoUI dark': coui.dark,
    'CoUI HC light': coui.highContrastLight,
    'CoUI HC dark': coui.highContrastDark,
  };

  for (final entry in modes.entries) {
    test('${entry.key}: accent reads the tertiary fill pair', () {
      final scheme = entry.value();
      final accent = scheme.resolve(const CoreColor.token(CoreColors.accent));
      final onAccent = scheme.resolve(
        const CoreColor.token(CoreColors.onAccent),
      );
      final tertiary = scheme.resolve(
        const CoreColor.token(CoreColors.tertiary),
      );
      final onTertiary = scheme.resolve(
        const CoreColor.token(CoreColors.onTertiary),
      );

      expect(accent.argb, tertiary.argb);
      expect(onAccent.argb, onTertiary.argb);
      expect(accent.token, CoreColors.accent);
      expect(onAccent.token, CoreColors.onAccent);
    });
  }

  test('the retired monochrome set still resolves accent from tertiary', () {
    // Deprecated, kept compiling for its window: one case so a project
    // pinned to the old look keeps the alias it had.
    final scheme = CoreSemanticMappingSet.monochrome.light(
      kBrandFixturePalette,
    );

    expect(
      scheme.resolve(const CoreColor.token(CoreColors.accent)).argb,
      scheme.resolve(const CoreColor.token(CoreColors.tertiary)).argb,
    );
  });

  test('CoUI accent is primary, in every mode', () {
    for (final entry in modes.entries.where((e) => e.key.startsWith('CoUI'))) {
      final scheme = entry.value();
      final accent = scheme.resolve(const CoreColor.token(CoreColors.accent));
      final onAccent = scheme.resolve(
        const CoreColor.token(CoreColors.onAccent),
      );

      expect(accent.argb, scheme.primary.argb, reason: entry.key);
      expect(onAccent.argb, scheme.onPrimary!.argb, reason: entry.key);
    }
  });

  test('a chromatic brand accent is its own tertiary, not its primary', () {
    // The control for the test above: on a palette with a third hue the
    // alias does not collapse onto primary, so "CoUI accent is primary" is
    // a fact about CoUI's tables, not about the alias.
    final light = kBrandFixtureSource.light();
    final dark = kBrandFixtureSource.dark();

    expect(
      light.resolve(const CoreColor.token(CoreColors.accent)).argb,
      isNot(light.primary.argb),
    );
    expect(
      dark.resolve(const CoreColor.token(CoreColors.accent)).argb,
      isNot(dark.primary.argb),
    );
  });

  test('stylesheet copies accent from tertiary in every mode', () {
    final cases = <Map<String, String> Function()>[
      () => PrimitiveCssGenerator.generateSemanticLight(kBrandFixturePalette),
      () => PrimitiveCssGenerator.generateSemanticDark(kBrandFixturePalette),
      () => PrimitiveCssGenerator.generateSemanticHighContrastLight(
        kBrandFixturePalette,
      ),
      () => PrimitiveCssGenerator.generateSemanticHighContrastDark(
        kBrandFixturePalette,
      ),
      for (final brightness in CoreBrightness.values)
        for (final highContrast in [false, true])
          () => PrimitiveCssGenerator.semanticVarsFor(
            coui,
            brightness,
            highContrast: highContrast,
          ),
    ];

    expect(cases, hasLength(8));
    for (final build in cases) {
      final css = build();
      expect(css['--coui-accent'], css['--coui-tertiary']);
      expect(css['--coui-on-accent'], css['--coui-on-tertiary']);
    }
  });
}
