/// Chip-specific size variants.
///
/// Three tiers, not the shared six. The chip's height ladder is 28 / 32 / 40:
/// the 24 tier below it is where `Badge` lives, and the 48 / 56 tiers above
/// it are where `Button` lives — a chip at those heights is a button wearing
/// a chip's label. Stating the ladder as its own enum makes the three the only
/// values a caller can name, so the resolver's `defaultsBySize[size]!` can
/// never meet a tier the design does not regulate.
library;

/// Size options for a `Chip`.
enum CoreChipSize {
  /// Small chip (28dp).
  sm,

  /// Medium chip (32dp) — the default.
  md,

  /// Large chip (40dp).
  lg;

  /// Widget default size. Flutter / Web `Chip` constructors reference this
  /// so neither platform diverges silently.
  static const CoreChipSize defaultSize = md;
}
