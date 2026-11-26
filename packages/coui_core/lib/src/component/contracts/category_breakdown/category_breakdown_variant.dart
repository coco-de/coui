/// Visual variant of the unified `CategoryBreakdown` component.
library;

/// How a `CategoryBreakdown` draws each category's share.
enum CoreCategoryBreakdownVariant {
  /// One row per category — label, value and share, over a horizontal
  /// bar. Reads at any width and text size, so it is the default.
  bar,

  /// A ring of arcs beside (or, when narrow, above) a legend.
  donut;

  /// Default variant — horizontal bars.
  static const CoreCategoryBreakdownVariant defaultVariant = bar;
}
