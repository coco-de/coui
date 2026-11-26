import 'package:meta/meta.dart';

/// Immutable runtime state for a single `DraggablePanel`.
///
/// Holds the handle position (logical pixels relative to the panel's
/// containing viewport) and whether the expandable panel is open. Lives in
/// `coui_core` so the Flutter and Web widgets share one state model with no
/// `dart:ui` dependency.
@immutable
class CoreDraggablePanelState {
  /// Creates a [CoreDraggablePanelState].
  const CoreDraggablePanelState({
    required this.x,
    required this.y,
    this.open = false,
  });

  /// Handle left offset in logical pixels.
  final double x;

  /// Handle top offset in logical pixels.
  final double y;

  /// Whether the expandable panel surface is currently open.
  final bool open;

  /// Returns a copy with the given fields replaced.
  CoreDraggablePanelState copyWith({double? x, double? y, bool? open}) => .new(
    x: x ?? this.x,
    y: y ?? this.y,
    open: open ?? this.open,
  );

  @override
  bool operator ==(Object other) =>
      other is CoreDraggablePanelState &&
      other.x == x &&
      other.y == y &&
      other.open == open;

  @override
  int get hashCode => Object.hash(x, y, open);

  @override
  String toString() => 'CoreDraggablePanelState(x: $x, y: $y, open: $open)';
}
