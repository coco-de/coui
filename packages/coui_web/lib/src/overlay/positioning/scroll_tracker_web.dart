/// Web-only scroll / resize tracker that keeps a popover aligned with its
/// trigger while ancestors scroll, or dismisses the popover on scroll
/// when [OverlayScrollTracker.closeOnScroll] is set.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

final _kPassiveCapture = web.AddEventListenerOptions(
  capture: true,
  passive: true,
);

/// Subscribes to scroll events on [trigger]'s ancestors and the window,
/// plus a [web.ResizeObserver] on the popover, to trigger repositioning
/// or dismissal.
class OverlayScrollTracker {
  /// Creates a [OverlayScrollTracker].
  OverlayScrollTracker({
    required this.trigger,
    required this.popover,
    required this.onChange,
    this.closeOnScroll = false,
    this.onScrollClose,
    this.trackViewportResize = false,
    this.ignorePanelScroll = false,
    this.triggerAncestorScrollOnly = false,
  });

  /// Trigger element whose scroll ancestors are observed.
  final web.HTMLElement trigger;

  /// Popover element observed for size changes.
  final web.HTMLElement popover;

  /// Called when a relayout is needed (scroll or resize).
  final void Function() onChange;

  /// When `true`, scroll events invoke [onScrollClose] instead of [onChange].
  final bool closeOnScroll;

  /// Alternative callback used when [closeOnScroll] is `true`.
  final void Function()? onScrollClose;

  /// Whether the window being resized calls [onChange] too.
  ///
  /// The popover's own [web.ResizeObserver] sees the panel change size, not
  /// the viewport: a panel held to the room the viewport leaves it needs
  /// to hear that the room changed even when the panel itself did not.
  final bool trackViewportResize;

  /// Whether a scroll inside the popover itself is left alone.
  ///
  /// `scroll` does not bubble, but a capturing listener on the window hears
  /// every element's. A panel that scrolls its own rows would otherwise
  /// measure and re-render once per scroll step, for a trigger that has not
  /// moved and a panel that has not changed size.
  final bool ignorePanelScroll;

  /// Ignore scrolling unrelated elements, including the panel itself.
  final bool triggerAncestorScrollOnly;

  JSFunction? _scrollListener;
  JSFunction? _viewportResizeListener;
  web.ResizeObserver? _resizeObserver;

  /// Begins listening. Idempotent.
  void attach() {
    if (_scrollListener != null) return;
    _scrollListener = _handleScroll.toJS;
    web.window.addEventListener('scroll', _scrollListener, _kPassiveCapture);
    _resizeObserver = web.ResizeObserver(_handleResize.toJS)..observe(popover);
    if (trackViewportResize) {
      _viewportResizeListener = _handleViewportResize.toJS;
      web.window.addEventListener('resize', _viewportResizeListener);
    }
  }

  /// Stops listening. Idempotent.
  void detach() {
    final scrollListener = _scrollListener;
    if (scrollListener != null) {
      // Use the same options instance passed to addEventListener so the
      // browser's listener-identity match succeeds (only `capture` is
      // actually compared, but staying symmetric avoids future surprises).
      web.window.removeEventListener(
        'scroll',
        scrollListener,
        _kPassiveCapture,
      );
      _scrollListener = null;
    }
    final observer = _resizeObserver;
    if (observer != null) {
      observer.disconnect();
      _resizeObserver = null;
    }
    final viewportResize = _viewportResizeListener;
    if (viewportResize != null) {
      web.window.removeEventListener('resize', viewportResize);
      _viewportResizeListener = null;
    }
  }

  void _handleViewportResize(web.Event event) {
    onChange();
  }

  void _handleScroll(web.Event event) {
    if (triggerAncestorScrollOnly) {
      if (event.target case final web.Node target) {
        if (popover.contains(target) || !target.contains(trigger)) return;
      }
    }
    if (ignorePanelScroll) {
      // Same shape as the outside-click listener: a non-`Node` target is
      // possible in principle and is not inside the panel.
      if (event.target case final web.Node target) {
        if (popover.contains(target)) return;
      }
    }
    if (closeOnScroll) {
      onScrollClose?.call();
    } else {
      onChange();
    }
  }

  void _handleResize(JSAny entries, JSAny observer) {
    onChange();
  }
}
