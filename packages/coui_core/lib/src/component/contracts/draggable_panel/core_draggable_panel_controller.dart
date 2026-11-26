import 'package:coui_core/src/component/contracts/draggable_panel/core_draggable_panel_state.dart';

/// Listener callback type used by [CoreDraggablePanelController].
typedef CoreDraggablePanelStateListener =
    void Function(CoreDraggablePanelState state);

/// Cross-platform reactive controller for a single `DraggablePanel`.
///
/// Both Flutter `DraggablePanel` and Web `DraggablePanel` read/write
/// through this controller so programmatic position/open control works
/// identically on either platform. Internally it is a minimal, `dart:ui`-free
/// notifier mirroring `CoreWindowController` — Flutter adopts it via a wrapper
/// that forwards listeners.
class CoreDraggablePanelController {
  /// Creates a controller with an initial handle position and open state.
  CoreDraggablePanelController({
    double initialX = 0,
    double initialY = 0,
    bool initiallyOpen = false,
  }) : value = CoreDraggablePanelState(
         x: initialX,
         y: initialY,
         open: initiallyOpen,
       );

  /// Current state, named to mirror Flutter's `ValueNotifier.value`.
  CoreDraggablePanelState value;

  List<CoreDraggablePanelStateListener> _listeners =
      const <CoreDraggablePanelStateListener>[];

  /// Updates the state. No-op when the new value equals the current one;
  /// otherwise notifies all listeners.
  void update(CoreDraggablePanelState next) {
    if (next == value) return;
    value = next;
    for (final listener in _listeners) {
      listener(next);
    }
  }

  /// Registers a listener invoked on every state change.
  void addListener(CoreDraggablePanelStateListener listener) {
    _listeners = [..._listeners, listener];
  }

  /// Removes a previously added listener.
  void removeListener(CoreDraggablePanelStateListener listener) {
    _listeners = _listeners.where((l) => l != listener).toList();
  }

  /// Releases all listeners.
  void dispose() {
    _listeners = const <CoreDraggablePanelStateListener>[];
  }

  /// Current handle left offset in logical pixels.
  double get x => value.x;
  set x(double next) {
    if (next == value.x) return;
    update(value.copyWith(x: next));
  }

  /// Current handle top offset in logical pixels.
  double get y => value.y;
  set y(double next) {
    if (next == value.y) return;
    update(value.copyWith(y: next));
  }

  /// Whether the expandable panel is open.
  bool get open => value.open;
  set open(bool next) {
    if (next == value.open) return;
    update(value.copyWith(open: next));
  }

  /// Moves the handle to ([nextX], [nextY]) in a single notification.
  void setPosition(double nextX, double nextY) {
    if (nextX == value.x && nextY == value.y) return;
    update(value.copyWith(x: nextX, y: nextY));
  }

  /// Toggles the open state.
  void toggle() {
    open = !open;
  }
}
