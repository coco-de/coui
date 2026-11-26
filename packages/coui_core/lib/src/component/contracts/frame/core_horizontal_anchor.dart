/// How a positioned child anchors horizontally inside its `Stacks`
/// parent. Mirrors Figma's per-axis "Constraints" panel.
///
/// Maps to:
/// - Flutter: `Positioned` with the matching edges set, `Align`, or
///   `FractionallySizedBox` depending on the anchor.
/// - Web: CSS `position: absolute` with the matching `left/right/top/
///   bottom/transform` declarations.
enum CoreHorizontalAnchor {
  /// Pin the child to the parent's left edge — uses `left` value, the
  /// child keeps its own `width`.
  left,

  /// Pin to the right edge — uses `right` value.
  right,

  /// Pin both edges — child stretches when the parent resizes (uses
  /// `left` and `right`; `width` is derived).
  leftRight,

  /// Centre horizontally — child keeps its own `width` and stays in
  /// the middle as the parent resizes.
  center,

  /// Scale with the parent — child width is a fraction of the parent
  /// (`widthFraction`).
  scale,
}
