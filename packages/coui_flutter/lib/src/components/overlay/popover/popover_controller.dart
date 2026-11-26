import 'package:coui_core/coui_core.dart';
import 'package:flutter/foundation.dart';

/// Flutter binding for [CorePopoverControllerContract].
///
/// Wraps a [ChangeNotifier] so consumers can `addListener` to be
/// notified of open / close transitions and `dispose()` from
/// `State.dispose`. Open / close themselves are wired by the owning
/// `Popover` widget — the controller only reflects state and
/// requests transitions.
///
/// Example:
/// ```dart
/// final controller = PopoverController();
/// // ...
/// Popover(
///   controller: controller,
///   trigger: Button(
///     onPressed: controller.toggle,
///     child: const Text('Toggle'),
///   ),
///   content: const Text('Hello'),
/// );
/// ```
class PopoverController extends ChangeNotifier
    implements CorePopoverControllerContract {
  /// Creates a controller. Pass to [Popover.controller].
  PopoverController();

  bool _isOpen = false;
  bool _disposed = false;
  VoidCallback? _showRequested;
  VoidCallback? _closeRequested;

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

  /// Internal — flipped by the owning `Popover` widget when its
  /// underlying `PopoverController.show` resolves / closes. Public
  /// callers must use [show] / [close] / [toggle].
  void notifyOpenChanged({required bool isOpen}) {
    if (_disposed || _isOpen == isOpen) return;
    _isOpen = isOpen;
    notifyListeners();
  }

  /// Internal — wired by the owning `Popover` widget. Public callers
  /// should use [show] / [close] / [toggle] which delegate here.
  void attachHandlers({
    required VoidCallback show,
    required VoidCallback close,
  }) {
    _showRequested = show;
    _closeRequested = close;
  }

  /// Internal — called by the owning widget on dispose so the
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
    super.dispose();
  }
}
