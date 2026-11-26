/// How a positioned child anchors vertically inside its `Stacks`
/// parent. Mirrors Figma's per-axis "Constraints" panel.
///
/// Vertical counterpart of `CoreHorizontalAnchor`.
enum CoreVerticalAnchor {
  /// Pin the child to the parent's top edge.
  top,

  /// Pin to the bottom edge.
  bottom,

  /// Pin both edges — child stretches when the parent resizes.
  topBottom,

  /// Centre vertically.
  center,

  /// Scale with the parent — child height is a fraction of the parent.
  scale,
}
