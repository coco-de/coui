/// ThemeController-specific size variants.
///
/// Three tiers, its own enum rather than the shared six. The ladder is a
/// swatch button of 32 / 40 / 48 around a palette preview of 24 / 32 / 40.
/// A caller can retune the numbers through `withStyle`; this enum is what
/// lets them ask for a tier by name.
library;

/// Size options for a `ThemeController` and its swatches.
enum CoreThemeControllerSize {
  /// Small — a 32dp swatch button.
  sm,

  /// Medium — a 40dp swatch button. The default.
  md,

  /// Large — a 48dp swatch button.
  lg;

  /// Widget default size. Flutter / Web `ThemeController` constructors
  /// reference this so neither platform diverges silently.
  static const CoreThemeControllerSize defaultSize = md;
}
