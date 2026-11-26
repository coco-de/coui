import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/primitive_colors.dart';
import 'package:coui_core/src/color/scheme_source.dart';
import 'package:coui_core/src/color/semantic_mapping.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// Builds one mode's [CoreColorScheme] from a brand's [PrimitiveColors].
typedef CoreSchemeBuilder = CoreColorScheme Function(PrimitiveColors palette);

/// Raises the contrast of an already-built (possibly style-bent) scheme —
/// the signature of [CoreSemanticMapping.raiseContrast].
typedef CoreContrastRaiser =
    CoreColorScheme Function(
      CoreColorScheme base,
      PrimitiveColors palette,
      CoreBrightness brightness,
    );

/// A brand's complete Primitive → Semantic interpretation: the four mode
/// builders bundled as one value, so "which mapping does this brand use"
/// is a single field on the brand instead of four call sites that can
/// disagree.
///
/// Why the mapping is brand-owned at all: the palette states what colours
/// exist and the mapping states what each semantic slot means, and no
/// palette swap can express the second — a brand that keeps chromatic
/// primitives but resolves its primary family to neutrals needs a different
/// mapping, not a different palette. Two brands can share every primitive
/// and still disagree about `color/primary`.
///
/// A set reaches a seat bound to its palette: [bind] pairs the two into a
/// [CoreSchemeSource], which is what every seat takes.
@immutable
class CoreSemanticMappingSet {
  /// Creates a [CoreSemanticMappingSet].
  ///
  /// The four builders and [raiseContrast] must keep the invariant
  /// [CoreSchemeSource] states — `highContrastLight(c)` equal to
  /// `raiseContrast(light(c), c, .light)`, and the dark pair likewise.
  const CoreSemanticMappingSet({
    required this.light,
    required this.dark,
    required this.highContrastLight,
    required this.highContrastDark,
    required this.raiseContrast,
  });

  /// The standard chromatic interpretation — [CoreSemanticMapping]'s four
  /// builders, unchanged. The default for every brand that does not state
  /// otherwise.
  static const standard = CoreSemanticMappingSet(
    light: CoreSemanticMapping.light,
    dark: CoreSemanticMapping.dark,
    highContrastLight: CoreSemanticMapping.highContrastLight,
    highContrastDark: CoreSemanticMapping.highContrastDark,
    raiseContrast: CoreSemanticMapping.raiseContrast,
  );

  /// The monochrome interpretation — primary/secondary slot families on the
  /// neutral scale (see `CoreSemanticMapping.monochromeLight`).
  @Deprecated(
    'CoUI reads CouiColorPresets.source (its fixed CouiPalette through '
    'CouiSemanticMapping) now; the monochrome reading of a generated '
    'palette is retired (since 0.154).',
  )
  static const monochrome = CoreSemanticMappingSet(
    light: CoreSemanticMapping.monochromeLight,
    dark: CoreSemanticMapping.monochromeDark,
    highContrastLight: CoreSemanticMapping.monochromeHighContrastLight,
    highContrastDark: CoreSemanticMapping.monochromeHighContrastDark,
    raiseContrast: CoreSemanticMapping.monochromeRaiseContrast,
  );

  /// Light mode builder.
  final CoreSchemeBuilder light;

  /// Dark mode builder.
  final CoreSchemeBuilder dark;

  /// High-contrast light mode builder.
  final CoreSchemeBuilder highContrastLight;

  /// High-contrast dark mode builder.
  final CoreSchemeBuilder highContrastDark;

  /// Raises contrast on an already-built (possibly style-bent) scheme —
  /// the theme seat's door into high contrast. See the constructor doc for
  /// the invariant tying this to the two `highContrast*` builders.
  final CoreContrastRaiser raiseContrast;

  /// [palette] read through this set — the source a seat takes.
  CorePrimitiveSchemeSource bind(PrimitiveColors palette) =>
      CorePrimitiveSchemeSource(palette, this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreSemanticMappingSet &&
          runtimeType == other.runtimeType &&
          light == other.light &&
          dark == other.dark &&
          highContrastLight == other.highContrastLight &&
          highContrastDark == other.highContrastDark &&
          raiseContrast == other.raiseContrast);

  @override
  int get hashCode => Object.hash(
    light,
    dark,
    highContrastLight,
    highContrastDark,
    raiseContrast,
  );
}
