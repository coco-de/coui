import 'package:coui_core/src/component/contracts/window/core_window_rect.dart';
import 'package:meta/meta.dart';

/// Describes one snap target (a screen-relative rectangle and whether the
/// dragged window should shrink while hovering the target).
@immutable
class CoreWindowSnapStrategy {
  /// Creates a [CoreWindowSnapStrategy].
  const CoreWindowSnapStrategy({
    required this.relativeBounds,
    this.shouldMinifyWindow = true,
  });

  /// Target rectangle in navigator-relative coordinates (0..1).
  final CoreWindowRect relativeBounds;

  /// Whether the dragged window should render minified while hovering this
  /// target (matches Flutter legacy behaviour).
  final bool shouldMinifyWindow;

  @override
  bool operator ==(Object other) =>
      other is CoreWindowSnapStrategy &&
      other.relativeBounds == relativeBounds &&
      other.shouldMinifyWindow == shouldMinifyWindow;

  @override
  int get hashCode => Object.hash(relativeBounds, shouldMinifyWindow);
}
