import 'package:coui_core/coui_core.dart';

/// Web binding for [CorePopoverControllerContract].
///
/// Wraps a small listener bag so consumers can `addListener` to be
/// notified of open / close transitions and `dispose()` from the
/// owning component's `dispose`. Open / close themselves are wired
/// by the owning `Popover` component — the controller only reflects
/// state and requests transitions.
///
/// Mirrors the Flutter `PopoverController` 1:1 so cross-platform
/// callers can swap implementations without touching the call site.
///
/// Example:
/// ```dart
/// final controller = PopoverController();
/// // ...
/// Popover(
///   controller: controller,
///   trigger: Button(
///     onClick: (_) => controller.toggle(),
///     child: Text('Toggle'),
///   ),
///   content: Text('Hello'),
/// );
/// ```
class PopoverController implements CorePopoverControllerContract {
  /// Creates a controller. Pass to [Popover.controller].
  PopoverController();

  /// Immutable snapshot of registered listeners. Mutations create a
  /// new list (`[..._listeners, listener]`) instead of using
  /// `add`/`remove` so the lint rule
  /// `avoid-collection-mutating-methods` stays satisfied.
  List<void Function()> _listeners = const [];
  bool _isOpen = false;
  bool _disposed = false;
  void Function()? _showRequested;
  void Function()? _closeRequested;

  @override
  bool get isOpen => _isOpen;

  @override
  void show() {
    if (_disposed || _isOpen) return;
    _showRequested?.call();
  }

  @override
  void close() {
    if (_disposed || !_isOpen) return;
    _closeRequested?.call();
  }

  @override
  void toggle() {
    if (_disposed) return;
    if (_isOpen) {
      _closeRequested?.call();
    } else {
      _showRequested?.call();
    }
  }

  @override
  void addListener(void Function() listener) {
    if (_disposed) return;
    _listeners = [..._listeners, listener];
  }

  @override
  void removeListener(void Function() listener) {
    if (_disposed) return;
    _listeners = _listeners.where((entry) => entry != listener).toList();
  }

  /// Internal — flipped by the owning `Popover` component when its
  /// open/close transition completes. Public callers must use
  /// [show] / [close] / [toggle].
  void notifyOpenChanged({required bool isOpen}) {
    if (_disposed || _isOpen == isOpen) return;
    _isOpen = isOpen;
    // Snapshot listeners before dispatching so a listener that calls
    // `removeListener` mid-iteration doesn't trip the iterator.
    final snapshot = List.of(_listeners);
    for (final listener in snapshot) {
      listener();
    }
  }

  /// Internal — wired by the owning `Popover` component. Public callers
  /// should use [show] / [close] / [toggle] which delegate here.
  void attachHandlers({
    required void Function() show,
    required void Function() close,
  }) {
    _showRequested = show;
    _closeRequested = close;
  }

  /// Internal — called by the owning component on dispose so the
  /// controller stops dispatching to a dead State.
  void detachHandlers() {
    _showRequested = null;
    _closeRequested = null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    detachHandlers();
    _listeners = const [];
  }
}
