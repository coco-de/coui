/// Collision handling enum for popover viewport positioning.
library;

/// Collision handling policies for popover positioning.
///
/// These flags drive the viewport-aware placement algorithm shared by the
/// Flutter `OverlayManager` and the Web `FloatingController`. They describe
/// what should happen when the preferred placement would cause
/// the popover to overflow the viewport.
enum CorePopoverCollision {
  /// Swap to the opposite axis placement (top ↔ bottom or left ↔ right)
  /// when the preferred side lacks room.
  flip,

  /// Translate along the placement axis to keep the popover on-screen
  /// without changing its side.
  shift,

  /// Allow the popover to render partially clipped by the viewport.
  clip,

  /// Do not apply any adjustment; render at the preferred origin regardless
  /// of overflow.
  none,
}
