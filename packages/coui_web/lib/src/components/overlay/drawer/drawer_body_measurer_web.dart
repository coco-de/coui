/// Web implementation of [DrawerBodyMeasurer].
///
/// The drawer body is a scroll container, so a touch on it pans it by
/// default and the drag never reaches the panel. When the body's content
/// fits along the slide axis there is nothing to pan, and the drawer hands
/// that touch to its own drag — the Flutter twin's gesture arena does the
/// same, where only a scrollable that can scroll takes the drag. The
/// measurer reports which case holds; the resolver turns it into the body's
/// `touch-action`.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Watches one drawer body and reports whether its content fits along the
/// slide axis.
class DrawerBodyMeasurer {
  /// Creates a [DrawerBodyMeasurer].
  DrawerBodyMeasurer({
    required this.bodyId,
    required this.horizontal,
    required this.onFitsChanged,
  });

  /// `id` of the body `<div>` — the panel's scrolling region.
  final String bodyId;

  /// Whether the drawer slides horizontally (a side drawer) — the axis the
  /// fit is measured on.
  final bool horizontal;

  /// Called with the new answer each time it changes, and once on attach.
  final void Function({required bool fits}) onFitsChanged;

  web.HTMLElement? _body;
  web.ResizeObserver? _observer;
  bool? _fits;

  /// Resolves the body, starts observing it, and reports the first answer.
  /// Idempotent.
  void attach() {
    if (_body != null) return;
    final element = web.document.getElementById(bodyId);
    if (element == null) return;
    final body = element as web.HTMLElement;
    _body = body;
    final observer = web.ResizeObserver(_handleResize.toJS)..observe(body);
    // Once the panel reaches its cap the body's own box stops growing, so
    // its children are watched too — their growth is what starts overflow.
    final children = body.children;
    for (var i = 0; i < children.length; i++) {
      final child = children.item(i);
      if (child != null) observer.observe(child);
    }
    _observer = observer;
    _report();
  }

  /// Disconnects the observer. Idempotent.
  void dispose() {
    _observer?.disconnect();
    _observer = null;
    _body = null;
  }

  void _handleResize(JSAny entries, JSAny observer) => _report();

  void _report() {
    final body = _body;
    if (body == null) return;
    final fits = horizontal
        ? body.scrollWidth <= body.clientWidth
        : body.scrollHeight <= body.clientHeight;
    if (fits == _fits) return;
    _fits = fits;
    onFitsChanged(fits: fits);
  }
}
