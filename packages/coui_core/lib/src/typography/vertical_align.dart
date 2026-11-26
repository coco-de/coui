/// Vertical alignment of content within its container.
///
/// Maps to:
/// - Flutter: `TextAlignVertical` (`top` / `center` / `bottom`).
/// - Web: CSS `align-items` / `align-self` (`flex-start` / `center` /
///   `flex-end`).
enum CoreVerticalAlign {
  /// Align to the top edge of the container.
  top,

  /// Center vertically within the container.
  center,

  /// Align to the bottom edge of the container.
  bottom,
}
