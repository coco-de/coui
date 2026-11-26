/// Unified component variant enum across design systems.
///
/// Maps to CoUI Web class variants, M3E filled/tonal/outlined/text variants,
/// and Liquid Glass material variants.
enum CoreComponentVariant {
  // === CoUI Primary Variants ===

  /// Default/neutral variant.
  defaultVariant,

  /// Primary brand action.
  primary,

  /// Secondary brand action.
  secondary,

  /// Accent highlight.
  accent,

  /// Informational.
  info,

  /// Success/positive.
  success,

  /// Warning/cautionary.
  warning,

  /// Error/destructive.
  error,

  // === M3E Style Variants ===

  /// Filled container (M3E).
  filled,

  /// Tonal container with reduced emphasis (M3E).
  tonal,

  /// Outlined border (M3E / CoUI outline).
  outlined,

  /// Text-only / ghost (M3E text / CoUI ghost).
  ghost,

  /// Elevated with shadow (M3E).
  elevated,

  // === Additional Variants ===

  /// Link style.
  link,

  /// Soft / subtle (low emphasis).
  soft,

  /// Dash outline.
  dash,

  /// Neutral variant.
  neutral,
}
