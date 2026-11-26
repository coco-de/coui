/// Cross-platform contract for unified popover controllers.
///
/// Defines the imperative open/close API that `Popover` exposes to
/// outside callers (e.g. a swatch button that toggles the picker
/// popover). Implementations on Flutter (`PopoverController`
/// extending `ChangeNotifier`) and Web (`PopoverController`
/// implementing its own listener bag) must satisfy the same surface.
library;

/// Imperative controller for a `Popover`.
///
/// External callers create one of these, pass it to `Popover` via
/// the `controller` parameter, and drive open / close themselves.
abstract interface class CorePopoverControllerContract {
  /// Whether the popover is currently open.
  bool get isOpen;

  /// Opens the popover. No-op if already open.
  void show();

  /// Closes the popover. No-op if already closed.
  void close();

  /// Convenience — `close()` if open, `show()` otherwise. Used by
  /// trigger toggle buttons (e.g. color picker swatch).
  void toggle();

  /// Subscribe to open / close transitions. Each registered listener
  /// fires on every state change. Mirrors `ChangeNotifier.addListener`
  /// so Flutter / Web can share the same wiring.
  void addListener(void Function() listener);

  /// Remove a previously registered listener.
  void removeListener(void Function() listener);

  /// Release any resources held by the controller. Call from
  /// `State.dispose` (Flutter) / `dispose()` (Web) of the owning
  /// component.
  void dispose();
}
