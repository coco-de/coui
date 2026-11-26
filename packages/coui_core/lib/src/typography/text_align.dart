/// Horizontal alignment of text within its container.
///
/// Maps to:
/// - Flutter: `TextAlign`.
/// - Web: CSS `text-align`.
enum CoreTextAlign {
  /// Align the text to the leading edge (start) of the container.
  start,

  /// Align the text to the trailing edge (end) of the container.
  end,

  /// Center the text horizontally.
  center,

  /// Stretch the text so each line fills the container width
  /// (CSS `justify`).
  justify,

  /// Align the text to the left edge.
  left,

  /// Align the text to the right edge.
  right,
}
