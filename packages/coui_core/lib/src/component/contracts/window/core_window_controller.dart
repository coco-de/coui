import 'package:coui_core/src/component/contracts/window/core_window_constraints.dart';
import 'package:coui_core/src/component/contracts/window/core_window_rect.dart';
import 'package:coui_core/src/component/contracts/window/core_window_state.dart';

/// Listener callback type used by [CoreWindowController].
typedef CoreWindowStateListener = void Function(CoreWindowState state);

/// Cross-platform reactive controller for a single window's state.
///
/// Both Flutter `Window` and Web `Window` read/write through this
/// controller so programmatic state control works identically on either
/// platform. Internally it is a minimal, `dart:ui`-free notifier — Flutter
/// adopts it via a wrapper that forwards listeners.
class CoreWindowController {
  /// Creates a [CoreWindowController] with an initial state.
  CoreWindowController({
    required CoreWindowRect bounds,
    bool alwaysOnTop = false,
    bool closable = true,
    CoreWindowConstraints constraints = kCoreDefaultWindowConstraints,
    bool draggable = true,
    bool enableSnapping = true,
    bool maximizable = true,
    CoreWindowRect? maximized,
    bool minimizable = true,
    bool minimized = false,
    bool resizable = true,
  }) : value = CoreWindowState(
         bounds: bounds,
         alwaysOnTop: alwaysOnTop,
         closable: closable,
         constraints: constraints,
         draggable: draggable,
         enableSnapping: enableSnapping,
         maximizable: maximizable,
         maximized: maximized,
         minimizable: minimizable,
         minimized: minimized,
         resizable: resizable,
       );

  /// Current state, named to mirror Flutter's `ValueNotifier.value`.
  CoreWindowState value;

  List<CoreWindowStateListener> _listeners = const <CoreWindowStateListener>[];

  /// Updates the state. No-op when the new value is equal to the current
  /// one; otherwise notifies all listeners.
  void update(CoreWindowState next) {
    if (next == value) return;
    value = next;
    for (final listener in _listeners) {
      listener(next);
    }
  }

  /// Registers a listener invoked on every state change.
  void addListener(CoreWindowStateListener listener) {
    _listeners = [..._listeners, listener];
  }

  /// Removes a previously added listener.
  void removeListener(CoreWindowStateListener listener) {
    _listeners = _listeners.where((l) => l != listener).toList();
  }

  /// Releases all listeners.
  void dispose() {
    _listeners = const <CoreWindowStateListener>[];
  }

  // Convenience getters/setters mirroring the legacy Flutter API. Each
  // reads/writes through [value] and re-emits via [update]. Named after
  // underlying [CoreWindowState] fields for API parity with legacy
  // `WindowController`.

  /// Current window bounds.
  CoreWindowRect get bounds => value.bounds;
  set bounds(CoreWindowRect next) {
    if (next == value.bounds) return;
    update(value.copyWith(bounds: next));
  }

  /// Current maximized rectangle (relative), or `null` when floating.
  CoreWindowRect? get maximized => value.maximized;
  set maximized(CoreWindowRect? next) {
    if (next == value.maximized) return;
    update(value.copyWith(maximized: next));
  }

  /// Whether the window is minimized.
  bool get minimized => value.minimized;
  set minimized(bool next) {
    if (next == value.minimized) return;
    update(value.copyWith(minimized: next));
  }

  /// Whether the window sits on the always-on-top layer.
  bool get alwaysOnTop => value.alwaysOnTop;
  set alwaysOnTop(bool next) {
    if (next == value.alwaysOnTop) return;
    update(value.copyWith(alwaysOnTop: next));
  }

  /// Whether the window is closable.
  bool get closable => value.closable;
  set closable(bool next) {
    if (next == value.closable) return;
    update(value.copyWith(closable: next));
  }

  /// Whether the window is resizable.
  bool get resizable => value.resizable;
  set resizable(bool next) {
    if (next == value.resizable) return;
    update(value.copyWith(resizable: next));
  }

  /// Whether the window is draggable.
  bool get draggable => value.draggable;
  set draggable(bool next) {
    if (next == value.draggable) return;
    update(value.copyWith(draggable: next));
  }

  /// Whether the window exposes a maximize button.
  bool get maximizable => value.maximizable;
  set maximizable(bool next) {
    if (next == value.maximizable) return;
    update(value.copyWith(maximizable: next));
  }

  /// Whether the window exposes a minimize button.
  bool get minimizable => value.minimizable;
  set minimizable(bool next) {
    if (next == value.minimizable) return;
    update(value.copyWith(minimizable: next));
  }

  /// Whether drag-to-edge snapping is enabled.
  bool get enableSnapping => value.enableSnapping;
  set enableSnapping(bool next) {
    if (next == value.enableSnapping) return;
    update(value.copyWith(enableSnapping: next));
  }

  /// Size constraints enforced during resize.
  CoreWindowConstraints get constraints => value.constraints;
  set constraints(CoreWindowConstraints next) {
    if (next == value.constraints) return;
    update(value.copyWith(constraints: next));
  }
}
