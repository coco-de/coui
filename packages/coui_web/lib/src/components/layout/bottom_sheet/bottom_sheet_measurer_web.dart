/// Web implementation of [BottomSheetMeasurer].
///
/// Listens for `scroll` events on the sheet's content viewport and writes
/// [kBottomSheetMoreBelowVar] on the footer's area — `1` while more content
/// lies below the visible part, `0` once the content ends in view. The
/// footer hairline reads the variable as its opacity, so detection never
/// re-renders the component (mirrors Flutter's `extentAfter > 0` check).
///
/// A [web.ResizeObserver] on the viewport and on its content re-evaluates
/// the state when either size changes — the content can grow without the
/// viewport growing once the sheet has reached its height ceiling.
library;

import 'dart:js_interop';

import 'package:coui_web/src/components/layout/bottom_sheet/bottom_sheet_style.dart';
import 'package:web/web.dart' as web;

/// Scroll-end slack in CSS px — sub-pixel offsets at the end of a scroll
/// would otherwise keep the hairline on. Not a design token: a numeric
/// tolerance, the same as Flutter's.
const double _kScrollEndTolerance = 1;

/// Web orchestrator for one `BottomSheet`'s content viewport.
class BottomSheetMeasurer {
  /// Creates a [BottomSheetMeasurer].
  BottomSheetMeasurer({required this.viewportId, required this.footerId});

  /// `id` of the scrolling content viewport `<div>`.
  final String viewportId;

  /// `id` of the footer's area `<div>`, which carries the variable.
  final String footerId;

  web.HTMLElement? _viewport;
  web.HTMLElement? _footer;
  web.ResizeObserver? _resizeObserver;
  JSFunction? _onScroll;

  /// Resolves both elements, attaches the listener and the observer, and
  /// writes the initial state. Idempotent.
  void attach() {
    if (_viewport != null) return;
    final viewport = web.document.getElementById(viewportId);
    final footer = web.document.getElementById(footerId);
    if (viewport == null || footer == null) return;
    _viewport = viewport as web.HTMLElement;
    _footer = footer as web.HTMLElement;

    _onScroll = _handleScroll.toJS;
    viewport.addEventListener('scroll', _onScroll);

    final observer = web.ResizeObserver(_handleResize.toJS)..observe(viewport);
    final content = viewport.firstElementChild;
    if (content != null) observer.observe(content);
    _resizeObserver = observer;

    _applyState();
  }

  /// Removes the listener and disconnects the observer. Idempotent.
  void dispose() {
    final viewport = _viewport;
    final onScroll = _onScroll;
    if (viewport != null && onScroll != null) {
      viewport.removeEventListener('scroll', onScroll);
    }
    _resizeObserver?.disconnect();
    _resizeObserver = null;
    _onScroll = null;
    _viewport = null;
    _footer = null;
  }

  void _handleScroll(web.Event event) => _applyState();

  void _handleResize(JSAny entries, JSAny observer) => _applyState();

  void _applyState() {
    final viewport = _viewport;
    final footer = _footer;
    if (viewport == null || footer == null) return;
    final below =
        viewport.scrollHeight - viewport.clientHeight - viewport.scrollTop;
    footer.style.setProperty(
      kBottomSheetMoreBelowVar,
      below > _kScrollEndTolerance ? '1' : '0',
    );
  }
}
