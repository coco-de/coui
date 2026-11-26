/// Platform-independent pointer and drag event types.
///
/// Used by component contracts for gesture callbacks.
/// Flutter maps to `TapDownDetails`/`LongPressStartDetails`/etc.,
/// Web maps to DOM `MouseEvent`/`PointerEvent`.
library;

/// Pointer event details for tap/press callbacks.
class CorePointerEvent {
  /// Creates pointer event details.
  const CorePointerEvent({
    required this.localX,
    required this.localY,
    required this.globalX,
    required this.globalY,
  });

  /// X position relative to the component.
  final double localX;

  /// Y position relative to the component.
  final double localY;

  /// X position relative to the screen.
  final double globalX;

  /// Y position relative to the screen.
  final double globalY;
}

/// Drag/move event details for long press move callbacks.
class CoreDragEvent extends CorePointerEvent {
  /// Creates drag event details.
  const CoreDragEvent({
    required super.localX,
    required super.localY,
    required super.globalX,
    required super.globalY,
    required this.offsetX,
    required this.offsetY,
  });

  /// Horizontal offset from the start position.
  final double offsetX;

  /// Vertical offset from the start position.
  final double offsetY;
}

/// Callback for pointer events (tap down/up, long press start/end).
typedef CorePointerCallback = void Function(CorePointerEvent event);

/// Callback for drag/move events (long press move update).
typedef CoreDragCallback = void Function(CoreDragEvent event);
