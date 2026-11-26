// CoUI's fixed palette carries only what its semantics read.
//
// A colour reachable in the palette but not through the mapping is a
// colour the four modes never had to answer for — bind it and it renders
// the same in light, dark and both high-contrast modes. The generated
// palette CoUI used to ship had two such ramps (a blue `primary` and a
// purple `secondary` its monochrome mapping never reached), and the
// project's own documentation described that blue as the brand colour for
// a long time, which is exactly how such a ramp gets bound.
//
// The fixed palette closes that: every ramp it carries is read by some
// semantic slot in some mode, so none of them is a bystander, and no slot
// reads a colour that is not one of its 67 primitives. The Figma half of
// the same rule is the exporter's publish visibility — a ramp no alias
// reads is hidden — which this test makes a no-op for CoUI.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// Every hex the four modes of [source] resolve to.
Set<String> _reachable(CoreSchemeSource source) => {
  for (final scheme in [
    source.light(),
    source.dark(),
    source.highContrastLight(),
    source.highContrastDark(),
  ])
    ...scheme.toMap().values,
};

/// [source]'s primitives grouped by family (`neutral`, `primary`, …,
/// `base`) — the unit the Figma export's publish visibility decides on.
Map<String, Set<String>> _families(CoreSchemeSource source) {
  final families = <String, Set<String>>{};
  for (final entry in source.primitives.entries) {
    families
        .putIfAbsent(entry.key.split('/').first, () => {})
        .add(entry.value.toHex());
  }
  return families;
}

void main() {
  group("CoUI's own palette", () {
    const source = CouiColorPresets.source;
    final reachable = _reachable(source);
    final families = _families(source);

    test('carries the six families it is defined with', () {
      // Guards the per-family loop below against passing on a grouping
      // that silently produced fewer families.
      expect(families.keys, [
        'neutral',
        'success',
        'info',
        'warning',
        'error',
        'base',
      ]);
    });

    for (final family in [
      'neutral',
      'success',
      'info',
      'warning',
      'error',
      'base',
    ]) {
      test('the $family ramp is read by some slot', () {
        expect(
          families[family]!.intersection(reachable),
          isNotEmpty,
          reason:
              'no semantic slot in any mode reads the $family ramp, so it '
              'is a colour the modes never had to answer for',
        );
      });
    }

    test('no slot in any mode reads a colour outside the palette', () {
      // The category and syntax tones count as in: they are the brand-less
      // shared groups every brand's category and syntax slots read, kept
      // out of CoUI's own vocabulary on purpose (`CoreCategoryPalette`,
      // `CoreSyntaxPalette`).
      final palette = {
        for (final hexes in families.values) ...hexes,
        for (final tone in CoreCategoryPalette.primitives.values) tone.toHex(),
        for (final tone in CoreSyntaxPalette.primitives.values) tone.toHex(),
      };

      expect(reachable, isNotEmpty);
      expect(reachable.difference(palette), isEmpty);
    });
  });

  test('a generated brand read through the standard mapping reaches every '
      'ramp it carries', () {
    // The same question asked of the brand path, so the CoUI answer above
    // is a fact about CoUI's palette and mapping rather than about the way
    // this test groups and looks for colours.
    final reachable = _reachable(kBrandFixtureSource);
    final families = _families(kBrandFixtureSource);

    expect(families, hasLength(8));
    for (final entry in families.entries) {
      expect(
        entry.value.intersection(reachable),
        isNotEmpty,
        reason: entry.key,
      );
    }
  });
}
