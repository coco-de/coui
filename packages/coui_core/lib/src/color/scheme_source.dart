import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/primitive_colors.dart';
import 'package:coui_core/src/color/semantic_mapping_set.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// A palette already bound to the mapping that reads it — the unit every
/// colour seat takes (the theme seat, the Web `:root` blocks, the Figma
/// export).
///
/// Why the pair travels as one value: a palette alone cannot say what a
/// semantic slot MEANS, and a mapping alone has nothing to read. Seats that
/// took the two separately could be handed a palette and a mapping that
/// were never meant for each other — a CoUI mapping over a brand's
/// generated palette, say — and the mistake would only show as wrong
/// colours. The methods here take no palette argument, so that pairing is
/// decided once, where the source is built, and a seat cannot redo it.
///
/// The invariant every implementation keeps: `highContrastLight()` equals
/// `raiseContrast(light(), CoreBrightness.light)`, and the dark pair
/// likewise. Mode-enumerating consumers (the Figma export, the Web
/// `@media (prefers-contrast: more)` block) read the four builders; the
/// theme seat raises an already style-bent base through [raiseContrast].
/// If the two disagreed, high contrast would render differently depending
/// on which door it came through.
abstract interface class CoreSchemeSource {
  /// The light-mode scheme.
  CoreColorScheme light();

  /// The dark-mode scheme.
  CoreColorScheme dark();

  /// The high-contrast light scheme — see the class doc for the invariant
  /// tying this to [raiseContrast].
  CoreColorScheme highContrastLight();

  /// The high-contrast dark scheme — see [highContrastLight].
  CoreColorScheme highContrastDark();

  /// Raises the contrast of an arbitrary [base] for [brightness].
  ///
  /// Takes a scheme rather than rebuilding one so that an axis applied
  /// earlier (a surface style bending the page) survives on the slots high
  /// contrast does not govern, while the slots it does govern are decided
  /// here.
  CoreColorScheme raiseContrast(
    CoreColorScheme base,
    CoreBrightness brightness,
  );

  /// The primitive vocabulary: `'<family>/<step>'` → colour, in emit order.
  ///
  /// The Web writes each entry as `--coui-<family>-<step>`; the Figma
  /// export writes it as `color/<brandId>/<family>/<step>`. One vocabulary
  /// for both, so the CSS name and the Figma variable name cannot be
  /// derived differently.
  ///
  /// The brand's own colours only. The category and syntax primitives are
  /// the same in every brand and live outside this vocabulary, in
  /// `CoreCategoryPalette.primitives` and `CoreSyntaxPalette.primitives`; a
  /// source states its category slots by calling
  /// `CoreCategoryPalette.applyTo` in its builders and its raise, and its
  /// syntax slots by calling `CoreSyntaxPalette.applyTo` in its builders.
  Map<String, CoreColor> get primitives;
}

/// A brand's [PrimitiveColors] read through a [CoreSemanticMappingSet].
///
/// Every brand that seeds a generated palette is this — the mapping
/// defaults to [CoreSemanticMappingSet.standard], and a brand with its own
/// interpretation states that set instead. Built by
/// [CoreSemanticMappingSet.bind].
@immutable
final class CorePrimitiveSchemeSource implements CoreSchemeSource {
  /// Creates a [CorePrimitiveSchemeSource].
  const CorePrimitiveSchemeSource(
    this.palette, [
    this.mapping = CoreSemanticMappingSet.standard,
  ]);

  /// The generated palette.
  final PrimitiveColors palette;

  /// How the semantic slots read [palette].
  final CoreSemanticMappingSet mapping;

  @override
  CoreColorScheme light() => mapping.light(palette);

  @override
  CoreColorScheme dark() => mapping.dark(palette);

  @override
  CoreColorScheme highContrastLight() => mapping.highContrastLight(palette);

  @override
  CoreColorScheme highContrastDark() => mapping.highContrastDark(palette);

  @override
  CoreColorScheme raiseContrast(
    CoreColorScheme base,
    CoreBrightness brightness,
  ) => mapping.raiseContrast(base, palette, brightness);

  /// The 64 generated primitives under their scale names
  /// (`neutral/pure-white` … `error/darkest`) — the names brands have
  /// always published, so a brand's CSS variables and Figma variables keep
  /// every name they had.
  @override
  Map<String, CoreColor> get primitives => {
    ..._neutralPrimitives(palette.neutral),
    ..._chromaticPrimitives('primary', palette.primary),
    ..._chromaticPrimitives('secondary', palette.secondary),
    ..._chromaticPrimitives('tertiary', palette.tertiary),
    ..._chromaticPrimitives('success', palette.success),
    ..._chromaticPrimitives('info', palette.info),
    ..._chromaticPrimitives('warning', palette.warning),
    ..._chromaticPrimitives('error', palette.error),
  };

  // `PrimitiveColors` has no value equality — two `generate` calls with the
  // same seeds are different objects — so a source compares its palette by
  // identity, exactly as `CoreBrand` always compared it.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CorePrimitiveSchemeSource &&
          palette == other.palette &&
          mapping == other.mapping);

  @override
  int get hashCode => Object.hash(palette, mapping);
}

Map<String, CoreColor> _neutralPrimitives(NeutralScale n) => {
  'neutral/pure-white': n.pureWhite,
  'neutral/white': n.white,
  'neutral/white-dark': n.whiteDark,
  'neutral/white-darker': n.whiteDarker,
  'neutral/grey-lightest': n.greyLightest,
  'neutral/grey-lighter': n.greyLighter,
  'neutral/grey-light': n.greyLight,
  'neutral/grey': n.grey,
  'neutral/grey-dark': n.greyDark,
  'neutral/grey-darker': n.greyDarker,
  'neutral/grey-darkest': n.greyDarkest,
  'neutral/black-lighter': n.blackLighter,
  'neutral/black-light': n.blackLight,
  'neutral/black': n.black,
  'neutral/pure-black': n.pureBlack,
};

Map<String, CoreColor> _chromaticPrimitives(
  String family,
  ChromaticScale scale,
) => {
  '$family/lightest': scale.lightest,
  '$family/lighter': scale.lighter,
  '$family/light': scale.light,
  '$family/base': scale.base,
  '$family/dark': scale.dark,
  '$family/darker': scale.darker,
  '$family/darkest': scale.darkest,
};
