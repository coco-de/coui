/// Platform-independent layout for `BottomActionBar`.
library;

/// How a `BottomActionBar` arranges its actions.
///
/// The choice changes the structure as well as the measurements — one column
/// against one row, which action comes first, and which cell takes the
/// remaining width — so it is a widget
/// parameter rather than a Style field. Padding, spacing and fill come from
/// the style in both layouts.
enum CoreBottomActionBarLayout {
  /// One column, each action the full width of the bar: the primary action
  /// on top, the secondary action under it. The note, when there is one,
  /// sits above both.
  vertical,

  /// One row of equal-width cells: the secondary action first, the primary
  /// action last. A lone primary action fills the row. The note sits above
  /// the row.
  horizontal,

  /// One row: the secondary action at its own width (a short label), the
  /// primary action filling the rest. A lone primary action fills the row.
  /// The note sits above the row.
  weighted,

  /// One row: a square icon-only secondary action at its own width, the
  /// primary action filling the rest. The arrangement is [weighted]'s — the
  /// caller's secondary `Button` is the square one — and the name says which
  /// shape the layout is for.
  icon,

  /// One row: a short summary at the start (the `summaryLabel` over the
  /// `summaryValue`, at their own width), the primary action filling the
  /// rest. The secondary action is not drawn. The note sits above the row.
  summary,

  /// One row: the summary at the start, the primary action at its own width
  /// at the end, both centred across. The secondary action is not drawn.
  /// The note sits above the row.
  ///
  /// [summary] with a lighter bar: a primary action that fills the rest of
  /// the row makes most of the bar a button. The primary action's width is
  /// its label's, so the caller picks the Button size the row needs.
  summaryCompact;

  /// Widget default layout — the Flutter / Web `BottomActionBar`
  /// constructors reference this so the default cannot silently diverge.
  static const CoreBottomActionBarLayout defaultLayout = vertical;
}
