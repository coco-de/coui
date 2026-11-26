/// Outline shape for focus ring rendering.
///
/// Determines whether the focus ring is rendered as a rectangle
/// (respecting borderRadius) or as a perfect circle.
enum CoreFocusOutlineShape {
  /// Rectangle shape. Uses borderRadius to round corners.
  rectangle,

  /// Circle shape. Ignores borderRadius and renders a perfect circle.
  circle,
}
