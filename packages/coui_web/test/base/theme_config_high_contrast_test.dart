import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

import '../helpers/brand_fixture.dart';

String _rgb(CoreColor c) => '${c.red} ${c.green} ${c.blue}';

/// `R G B` of a [CoreColorScheme.toMap] value — `#RRGGBB`, or `#AARRGGBB`
/// for a translucent slot. The CSS variables carry the channels only.
String _rgbOfHex(String hex) {
  final value = int.parse(hex.substring(hex.length - 6), radix: 16);
  return '${value >> 16 & 0xFF} ${value >> 8 & 0xFF} ${value & 0xFF}';
}

/// The page tones — the slots several components tell apart by background
/// alone, with no border to fall back on.
const _surfaceTones = [
  'surface',
  'surface-dim',
  'surface-bright',
  'surface-container-lowest',
  'surface-container-low',
  'surface-container',
  'surface-container-high',
  'surface-container-highest',
];

/// The light high-contrast block's selector. The `:where(:not(…))` keeps it
/// off an explicitly dark page without adding specificity.
const _lightSelector = ':root:root:where(:not([data-theme="dark"]))';

/// The dark high-contrast block's selector.
const _darkSelector = ':root:root[data-theme="dark"]';

/// Each high-contrast block, by its selector and the mode it raises.
const List<(String, CoreBrightness)> _modes = [
  (_lightSelector, CoreBrightness.light),
  (_darkSelector, CoreBrightness.dark),
];

/// A standard reading whose light raise governs one slot the dark raise
/// leaves alone — the shape that lets a light block painting on a dark page
/// show. CoUI's own source has that shape too (its light raise governs
/// category slots its dark one does not — gray's on-container moves only
/// in light), and the explicit-mode cascade tests below hold it for CoUI as
/// for this reading. The standard raise writes the same slots in both
/// modes, so this states the shape on a brand palette as well.
CoreColorScheme _raiseLopsided(
  CoreColorScheme base,
  PrimitiveColors palette,
  CoreBrightness brightness,
) {
  final raised = CoreSemanticMapping.raiseContrast(base, palette, brightness);

  return brightness == .light
      ? raised.copyWith(inversePrimary: palette.primary.darkest)
      : raised;
}

CoreColorScheme _lopsidedHighContrastLight(PrimitiveColors palette) =>
    _raiseLopsided(CoreSemanticMapping.light(palette), palette, .light);

CoreColorScheme _lopsidedHighContrastDark(PrimitiveColors palette) =>
    _raiseLopsided(CoreSemanticMapping.dark(palette), palette, .dark);

const _lopsided = CoreSemanticMappingSet(
  light: CoreSemanticMapping.light,
  dark: CoreSemanticMapping.dark,
  highContrastLight: _lopsidedHighContrastLight,
  highContrastDark: _lopsidedHighContrastDark,
  raiseContrast: _raiseLopsided,
);

/// The declarations of one rule body, by variable.
Map<String, String> _declarations(String body) => {
  for (final declaration in body.split(';').where((d) => d.contains(':')))
    declaration.substring(0, declaration.indexOf(':')): declaration.substring(
      declaration.indexOf(':') + 1,
    ),
};

void main() {
  const source = CouiColorPresets.source;
  final css = ThemeConfig.defaults().cssVariables;

  // The two kinds of config the block is generated for — CoUI's own
  // colours and a brand's generated palette — each with the source its
  // block has to come from.
  final configs = <(String, ThemeConfig, CoreSchemeSource)>[
    ('CoUI', ThemeConfig.defaults(), source),
    (
      'brand',
      ThemeConfig(kBrandFixturePalette),
      CoreSemanticMappingSet.standard.bind(kBrandFixturePalette),
    ),
  ];

  // The selectors carry a doubled `:root` so the preference outranks a
  // surface style that states the same slot; matching on it here keeps this
  // file from passing on a stylesheet where that rank was lost.
  RegExp block(String selector) => RegExp(
    '@media \\(prefers-contrast:more\\)\\{${RegExp.escape(selector)}\\{(.*?)\\}\\}',
    dotAll: true,
  );

  String bodyOf(String stylesheet, String selector) {
    final match = block(selector).firstMatch(stylesheet);
    expect(match, isNotNull, reason: 'no high-contrast block for $selector');
    return match!.group(1)!;
  }

  group('high-contrast overrides are emitted', () {
    test('a block exists for each mode', () {
      expect(block(_lightSelector).firstMatch(css), isNotNull);
      expect(block(_darkSelector).firstMatch(css), isNotNull);
    });

    test('values come from the shared Core source', () {
      // Emitting a hand-written second palette here is how the two
      // platforms would drift; this asserts the Web block is the same
      // resolution Flutter reads. `defaults()` renders the CoUI look, so
      // the expectation reads CoUI's OWN source — the standard builders
      // would be a different brand's block.
      final light = source.highContrastLight().resolved(.light);
      final lightBody = bodyOf(css, _lightSelector);
      expect(lightBody, contains('--coui-outline:${_rgb(light.outline)};'));
      expect(
        lightBody,
        contains('--coui-on-surface:${_rgb(light.onSurface)};'),
      );
      expect(lightBody, contains('--coui-primary:${_rgb(light.primary)};'));

      final dark = source.highContrastDark().resolved(.dark);
      final darkBody = bodyOf(css, _darkSelector);
      expect(darkBody, contains('--coui-outline:${_rgb(dark.outline)};'));
      expect(darkBody, contains('--coui-on-surface:${_rgb(dark.onSurface)};'));
    });

    test('dark block differs from light', () {
      expect(
        bodyOf(css, _lightSelector),
        isNot(equals(bodyOf(css, _darkSelector))),
      );
    });
  });

  group('what the override deliberately omits', () {
    test('surface tones are not flattened', () {
      // Only the slots the raise governs are emitted; surfaces inherit
      // from :root. Overriding them would erase the background-tone
      // boundary that several components rely on instead of a border. Both
      // kinds of config, both modes, every page tone — the raise leaves
      // them to the base, so the block must never write one.
      for (final (name, config, _) in configs) {
        for (final (selector, _) in _modes) {
          final body = bodyOf(config.cssVariables, selector);
          for (final tone in _surfaceTones) {
            expect(
              body,
              isNot(contains('--coui-$tone:')),
              reason: '$name $selector writes $tone',
            );
          }
        }
      }
    });

    test('the override set is exactly the slots the raise governs', () {
      // A full second palette in the media query is the drift risk this
      // design avoids, and a hand-kept list of "slots high contrast
      // touches" is the opposite risk: it falls behind the mapping, and a
      // raised slot it does not name renders raised on Flutter and normal
      // here. So the block is every variable the source's raise writes —
      // no more, no fewer — in both modes, for CoUI's colours and for a
      // brand's alike. "Writes", not "changes": the Flutter seat lets a
      // slot the raise pins to its normal value outrank a surface style
      // too (Core's `semanticVarsRaised` tests pin those slots).
      for (final (name, config, configSource) in configs) {
        for (final (selector, brightness) in _modes) {
          final normal = PrimitiveCssGenerator.semanticVarsFor(
            configSource,
            brightness,
          );
          final raised = PrimitiveCssGenerator.semanticVarsFor(
            configSource,
            brightness,
            highContrast: true,
          );
          final expected = {
            for (final entry in PrimitiveCssGenerator.semanticVarsRaised(
              configSource,
              brightness,
            ).entries)
              '${entry.key}:${entry.value}',
          };
          final declarations = bodyOf(
            config.cssVariables,
            selector,
          ).split(';').where((d) => d.isNotEmpty);

          expect(declarations.toSet(), expected, reason: '$name $selector');
          expect(
            declarations,
            hasLength(expected.length),
            reason: '$name $selector states a slot twice',
          );
          // Every variable whose value high contrast changes is among
          // them — read off the two full schemes, not off the generator.
          expect(
            declarations.toSet(),
            containsAll(<String>{
              for (final entry in raised.entries)
                if (normal[entry.key] != entry.value)
                  '${entry.key}:${entry.value}',
            }),
            reason: '$name $selector misses a changed slot',
          );
          expect(expected, isNotEmpty, reason: '$name $selector raises none');
          expect(
            expected.length,
            lessThan(normal.length),
            reason: '$name $selector: overrides, not a copy',
          );
        }
      }
    });
  });

  group('each explicit mode reads its own high-contrast block', () {
    // The light block must not paint on an explicitly dark page. If it
    // matches there it outranks the plain dark rule, and the dark block
    // only restates its own slots — so a slot the light raise governs and
    // the dark one does not would show its light high-contrast value on a
    // dark page. Checked as the cascade a browser would compute, against
    // the scheme the theme seat resolves, for CoUI's colours, a brand's,
    // the retired monochrome look, and a reading whose light raise governs
    // a slot its dark raise does not.
    // The retired look still renders until it is removed, so its
    // stylesheet is held to the same cascade — which means naming it.
    // ignore: deprecated_member_use
    final retiredPalette = CouiColorPresets.defaultPalette;
    // Same reason: the retired look's mapping, paired with its palette.
    // ignore: deprecated_member_use
    const retiredMapping = CouiColorPresets.defaultMapping;
    final cascadeConfigs = <(String, ThemeConfig, CoreSchemeSource)>[
      ...configs,
      (
        'monochrome (deprecated)',
        ThemeConfig(retiredPalette, mapping: retiredMapping),
        retiredMapping.bind(retiredPalette),
      ),
      (
        'lopsided raise',
        ThemeConfig(kBrandFixturePalette, mapping: _lopsided),
        _lopsided.bind(kBrandFixturePalette),
      ),
    ];

    // Which high-contrast blocks apply on a page that states [b] with
    // `data-theme`, in cascade order. A selector rules a page out only by
    // requiring the other `data-theme` value or by negating this one —
    // anything else, a bare `:root` included, matches. The blocks that can
    // both match a page never tie on specificity in a way that reverses
    // their source order, so source order stands in for the cascade.
    List<Map<String, String>> blocksFor(String css, CoreBrightness b) {
      final (stated, other) = switch (b) {
        .light => ('light', 'dark'),
        .dark => ('dark', 'light'),
      };
      final negation = RegExp(r':not\(\[data-theme="(\w+)"\]\)');

      return [
        for (final match in RegExp(
          r'@media \(prefers-contrast:more\)\{([^{]+)\{([^}]*)\}\}',
        ).allMatches(css))
          if (!negation
                  .allMatches(match[1]!)
                  .any((negated) => negated[1] == stated) &&
              !match[1]!
                  .replaceAll(negation, '')
                  .contains('[data-theme="$other"]'))
            _declarations(match[2]!),
      ];
    }

    test('the matcher reads the two selectors the way a browser would', () {
      // The cascade below is only as good as this. A bare `:root` block
      // matches every page, and the matcher has to say so — reading only
      // the attributes a selector names would wave a light block through
      // as "not dark" and hide the very leak the group exists for.
      final css = ThemeConfig.defaults().cssVariables;
      expect(
        blocksFor(css, .light).single,
        _declarations(bodyOf(css, _lightSelector)),
      );
      expect(
        blocksFor(css, .dark).single,
        _declarations(bodyOf(css, _darkSelector)),
      );
      const bare = '@media (prefers-contrast:more){:root:root{--coui-x:1;}}';
      for (final brightness in CoreBrightness.values) {
        expect(blocksFor(bare, brightness), hasLength(1));
      }
    });

    test('the lopsided reading really governs a light-only slot', () {
      // The premise of the last config: without a light-only slot it
      // would pass whether or not the light block is kept off dark pages.
      final source = _lopsided.bind(kBrandFixturePalette);
      expect(
        PrimitiveCssGenerator.semanticVarsRaised(
          source,
          .light,
        ).keys.toSet().difference(
          PrimitiveCssGenerator.semanticVarsRaised(
            source,
            .dark,
          ).keys.toSet(),
        ),
        isNotEmpty,
      );
    });

    for (final (name, config, configSource) in cascadeConfigs) {
      for (final brightness in CoreBrightness.values) {
        test('$name, ${brightness.name}, with and without a surface style', () {
          final css = config.cssVariables;
          for (final id in CoreSurfaceStyleId.values) {
            final constraint = resolveThemeRecipe(
              surfaceStyle: id,
            ).colorConstraint;
            final styleBlock = constraint.isIdentity
                ? ''
                : config.surfaceStyleBlock(id, constraint);
            // The light rule is the block's first; anchoring keeps it from
            // matching the tail of the dark rule, which contains it.
            final styleRule = switch (brightness) {
              .light => RegExp(
                '^${RegExp.escape('[data-coui-style="${id.name}"]')}'
                r'\{(.*?)\}',
              ),
              .dark => RegExp(
                RegExp.escape(
                      '[data-theme="dark"][data-coui-style="${id.name}"]',
                    ) +
                    r'\{(.*?)\}',
              ),
            }.firstMatch(styleBlock);

            // The page's own mode, then the style (it outranks the plain
            // rule), then every high-contrast block that matches (each
            // outranks the style).
            final cascade = {
              ...PrimitiveCssGenerator.semanticVarsFor(
                configSource,
                brightness,
              ),
              if (styleRule != null) ..._declarations(styleRule[1]!),
              for (final block in blocksFor(css, brightness)) ...block,
            };
            final seat = PrimitiveCssGenerator.semanticVars(
              resolveThemeSchemeFrom(
                configSource,
                brightness: brightness,
                highContrast: true,
                surfaceStyle: id,
              ).resolved(brightness),
            );

            for (final key in seat.keys) {
              expect(
                cascade[key],
                seat[key],
                reason: '$name ${brightness.name} ${id.name} $key',
              );
            }
          }
        });
      }
    }
  });

  group('every slot the scheme raises reaches the Web', () {
    test('read off the scheme itself, not off the emitter', () {
      // The set test above compares the block with the generator's own
      // walk; this one reads the two schemes directly, so a vocabulary
      // entry that pointed at the wrong slot would show up here even
      // though the block and the walk agreed with each other.
      for (final (selector, brightness) in _modes) {
        final normal = switch (brightness) {
          .light => source.light(),
          .dark => source.dark(),
        }.resolved(brightness).toMap();
        final raised = switch (brightness) {
          .light => source.highContrastLight(),
          .dark => source.highContrastDark(),
        }.resolved(brightness).toMap();
        final changed = [
          for (final slot in normal.keys)
            if (raised[slot] != normal[slot]) slot,
        ];
        final body = bodyOf(css, selector);

        expect(changed, isNotEmpty, reason: selector);
        for (final slot in changed) {
          expect(
            body,
            contains('--coui-$slot:${_rgbOfHex(raised[slot]!)};'),
            reason: '$selector leaves the raised $slot at its normal value',
          );
        }
      }
    });

    test('the container and inverse tones are raised too', () {
      // CoUI's high-contrast table raises the `on-*-container` tones and
      // the inverse family; a list of slots written by hand is exactly how
      // those would stay at their normal value on the Web only.
      final light = bodyOf(css, _lightSelector);
      for (final slot in [
        '--coui-on-primary-container:',
        '--coui-on-error-container:',
        '--coui-secondary-container:',
        '--coui-inverse-surface:',
        '--coui-inverse-primary:',
      ]) {
        expect(light, contains(slot));
      }

      final dark = bodyOf(css, _darkSelector);
      for (final slot in [
        '--coui-on-primary-container:',
        '--coui-inverse-surface:',
        '--coui-inverse-on-surface:',
        '--coui-inverse-primary:',
      ]) {
        expect(dark, contains(slot));
      }
    });
  });
}
