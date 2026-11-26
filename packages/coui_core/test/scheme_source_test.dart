// CoreSchemeSource — the unit every colour seat takes — and the brand
// implementation, CorePrimitiveSchemeSource.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// The 64 primitive names a generated brand palette has always published —
/// frozen as written before the source type existed, so a change to the
/// brand vocabulary (a rename, a reorder) fails here instead of reaching
/// every brand's CSS variables and Figma variables.
const _kBrandPrimitiveNames = [
  'neutral/pure-white',
  'neutral/white',
  'neutral/white-dark',
  'neutral/white-darker',
  'neutral/grey-lightest',
  'neutral/grey-lighter',
  'neutral/grey-light',
  'neutral/grey',
  'neutral/grey-dark',
  'neutral/grey-darker',
  'neutral/grey-darkest',
  'neutral/black-lighter',
  'neutral/black-light',
  'neutral/black',
  'neutral/pure-black',
  'primary/lightest',
  'primary/lighter',
  'primary/light',
  'primary/base',
  'primary/dark',
  'primary/darker',
  'primary/darkest',
  'secondary/lightest',
  'secondary/lighter',
  'secondary/light',
  'secondary/base',
  'secondary/dark',
  'secondary/darker',
  'secondary/darkest',
  'tertiary/lightest',
  'tertiary/lighter',
  'tertiary/light',
  'tertiary/base',
  'tertiary/dark',
  'tertiary/darker',
  'tertiary/darkest',
  'success/lightest',
  'success/lighter',
  'success/light',
  'success/base',
  'success/dark',
  'success/darker',
  'success/darkest',
  'info/lightest',
  'info/lighter',
  'info/light',
  'info/base',
  'info/dark',
  'info/darker',
  'info/darkest',
  'warning/lightest',
  'warning/lighter',
  'warning/light',
  'warning/base',
  'warning/dark',
  'warning/darker',
  'warning/darkest',
  'error/lightest',
  'error/lighter',
  'error/light',
  'error/base',
  'error/dark',
  'error/darker',
  'error/darkest',
];

void main() {
  group('CorePrimitiveSchemeSource', () {
    test('reads the palette through its mapping in all four modes', () {
      final source = CoreSemanticMappingSet.standard.bind(kBrandFixturePalette);

      expect(
        source.light(),
        equals(CoreSemanticMapping.light(kBrandFixturePalette)),
      );
      expect(
        source.dark(),
        equals(CoreSemanticMapping.dark(kBrandFixturePalette)),
      );
      expect(
        source.highContrastLight(),
        equals(CoreSemanticMapping.highContrastLight(kBrandFixturePalette)),
      );
      expect(
        source.highContrastDark(),
        equals(CoreSemanticMapping.highContrastDark(kBrandFixturePalette)),
      );
    });

    test('raises a base through its mapping', () {
      final source = kBrandFixtureSource;
      final base = source.light();

      expect(
        source.raiseContrast(base, .light),
        equals(
          CoreSemanticMapping.raiseContrast(
            base,
            kBrandFixturePalette,
            .light,
          ),
        ),
      );
    });

    test('keeps the 64 brand primitive names, in order', () {
      expect(
        kBrandFixtureSource.primitives.keys.toList(),
        equals(_kBrandPrimitiveNames),
      );
    });

    test('defaults to the standard mapping', () {
      expect(
        CorePrimitiveSchemeSource(kBrandFixturePalette),
        equals(kBrandFixtureSource),
      );
    });

    test('compares by palette identity and mapping', () {
      final same = CorePrimitiveSchemeSource(kBrandFixturePalette);
      final otherMapping = CorePrimitiveSchemeSource(
        kBrandFixturePalette,
        const CoreSemanticMappingSet(
          light: CoreSemanticMapping.dark,
          dark: CoreSemanticMapping.dark,
          highContrastLight: CoreSemanticMapping.highContrastDark,
          highContrastDark: CoreSemanticMapping.highContrastDark,
          raiseContrast: CoreSemanticMapping.raiseContrast,
        ),
      );

      expect(kBrandFixtureSource, equals(same));
      expect(kBrandFixtureSource.hashCode, equals(same.hashCode));
      expect(kBrandFixtureSource, isNot(equals(otherMapping)));
    });
  });

  // The invariant every source keeps: the high-contrast builder equals the
  // raise applied to the normal builder. The Figma export and the Web
  // `@media` block read the builders; the theme seat raises a base. If the
  // two disagreed, high contrast would depend on which door it came through.
  group('CoreSchemeSource high-contrast invariant', () {
    final sources = <String, CoreSchemeSource>{
      'CoUI': CouiColorPresets.source,
      'brand (standard)': kBrandFixtureSource,
      // A brand that states its own set rather than the standard one — the
      // retired monochrome reading stands in for any such set.
      'brand (own set)': CoreSemanticMappingSet.monochrome.bind(
        kBrandFixturePalette,
      ),
    };

    for (final entry in sources.entries) {
      test('${entry.key}: both doors agree in both modes', () {
        final source = entry.value;
        final light = source.raiseContrast(source.light(), .light);
        final dark = source.raiseContrast(source.dark(), .dark);

        expect(source.highContrastLight(), equals(light));
        expect(source.highContrastLight().toMap(), equals(light.toMap()));
        expect(source.highContrastDark(), equals(dark));
        expect(source.highContrastDark().toMap(), equals(dark.toMap()));
      });
    }
  });

  group('resolveThemeSchemeFrom', () {
    test('is the seat resolveThemeScheme forwards a brand palette to', () {
      for (final brightness in CoreBrightness.values) {
        for (final highContrast in [false, true]) {
          for (final style in CoreSurfaceStyleId.values) {
            expect(
              resolveThemeScheme(
                kBrandFixturePalette,
                brightness: brightness,
                highContrast: highContrast,
                surfaceStyle: style,
              ),
              equals(
                resolveThemeSchemeFrom(
                  kBrandFixtureSource,
                  brightness: brightness,
                  highContrast: highContrast,
                  surfaceStyle: style,
                ),
              ),
              reason: '$brightness / hc=$highContrast / $style',
            );
          }
        }
      }
    });
  });
}
