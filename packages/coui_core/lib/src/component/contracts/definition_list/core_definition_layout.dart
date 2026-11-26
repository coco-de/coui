/// Platform-independent layout for `DefinitionList` term / description
/// pairs.
library;

/// How a `DefinitionList` arranges each term against its description.
///
/// The choice is purely visual — every layout renders the same
/// `<dl>` / `<dt>` / `<dd>` structure, so the reading order a screen
/// reader announces does not change with it.
enum CoreDefinitionLayout {
  /// Term and description run together on one line, pairs wrapping onto
  /// further lines as the width runs out. For compact runs of short
  /// values ("대표 한동우 · 사업자등록번호 000-00-00000").
  inline,

  /// Term above, description below. The only layout that cannot overflow
  /// at any width, which is why it is the default — a long term wraps
  /// inside the full measure instead of widening a column. The term is a
  /// caption, one step smaller than the description.
  stacked,

  /// Two columns — `grid-template-columns: max-content 1fr`. Every
  /// description starts at the same edge, so numbers stacked in the
  /// second column line up vertically (pair this with
  /// `DefinitionList.numeric` to make the digits line up too).
  ///
  /// The term column is `max-content` unless
  /// `CoreDefinitionListStyle.termWidth` fixes it: it never shrinks, so a
  /// long term squeezes the description column rather than wrapping. A
  /// fixed `termWidth` holds the column at that width, which lines the
  /// descriptions of separate lists up on one edge. Prefer [stacked] when
  /// the terms are long or the container is narrow.
  columns,
}
