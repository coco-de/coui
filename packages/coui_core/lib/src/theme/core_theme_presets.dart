import 'package:coui_core/src/color/color_presets.dart';
import 'package:coui_core/src/color/resolved_color_scheme.dart';
import 'package:coui_core/src/theme/core_theme_data.dart';

/// Single source of truth for CoUI default theme presets.
///
/// All color values are read from [CouiColorPresets.source] — CoUI's fixed
/// palette through its own mapping — ensuring consistency across platforms.
abstract final class CoreThemePresets {
  const CoreThemePresets._();

  // ── Color Schemes (Primitive-based) ───────────────────────────

  /// Default light color scheme.
  ///
  /// The mapping already fills every M3 slot, so this is promoted to a
  /// [ResolvedColorScheme] (non-null M3 getters) — consumers read
  /// `lightColorScheme.onSurface.toValue()` with no `!`.
  static final ResolvedColorScheme lightColorScheme = CouiColorPresets.source
      .light()
      .resolved(.light);

  /// Default dark color scheme.
  ///
  /// See [lightColorScheme] — promoted to [ResolvedColorScheme] the same way.
  static final ResolvedColorScheme darkColorScheme = CouiColorPresets.source
      .dark()
      .resolved(.dark);

  /// [lightColorScheme] with contrast raised for users who have asked for
  /// it — the same slots resolved to stronger values.
  static final ResolvedColorScheme highContrastLightColorScheme =
      CouiColorPresets.source.highContrastLight().resolved(.light);

  /// See [highContrastLightColorScheme] — dark counterpart.
  static final ResolvedColorScheme highContrastDarkColorScheme =
      CouiColorPresets.source.highContrastDark().resolved(.dark);

  // ── Theme Data ────────────────────────────────────────────────

  /// Default light theme data.
  static final light = CoreThemeData(
    colorScheme: lightColorScheme,
    brightness: .light,
    designSystem: .coui,
  );

  /// Default dark theme data.
  static final dark = CoreThemeData(
    colorScheme: darkColorScheme,
    brightness: .dark,
    designSystem: .coui,
  );

  /// High-contrast light theme data — see [highContrastLightColorScheme].
  static final highContrastLight = CoreThemeData(
    colorScheme: highContrastLightColorScheme,
    brightness: .light,
    designSystem: .coui,
  );

  /// High-contrast dark theme data — see [highContrastDarkColorScheme].
  static final highContrastDark = CoreThemeData(
    colorScheme: highContrastDarkColorScheme,
    brightness: .dark,
    designSystem: .coui,
  );

  // ── Preview (Docs Site) ───────────────────────────────────────

  /// Scale factor to align Flutter rendering with Web CSS rendering.
  static const previewScaleFactor = 1.15;

  /// Preview-optimized light theme for docs site Flutter embeds.
  static final previewLight = CoreThemeData(
    colorScheme: lightColorScheme,
    brightness: .light,
    designSystem: .coui,
    textScaling: previewScaleFactor,
    sizeScaling: previewScaleFactor,
    radiusScaling: previewScaleFactor,
  );

  /// Preview-optimized dark theme for docs site Flutter embeds.
  static final previewDark = CoreThemeData(
    colorScheme: darkColorScheme,
    brightness: .dark,
    designSystem: .coui,
    textScaling: previewScaleFactor,
    sizeScaling: previewScaleFactor,
    radiusScaling: previewScaleFactor,
  );
}
