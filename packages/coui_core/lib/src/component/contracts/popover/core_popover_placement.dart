/// Placement enum for popover positioning relative to trigger.
library;

/// The preferred placement of a popover relative to its trigger.
///
/// The 4 legacy values (`top`/`bottom`/`left`/`right`) are equivalent to the
/// corresponding `*Center` placements and are kept for backward compatibility.
/// Form popovers (Select, DatePicker, Autocomplete, etc.) should prefer the
/// 8 corner-aware values which enable alignment-aware flip/shift collision
/// handling via [CorePopoverPlacementExt].
enum CorePopoverPlacement {
  /// Above the trigger, horizontally centered.
  ///
  /// Equivalent to the logical "top-center" position.
  top,

  /// Above the trigger, left-aligned with the trigger start edge.
  topStart,

  /// Above the trigger, right-aligned with the trigger end edge.
  topEnd,

  /// Below the trigger, horizontally centered.
  ///
  /// Equivalent to the logical "bottom-center" position.
  bottom,

  /// Below the trigger, left-aligned with the trigger start edge.
  bottomStart,

  /// Below the trigger, right-aligned with the trigger end edge.
  bottomEnd,

  /// To the left of the trigger, vertically centered.
  ///
  /// Equivalent to the logical "left-center" position.
  left,

  /// To the left of the trigger, aligned with the trigger top edge.
  leftStart,

  /// To the left of the trigger, aligned with the trigger bottom edge.
  leftEnd,

  /// To the right of the trigger, vertically centered.
  ///
  /// Equivalent to the logical "right-center" position.
  right,

  /// To the right of the trigger, aligned with the trigger top edge.
  rightStart,

  /// To the right of the trigger, aligned with the trigger bottom edge.
  rightEnd,
}

/// Extension providing axis-flip helpers for [CorePopoverPlacement].
extension CorePopoverPlacementExt on CorePopoverPlacement {
  /// Returns the placement with the primary axis mirrored vertically
  /// (top ↔ bottom). Left/right placements are returned unchanged.
  CorePopoverPlacement flipY() {
    return switch (this) {
      .top => .bottom,
      .topStart => .bottomStart,
      .topEnd => .bottomEnd,
      .bottom => .top,
      .bottomStart => .topStart,
      .bottomEnd => .topEnd,
      .left ||
      .leftStart ||
      .leftEnd ||
      .right ||
      .rightStart ||
      .rightEnd => this,
    };
  }

  /// Returns the placement with the primary axis mirrored horizontally
  /// (left ↔ right). Top/bottom placements are returned unchanged.
  CorePopoverPlacement flipX() {
    return switch (this) {
      .left => .right,
      .leftStart => .rightStart,
      .leftEnd => .rightEnd,
      .right => .left,
      .rightStart => .leftStart,
      .rightEnd => .leftEnd,
      .top ||
      .topStart ||
      .topEnd ||
      .bottom ||
      .bottomStart ||
      .bottomEnd => this,
    };
  }

  /// Whether the popover opens above the trigger.
  bool get isTop => switch (this) {
    .top || .topStart || .topEnd => true,
    .bottom ||
    .bottomStart ||
    .bottomEnd ||
    .left ||
    .leftStart ||
    .leftEnd ||
    .right ||
    .rightStart ||
    .rightEnd => false,
  };

  /// Whether the popover opens below the trigger.
  bool get isBottom => switch (this) {
    .bottom || .bottomStart || .bottomEnd => true,
    .top ||
    .topStart ||
    .topEnd ||
    .left ||
    .leftStart ||
    .leftEnd ||
    .right ||
    .rightStart ||
    .rightEnd => false,
  };

  /// Whether the popover opens to the left of the trigger.
  bool get isLeft => switch (this) {
    .left || .leftStart || .leftEnd => true,
    .top ||
    .topStart ||
    .topEnd ||
    .bottom ||
    .bottomStart ||
    .bottomEnd ||
    .right ||
    .rightStart ||
    .rightEnd => false,
  };

  /// Whether the popover opens to the right of the trigger.
  bool get isRight => switch (this) {
    .right || .rightStart || .rightEnd => true,
    .top ||
    .topStart ||
    .topEnd ||
    .bottom ||
    .bottomStart ||
    .bottomEnd ||
    .left ||
    .leftStart ||
    .leftEnd => false,
  };
}
