/// Width / height constraint policies for popover panels.
///
/// Mirrors the legacy Flutter `PopoverConstraint` enum — promoted to
/// `coui_core` so Flutter and Web `Popover` implementations can both
/// express the same anchor-relative sizing rules.
library;

/// How a popover panel's width or height is sized relative to the
/// trigger anchor.
enum CorePopoverConstraint {
  /// Match the anchor's size exactly (locked to anchor width/height).
  anchorFixedSize,

  /// Cap at the anchor's size (panel may be smaller, never larger).
  anchorMaxSize,

  /// Floor at the anchor's size (panel may be larger, never smaller).
  anchorMinSize,

  /// Size to the panel content's intrinsic measurement, ignoring the
  /// anchor.
  flexible,

  /// Use the panel's intrinsic width/height computed by the layout
  /// engine without any anchor relationship.
  intrinsic,
}
