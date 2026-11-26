import 'package:coui_core/src/component/contracts/window/core_window_constraints.dart';
import 'package:coui_core/src/component/contracts/window/core_window_rect.dart';
import 'package:meta/meta.dart';

/// Sentinel used by [CoreWindowState.copyWith] to distinguish
/// "keep existing" from "explicit null" for [CoreWindowState.maximized].
///
/// Not a design token — internal sentinel for nullable-copy semantics.
const _kSentinel = Object();

/// Immutable snapshot of a single window's state.
///
/// Used by the cross-platform `CoreWindowController` so Flutter and Web can
/// share the same mutable view-model (only the widgets/components differ).
@immutable
class CoreWindowState {
  /// Creates a [CoreWindowState].
  const CoreWindowState({
    required this.bounds,
    this.alwaysOnTop = false,
    this.closable = true,
    this.constraints = kCoreDefaultWindowConstraints,
    this.draggable = true,
    this.enableSnapping = true,
    this.maximizable = true,
    this.maximized,
    this.minimizable = true,
    this.minimized = false,
    this.resizable = true,
  });

  /// Current logical-pixel bounds of the window inside the navigator.
  final CoreWindowRect bounds;

  /// Relative (0..1) maximized rectangle, or `null` when the window is
  /// floating.
  final CoreWindowRect? maximized;

  /// Whether the window is currently minimized to the dock.
  final bool minimized;

  /// Whether the window is pinned to the always-on-top layer.
  final bool alwaysOnTop;

  /// Whether the window can be closed by the user.
  final bool closable;

  /// Whether the window can be resized with edge/corner handles.
  final bool resizable;

  /// Whether the title bar supports drag-to-move.
  final bool draggable;

  /// Whether the maximize toggle is available.
  final bool maximizable;

  /// Whether the minimize toggle is available.
  final bool minimizable;

  /// Whether drag-to-edge snapping is enabled.
  final bool enableSnapping;

  /// Size constraints enforced while resizing.
  final CoreWindowConstraints constraints;

  /// Returns a copy with the given fields replaced.
  CoreWindowState copyWith({
    bool? alwaysOnTop,
    CoreWindowRect? bounds,
    bool? closable,
    CoreWindowConstraints? constraints,
    bool? draggable,
    bool? enableSnapping,
    bool? maximizable,
    Object? maximized = _kSentinel,
    bool? minimizable,
    bool? minimized,
    bool? resizable,
  }) {
    return CoreWindowState(
      bounds: bounds ?? this.bounds,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      closable: closable ?? this.closable,
      constraints: constraints ?? this.constraints,
      draggable: draggable ?? this.draggable,
      enableSnapping: enableSnapping ?? this.enableSnapping,
      maximizable: maximizable ?? this.maximizable,
      maximized: identical(maximized, _kSentinel)
          ? this.maximized
          : maximized as CoreWindowRect?,
      minimizable: minimizable ?? this.minimizable,
      minimized: minimized ?? this.minimized,
      resizable: resizable ?? this.resizable,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CoreWindowState &&
      other.bounds == bounds &&
      other.maximized == maximized &&
      other.minimized == minimized &&
      other.alwaysOnTop == alwaysOnTop &&
      other.closable == closable &&
      other.resizable == resizable &&
      other.draggable == draggable &&
      other.maximizable == maximizable &&
      other.minimizable == minimizable &&
      other.enableSnapping == enableSnapping &&
      other.constraints == constraints;

  @override
  int get hashCode => Object.hash(
    bounds,
    maximized,
    minimized,
    alwaysOnTop,
    closable,
    resizable,
    draggable,
    maximizable,
    minimizable,
    enableSnapping,
    constraints,
  );
}
