/// Visual variants for `EmptyState`.
library;

/// Visual density variant of `EmptyState`.
///
/// - [normal] — full-size empty state. Used in primary content areas where
///   the empty state is the main subject (default).
/// - [compact] — denser layout suited for embedded contexts such as
///   sidebars, panels, or list previews.
/// - [large] — roomier layout for wide first-screen placements.
enum CoreEmptyStateVariant {
  /// Standard full-size empty state.
  normal,

  /// Denser layout for embedded contexts.
  compact,

  /// Roomier layout with a larger icon box, for wide placements.
  large;

  /// Widget default variant. Flutter / Web `EmptyState` constructors
  /// reference this value to avoid silent divergence.
  static const CoreEmptyStateVariant defaultVariant = normal;
}
