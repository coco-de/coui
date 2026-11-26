import 'package:coui_core/coui_core.dart';

/// The four [CoreColorScheme]s of a [CoreSchemeSource] — the light, dark
/// and two high-contrast schemes a `ThemeData` set is built from.
///
/// This is a thin wrapper — the actual Primitive → Semantic mapping logic
/// lives in coui_core and is shared with coui_web.
///
/// Usage — CoUI's own colours:
/// ```dart
/// const semantic = CouiSemanticColors.from(CouiColorPresets.source);
/// final lightScheme = semantic.light;
/// final darkScheme = semantic.dark;
/// ```
///
/// Or a brand's generated palette:
/// ```dart
/// final semantic = CouiSemanticColors(PrimitiveColors.generate(...));
/// ```
class CouiSemanticColors {
  /// Creates semantic color mappings from a brand's generated
  /// [PrimitiveColors].
  ///
  /// [mapping] is the brand's Primitive → Semantic interpretation — pass
  /// the brand's own set alongside its palette.
  const CouiSemanticColors(
    PrimitiveColors this._colors, {
    CoreSemanticMappingSet mapping = CoreSemanticMappingSet.standard,
  }) : _mapping = mapping,
       _statedSource = null;

  /// Creates semantic color mappings from a colour [source] that is not a
  /// generated palette — CoUI's own `CouiColorPresets.source`, for one.
  const CouiSemanticColors.from(CoreSchemeSource source)
    : _statedSource = source,
      _colors = null,
      _mapping = null;

  // A const constructor cannot build the source from its parameters, so a
  // palette instance keeps the pair and [_source] wraps it on read.
  final PrimitiveColors? _colors;

  final CoreSemanticMappingSet? _mapping;

  final CoreSchemeSource? _statedSource;

  CoreSchemeSource get _source =>
      _statedSource ?? CorePrimitiveSchemeSource(_colors!, _mapping!);

  /// Light mode [CoreColorScheme].
  CoreColorScheme get light => _source.light();

  /// Dark mode [CoreColorScheme].
  CoreColorScheme get dark => _source.dark();

  /// Light mode with contrast raised for users who asked for it.
  CoreColorScheme get highContrastLight => _source.highContrastLight();

  /// Dark mode with contrast raised for users who asked for it.
  CoreColorScheme get highContrastDark => _source.highContrastDark();
}
