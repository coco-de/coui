/// Text decoration line style.
///
/// Maps to:
/// - Flutter: `TextDecoration` (`none / underline / overline /
///   lineThrough`).
/// - Web: CSS `text-decoration-line`.
enum CoreTextDecoration {
  /// No decoration.
  none,

  /// Single line drawn beneath the text.
  underline,

  /// Single line drawn above the text.
  overline,

  /// Single line drawn through the middle of the text.
  lineThrough,
}
