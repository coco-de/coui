/// Web-only listener that dismisses a popover on document-level
/// outside-click and `Escape` key events.
///
/// Uses the **capture** phase so the listener fires even if the popover
/// content calls `stopPropagation()` internally; in return the listener
/// checks whether the target is a descendant of either the trigger or
/// the popover before invoking the dismiss callback.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

final _kCapture = web.AddEventListenerOptions(capture: true);

/// Registers a document-level capture listener for outside-click / ESC.
class OverlayOutsideClick {
  /// Creates a [OverlayOutsideClick] listener.
  OverlayOutsideClick({
    required this.trigger,
    required this.popover,
    required this.onDismiss,
    this.listenEsc = true,
  });

  /// Element users may click/tap without dismissing the popover.
  final web.HTMLElement trigger;

  /// Element users may interact with without dismissing the popover.
  final web.HTMLElement popover;

  /// Called when the listener detects an outside click or ESC press.
  final void Function() onDismiss;

  /// Whether to listen for the `Escape` key.
  final bool listenEsc;

  JSFunction? _clickListener;
  JSFunction? _keyListener;

  /// Begins listening on `document`. Idempotent.
  void attach() {
    if (_clickListener != null) return;
    _clickListener = _handleClick.toJS;
    web.document.addEventListener(
      'mousedown',
      _clickListener,
      _kCapture,
    );
    if (listenEsc) {
      _keyListener = _handleKey.toJS;
      web.document.addEventListener('keydown', _keyListener, _kCapture);
    }
  }

  /// Stops listening. Idempotent.
  void detach() {
    final click = _clickListener;
    if (click != null) {
      web.document.removeEventListener('mousedown', click, _kCapture);
      _clickListener = null;
    }
    final key = _keyListener;
    if (key != null) {
      web.document.removeEventListener('keydown', key, _kCapture);
      _keyListener = null;
    }
  }

  void _handleClick(web.Event event) {
    // event.target is nullable EventTarget; Node is a subtype of EventTarget,
    // but non-Node targets (e.g. XMLHttpRequest) are possible in principle.
    if (event.target case final web.Node target) {
      if (_contains(trigger, target) || _contains(popover, target)) return;
      onDismiss();
    }
  }

  void _handleKey(web.KeyboardEvent event) {
    if (event.key == 'Escape') onDismiss();
  }

  bool _contains(web.HTMLElement ancestor, web.Node target) {
    return ancestor.contains(target);
  }
}
