import 'package:meta/meta.dart';

/// Platform-neutral 2D offset used by the title-bar drag callbacks.
///
/// Mirrors Flutter's `Offset` / DOM `clientX, clientY` pair but avoids a
/// `dart:ui` dependency so it can live in `coui_core`.
@immutable
class CoreOffset {
  /// Creates a [CoreOffset].
  const CoreOffset(this.dx, this.dy);

  /// Zero offset — origin.
  static const zero = CoreOffset(0, 0);

  /// Horizontal component in logical pixels.
  final double dx;

  /// Vertical component in logical pixels.
  final double dy;

  @override
  bool operator ==(Object other) =>
      other is CoreOffset && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(dx, dy);

  @override
  String toString() => 'CoreOffset($dx, $dy)';
}

/// Callback invoked when a drag gesture starts on the title bar.
///
/// Receives the **local** pointer position relative to the title bar top
/// left corner. Window uses this to compute `_dragAlignment` for the
/// minify-during-snap animation.
typedef CoreTitleBarDragStartCallback =
    void Function(CoreOffset localPosition, CoreOffset globalPosition);

/// Callback invoked on every drag move. [delta] is the pointer movement
/// since the previous move event (Flutter `details.delta` / Web
/// `clientX/Y` diff).
typedef CoreTitleBarDragUpdateCallback =
    void Function(CoreOffset delta, CoreOffset globalPosition);

/// Callback invoked when the drag gesture ends or is cancelled.
typedef CoreTitleBarDragEndCallback = void Function();
