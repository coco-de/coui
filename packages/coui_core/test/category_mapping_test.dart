// The category slots as each mapping authors them — every source, every
// mode, and both doors into high contrast.
//
// Reads the AUTHORED scheme, before `resolved()`. Resolving fills an unset
// slot from CoUI's normal values, so a builder or a raise that forgot the
// category slots would still resolve to colours — the normal ones — and pass
// any check made after it. That is also why the two doors agreeing proves
// nothing here: a raise that skips the category slots keeps the normal
// values through both. The expectation is the category table itself, read
// with each mapping's own pure white and black.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// A source, the white and black its strong labels read, and — for a
/// mapping on a generated palette — the off-white those labels must not
/// read.
typedef _Source = ({
  CoreSchemeSource source,
  CoreColor white,
  CoreColor black,
  CoreColor? offWhite,
});

/// A brand that only moves its light page to pure white — Unibook's shape:
/// a light builder bent with `copyWith`, the rest the standard mapping, and
/// high contrast raised from its own light.
CoreColorScheme _pureWhitePageLight(PrimitiveColors c) =>
    CoreSemanticMapping.light(c).copyWith(surface: c.neutral.pureWhite);

CoreColorScheme _pureWhitePageHighContrastLight(PrimitiveColors c) =>
    CoreSemanticMapping.raiseContrast(_pureWhitePageLight(c), c, .light);

const _pureWhitePage = CoreSemanticMappingSet(
  light: _pureWhitePageLight,
  dark: CoreSemanticMapping.dark,
  highContrastLight: _pureWhitePageHighContrastLight,
  highContrastDark: CoreSemanticMapping.highContrastDark,
  raiseContrast: CoreSemanticMapping.raiseContrast,
);

final NeutralScale _n = kBrandFixturePalette.neutral;

/// CoUI's own source, then every mapping a generated palette ships through.
final _kSources = <String, _Source>{
  'CoUI': (
    source: CouiColorPresets.source,
    white: CouiColorPresets.palette.white,
    black: CouiColorPresets.palette.black,
    offWhite: null,
  ),
  'standard': (
    source: kBrandFixtureSource,
    white: _n.pureWhite,
    black: _n.pureBlack,
    offWhite: _n.white,
  ),
  // The retired monochrome reading stands in for any brand with a set of
  // its own built on the standard one.
  'monochrome': (
    source: CoreSemanticMappingSet.monochrome.bind(kBrandFixturePalette),
    white: _n.pureWhite,
    black: _n.pureBlack,
    offWhite: _n.white,
  ),
  'pure-white page': (
    source: _pureWhitePage.bind(kBrandFixturePalette),
    white: _n.pureWhite,
    black: _n.pureBlack,
    offWhite: _n.white,
  ),
};

const List<(CoreBrightness, bool)> _kModes = [
  (CoreBrightness.light, false),
  (CoreBrightness.dark, false),
  (CoreBrightness.light, true),
  (CoreBrightness.dark, true),
];

String _label((CoreBrightness, bool) mode) =>
    '${mode.$1.name}${mode.$2 ? ' high contrast' : ''}';

/// Every door into one mode: the builder, and for high contrast also the
/// raise applied to the normal builder — the one the theme seat takes.
Map<String, CoreColorScheme> _doors(
  CoreSchemeSource source,
  (CoreBrightness, bool) mode,
) => switch (mode) {
  (.light, false) => {'builder': source.light()},
  (.dark, false) => {'builder': source.dark()},
  (.light, true) => {
    'builder': source.highContrastLight(),
    'raise': source.raiseContrast(source.light(), .light),
  },
  (.dark, true) => {
    'builder': source.highContrastDark(),
    'raise': source.raiseContrast(source.dark(), .dark),
  },
};

/// What the table says [slot] of [color] is in [mode] for [entry].
CoreColor _expected(
  _Source entry,
  CoreCategoryColor color,
  CoreCategorySlot slot,
  (CoreBrightness, bool) mode,
) => CoreCategoryPalette.valueOf(
  color,
  slot,
  mode.$1,
  highContrast: mode.$2,
  white: entry.white,
  black: entry.black,
);

/// The category slot names among the `--coui-*` keys [vars] carries.
Set<String> _categoryNames(Map<String, String> vars) {
  final names = {
    for (final color in CoreCategoryColor.values)
      for (final slot in CoreCategorySlot.values) slot.cssName(color),
  };

  return {
    for (final key in vars.keys)
      if (names.contains(key.substring('--coui-'.length)))
        key.substring('--coui-'.length),
  };
}

void main() {
  for (final MapEntry(key: name, value: entry) in _kSources.entries) {
    group('$name states every category slot as the table does', () {
      for (final mode in _kModes) {
        for (final MapEntry(key: door, value: scheme) in _doors(
          entry.source,
          mode,
        ).entries) {
          test('${_label(mode)} — $door', () {
            final drift = <String>[];
            for (final color in CoreCategoryColor.values) {
              for (final slot in CoreCategorySlot.values) {
                final got = color.token(slot).read(scheme);
                final want = _expected(entry, color, slot, mode);
                if (got?.argb != want.argb) {
                  drift.add(
                    '${slot.cssName(color)}: table ${want.toHex()}, '
                    'scheme ${got?.toHex()}',
                  );
                }
              }
            }

            expect(drift, isEmpty, reason: drift.join('\n'));
          });
        }
      }

      if (entry.offWhite case final offWhite?) {
        test('the strong label is pure white, never the off-white', () {
          // On the lowest light fill the off-white falls under the 3.5:1
          // the strong label is allowed.
          expect(offWhite.argb, isNot(entry.white.argb));
          for (final mode in _kModes) {
            for (final scheme in _doors(entry.source, mode).values) {
              for (final color in CoreCategoryColor.values) {
                expect(
                  color.onFill.read(scheme)?.argb,
                  isNot(offWhite.argb),
                  reason: '${color.onFill.name} ${_label(mode)}',
                );
              }
            }
          }
        });
      }
    });
  }

  // "Governs" is what the raise writes, read off it by the generator the
  // Web block uses. The expected set is computed from the table — the slots
  // whose value high contrast changes — never a count copied from it.
  group('high contrast governs the category slots', () {
    test('CoUI: exactly the slots whose value the table moves', () {
      final coui = _kSources['CoUI']!;
      for (final brightness in CoreBrightness.values) {
        final moved = {
          for (final color in CoreCategoryColor.values)
            for (final slot in CoreCategorySlot.values)
              if (_expected(coui, color, slot, (brightness, false)).argb !=
                  _expected(coui, color, slot, (brightness, true)).argb)
                slot.cssName(color),
        };

        expect(moved, isNotEmpty);
        expect(
          _categoryNames(
            PrimitiveCssGenerator.semanticVarsRaised(coui.source, brightness),
          ),
          moved,
          reason: brightness.name,
        );
      }
    });

    test('a generated palette: every category slot, in both modes', () {
      // The standard raise writes the whole table, so a style that bends a
      // category slot never outlives the preference.
      final every = {
        for (final color in CoreCategoryColor.values)
          for (final slot in CoreCategorySlot.values) slot.cssName(color),
      };
      for (final MapEntry(key: name, value: entry) in _kSources.entries) {
        // CoUI raises by its own table's differences, above.
        if (identical(entry.source, CouiColorPresets.source)) continue;
        for (final brightness in CoreBrightness.values) {
          expect(
            _categoryNames(
              PrimitiveCssGenerator.semanticVarsRaised(
                entry.source,
                brightness,
              ),
            ),
            every,
            reason: '$name ${brightness.name}',
          );
        }
      }
    });
  });
}
