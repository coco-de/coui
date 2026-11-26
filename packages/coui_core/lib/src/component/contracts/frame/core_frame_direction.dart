/// Layout direction for `CoreFrameContract`.
///
/// Maps to:
/// - Flutter: `Row` / `Column` / `Wrap` widgets (with `verticalDirection`
///   reversed for `*Reverse`).
/// - Web: CSS `flex-direction: row | column | row-reverse | column-reverse`
///   plus `flex-wrap: wrap` for [wrap].
/// - Figma: Auto Layout direction (Horizontal / Vertical / Wrap).
///
/// `null` on the contract means *no flex layout* — the frame falls back
/// to single-child / non-flex behaviour (the child stacks naturally,
/// like a CSS `display:block` div).
enum CoreFrameDirection {
  /// Children laid out left-to-right.
  row,

  /// Children laid out top-to-bottom (default for Web `<div>`).
  column,

  /// Like [row] but reversed.
  rowReverse,

  /// Like [column] but reversed.
  columnReverse,

  /// Children flow horizontally, wrapping to the next line when they
  /// overflow the main axis.
  wrap,
}
