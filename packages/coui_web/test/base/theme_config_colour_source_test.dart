import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

import '../helpers/brand_fixture.dart';

/// The primitive declarations of [css]'s base `:root` block, by name.
///
/// Read off the section the generator labels, so a semantic variable that
/// happens to share a prefix with a ramp (`--coui-primary-container`) is
/// never counted as a primitive.
Map<String, String> _primitivesIn(String css) {
  final start = css.indexOf('/* Primitive Colors */');
  final end = css.indexOf('/* Semantic Colors', start);
  expect(start, isNonNegative, reason: 'the base block has no primitives');
  expect(end, greaterThan(start), reason: 'the primitive section never ends');

  return {
    for (final m in RegExp(
      '(--coui-[a-z0-9-]+): ([0-9]+ [0-9]+ [0-9]+);',
    ).allMatches(css.substring(start, end)))
      m[1]!: m[2]!,
  };
}

/// Every stylesheet a page can be served, concatenated.
String _everySheet(ThemeConfig config) =>
    config.cssVariables +
    config.cssVariablesDark +
    config.darkVariableBlock +
    config.surfaceStyleVariableBlocks;

// The retired pair is read here and nowhere else in this package: the last
// group shows the deprecation window keeps the old look reproducible, and
// it goes when the pair does.
// ignore: deprecated_member_use
final PrimitiveColors _retiredPalette = CouiColorPresets.defaultPalette;

// The retired mapping, read for the same group as [_retiredPalette].
// ignore: deprecated_member_use
const CoreSemanticMappingSet _retiredMapping = CouiColorPresets.defaultMapping;

void main() {
  group('the CoUI theme states its fixed palette', () {
    final config = ThemeConfig.defaults();

    test('the primitive section is the fixed palette and nothing else', () {
      final emitted = _primitivesIn(config.cssVariables);

      expect(
        emitted,
        PrimitiveCssGenerator.primitiveVars(CouiColorPresets.source),
      );
      expect(emitted, hasLength(CouiColorPresets.palette.primitives.length));
    });

    test('a step carries the palette hex, not a regeneration of it', () {
      // Anchors from the designer's table, written as channels — checked
      // against the values themselves rather than against the generator,
      // which the test above already compares with.
      final emitted = _primitivesIn(config.cssVariables);

      expect(emitted['--coui-neutral-50'], '249 250 251'); // #F9FAFB
      expect(emitted['--coui-neutral-900'], '42 43 44'); // #2A2B2C
      expect(emitted['--coui-neutral-1050'], '15 16 17'); // #0F1011
      expect(emitted['--coui-base-white'], '255 255 255');
      expect(emitted['--coui-base-black'], '0 0 0');
    });

    test('there is no primary, secondary or tertiary ramp', () {
      // All three read the neutral ramp (#6135); a ramp of their own would
      // put one hex under two names.
      final ramps = _primitivesIn(config.cssVariables).keys.where(
        (name) =>
            name.startsWith('--coui-primary-') ||
            name.startsWith('--coui-secondary-') ||
            name.startsWith('--coui-tertiary-'),
      );

      expect(ramps, isEmpty);
    });

    test('dark mode states the same primitives', () {
      // A primitive is a colour, not a role, so it does not change with
      // the mode — only the semantic slots that point at it do.
      expect(
        _primitivesIn(config.cssVariablesDark),
        _primitivesIn(config.cssVariables),
      );
    });

    test('no generated-palette name is left in any sheet', () {
      // The names a generated palette publishes (`--coui-neutral-grey`,
      // `--coui-primary-base`, …) are gone from the CoUI theme rather than
      // kept as aliases. Taken from a generated palette rather than
      // written out, so the list is the real vocabulary, not a guess at it.
      final sheet = _everySheet(config);
      final generatedNames = PrimitiveCssGenerator.generate(
        kBrandFixturePalette,
      ).keys;

      expect(generatedNames, isNotEmpty);
      for (final name in generatedNames) {
        expect(sheet, isNot(contains('$name:')), reason: name);
      }
    });
  });

  group('a brand palette keeps the vocabulary it always published', () {
    final config = ThemeConfig(kBrandFixturePalette);

    test('its primitive section is the generated scale', () {
      final emitted = _primitivesIn(config.cssVariables);

      expect(emitted, PrimitiveCssGenerator.generate(kBrandFixturePalette));
      expect(emitted.keys, contains('--coui-primary-base'));
      expect(emitted.keys, isNot(contains('--coui-neutral-50')));
    });

    test('its semantic slots read its own palette', () {
      expect(
        config.semanticLightVars,
        PrimitiveCssGenerator.generateSemanticLight(kBrandFixturePalette),
      );
      expect(
        config.semanticDarkVars,
        PrimitiveCssGenerator.generateSemanticDark(kBrandFixturePalette),
      );
      expect(
        config.semanticLightVars,
        isNot(ThemeConfig.defaults().semanticLightVars),
        reason: 'a brand config rendered the CoUI look',
      );
    });
  });

  group('the retired look stays reproducible for the deprecation window', () {
    test('the old palette through the old mapping renders the old look', () {
      final retired = ThemeConfig(_retiredPalette, mapping: _retiredMapping);

      expect(
        retired.semanticLightVars,
        PrimitiveCssGenerator.generateSemanticLight(
          _retiredPalette,
          mapping: _retiredMapping,
        ),
      );
      expect(
        retired.semanticDarkVars,
        PrimitiveCssGenerator.generateSemanticDark(
          _retiredPalette,
          mapping: _retiredMapping,
        ),
      );
      // The mapping has to travel with the palette — a config that dropped
      // it would read the standard mapping and still look plausible.
      expect(
        retired.semanticLightVars,
        isNot(ThemeConfig(_retiredPalette).semanticLightVars),
        reason: 'the mapping argument did not reach the stylesheet',
      );
      expect(
        retired.semanticLightVars,
        isNot(ThemeConfig.defaults().semanticLightVars),
        reason: 'the retired look is the CoUI look — nothing changed',
      );
    });
  });
}
