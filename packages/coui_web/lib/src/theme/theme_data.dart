/// Main theme data for web applications.
library;

import 'package:coui_core/coui_core.dart';

/// Theme data configuration.
class ThemeData {
  /// Creates a theme data.
  const ThemeData({
    this.colorScheme = const CoreColorScheme.tokenized(),
    this.coreComponentTheme,
    this.designSystem = .coui,
    this.typography = CoreTypography.coui,
    this.textScaling = 1.0,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  /// Creates a [ThemeData] from a [CoreThemeData] (coui_core) — the
  /// single entry point that derives the Web theme from the same core
  /// definitions Flutter (`ThemeData.fromCore`) and the CSS-variable
  /// generator consume. Pass an explicit [typography] to override the
  /// derived `core.typography` scale.
  ///
  /// ```dart
  /// final theme = ThemeData.fromCore(CoreThemePresets.light);
  /// ```
  factory ThemeData.fromCore(
    CoreThemeData core, {
    CoreComponentTheme? coreComponentTheme,
    CoreTypography? typography,
    double? surfaceBlur,
    double? surfaceOpacity,
  }) {
    return ThemeData(
      colorScheme: core.colorScheme,
      coreComponentTheme: coreComponentTheme,
      designSystem: core.designSystem,
      typography: typography ?? core.typography,
      textScaling: core.textScaling,
      surfaceBlur: surfaceBlur,
      surfaceOpacity: surfaceOpacity,
    );
  }

  /// Color scheme (M3 semantic [CoreColor] tokens).
  ///
  /// Defaults to `CoreColorScheme.tokenized()` — every field is a
  /// `CoreColor.token(...)` reference. Web renderers emit
  /// `var(--color-X)` via `.toValue()` for inline CSS, while Tailwind
  /// class composition uses Dart string interpolation directly
  /// (`'bg-${cs.primary}'` → `bg-primary` via [CoreColor.toString]).
  final CoreColorScheme colorScheme;

  /// Cross-platform component theme overrides for * components.
  final CoreComponentTheme? coreComponentTheme;

  /// Active design system.
  ///
  /// `CssVariableGenerator` resolves the colour scheme through this
  /// system's [DesignSystemAdapter] (`designSystem.adapter`) before
  /// emitting `--coui-*` variables, so M3E / Liquid Glass derive their
  /// scheme tokens while the CoUI baseline passes through unchanged.
  final DesignSystem designSystem;

  /// Canonical platform-neutral typography scale (coui_core).
  ///
  /// The single source of truth Flutter (`ThemeData.typography`) and the
  /// CSS-variable generator consume. Defaults to [CoreTypography.coui];
  /// `fromCore` derives it from `core.typography`. Mirrors
  /// `colorScheme: CoreColorScheme` — clean field name + Core type, no
  /// legacy Tailwind-class-key slot (Web class-keys read the canonical
  /// `CoreTextStyles.<role>.name` catalog directly).
  final CoreTypography typography;

  /// Text scaling factor.
  final double textScaling;

  /// Global surface backdrop blur (logical px). Surface components
  /// (outlined-container / dialog / tooltip …) fall back to this when
  /// their own `CoreXxxStyle.surfaceBlur` is unset. Mirrors Flutter
  /// `ThemeData.surfaceBlur`.
  final double? surfaceBlur;

  /// Global surface opacity (0–1). Surface components fall back to this
  /// when their own `CoreXxxStyle.surfaceOpacity` is unset. Mirrors
  /// Flutter `ThemeData.surfaceOpacity`.
  final double? surfaceOpacity;

  /// Default theme with CoUI design system.
  static final defaults = ThemeData();

  /// Default theme with CoUI style.
  static final coui = ThemeData();

  /// Default light theme — derived from [CoreThemePresets.light], the
  /// shared light-theme source of truth (same preset Flutter consumes).
  static final light = ThemeData.fromCore(CoreThemePresets.light);

  /// Default dark theme — derived from [CoreThemePresets.dark].
  static final dark = ThemeData.fromCore(CoreThemePresets.dark);

  /// Creates a copy with optional changes.
  ThemeData copyWith({
    CoreColorScheme? colorScheme,
    CoreComponentTheme? coreComponentTheme,
    DesignSystem? designSystem,
    CoreTypography? typography,
    double? textScaling,
    double? surfaceBlur,
    double? surfaceOpacity,
  }) {
    return ThemeData(
      colorScheme: colorScheme ?? this.colorScheme,
      coreComponentTheme: coreComponentTheme ?? this.coreComponentTheme,
      designSystem: designSystem ?? this.designSystem,
      typography: typography ?? this.typography,
      textScaling: textScaling ?? this.textScaling,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
    );
  }
}
