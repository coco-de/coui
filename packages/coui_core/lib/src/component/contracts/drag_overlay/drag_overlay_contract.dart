/// Platform-independent contract for the drag overlay component.
///
/// `DragOverlay` paints a copy of whatever is being dragged in a layer
/// above the page, so the drag is visible outside the box it started in —
/// an ancestor that clips or transforms its children would otherwise cut
/// the dragged item off at the boundary.
library;

/// Contract for the floating layer that follows a live drag.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
/// - [OverlayBuilder] - builder invoked with the live drag session
///   (platform-typed, since only its return type differs).
///
/// The overlay renders nothing while no drag is live, so it costs nothing
/// to leave mounted.
abstract interface class CoreDragOverlayContract<W, OverlayBuilder> {
  /// Builds the floating copy from the live session.
  OverlayBuilder get builder;
}
