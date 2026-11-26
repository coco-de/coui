/// Progress-specific size variants.
///
/// Confirmed by `.claude/docs/figma-token-sync/epic-k-dimension-table.md`
/// §축 8-1 (`design/design-tokens/component/progress-bar/
/// CoUI_Progress_Bar_Height_Token_Specification.md`, v1.0). Not
/// `CoreComponentSize` — the spec's label ladder starts at `2xs`, a tier
/// the shared enum doesn't have (DDR-06; Fab/Status/Dock/DescriptionCard/
/// ValidationBadge already use dedicated enums for the same reason).
library;

/// Size options for a `Progress` (linear) track / indicator.
///
/// `2xs` cannot be a Dart identifier (leading digit), so it is spelled
/// [xs2] — the same trailing-digit convention `CoreComponentSize.xl2`
/// uses for the spec's `2xl` (see `component_size.dart`).
enum CoreProgressSize {
  /// `2xs` in the spec (2px track).
  xs2,

  /// `xs` (4px track).
  xs,

  /// `sm` (6px track) — the default.
  sm,

  /// `md` (8px track).
  md,

  /// `lg` (12px track).
  lg,

  /// `xl` (16px track).
  xl;

  /// Widget default size. Flutter / Web `Progress` constructors reference
  /// this so neither platform diverges silently.
  static const CoreProgressSize defaultSize = sm;
}
