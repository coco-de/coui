import 'dart:js_interop';

import 'package:coui_web/src/components/navigation/navigation_bar/navigation_compact_tracker.dart';
import 'package:web/web.dart' as web;

/// Follows the content a bar navigates as it scrolls — the DOM half of the
/// bar's `CoreNavigationCompact.onScroll`.
///
/// Every bar that follows shares one capturing listener on the document, so
/// a page of bars costs one listener and a scroll that no bar follows costs a
/// loop over none. The listener reads where the scroller is; the rule that
/// turns that into "compact or not" is Core's, through
/// [NavigationCompactTracker].
class NavigationCompactRuntime {
  /// Follows the content of the bar whose root element carries [elementId].
  NavigationCompactRuntime({required this.elementId, required this.onChanged}) {
    _bars.add(this);
    if (_bars.length == 1) _install();
  }

  /// The bar's root element's id.
  final String elementId;

  /// Called when the content's scrolling makes the bar compact or returns
  /// it.
  final void Function({required bool compact}) onChanged;

  final NavigationCompactTracker _tracker = NavigationCompactTracker();

  static final Set<NavigationCompactRuntime> _bars = {};
  static JSFunction? _listener;

  static void _install() {
    final listener = _listener = ((web.Event event) {
      final target = event.target;
      // A scroll of the page itself is reported on the document.
      final scroller = target != null && target.isA<web.Element>()
          ? target as web.Element
          : web.document.scrollingElement;
      if (scroller == null) return;
      for (final bar in _bars.toList()) {
        bar._scrolled(scroller);
      }
    }).toJS;
    web.document.addEventListener('scroll', listener, true.toJS);
  }

  /// Whether [scroller] scrolls the content [bar] navigates.
  ///
  /// The content is what scrolls inside the scaffold the bar belongs to, and
  /// the scrollport that scaffold itself scrolls in — the Web scaffold grows
  /// with its content and leaves the scrolling to whatever holds it, the
  /// page included. A scroller further out, with another between it and the
  /// bar, moves the bar's whole scrollport rather than the content. Without
  /// a scaffold the bar's parent stands in for one.
  static bool _follows(web.Element bar, web.Element scroller) {
    if (bar.contains(scroller)) return false;
    // Offstage tab panels can still dispatch queued/programmatic events.
    // A box with hidden visibility still has client rects, unlike display:none.
    if (scroller.getClientRects().length == 0 ||
        web.window.getComputedStyle(scroller).visibility != 'visible') {
      return false;
    }
    final scope = bar.closest('[data-coui-scaffold]') ?? bar.parentElement;
    if (scope != null && scope.contains(scroller)) {
      // Only the outer content scrollport drives the bar. Inner lists and
      // editors may move or reach zero without the reader moving the page.
      // Horizontal page containers do not count as vertical ancestors.
      for (
        var node = scroller.parentElement;
        node != null;
        node = node.parentElement
      ) {
        if (_scrollsVertically(node)) return false;
      }
      return true;
    }
    if (!scroller.contains(bar)) return false;
    for (
      var node = bar.parentElement;
      node != null && node != scroller;
      node = node.parentElement
    ) {
      if (_scrollsVertically(node)) return false;
    }

    return true;
  }

  static bool _scrollsVertically(web.Element element) {
    if (element.scrollHeight <= element.clientHeight) return false;
    if (element == web.document.scrollingElement) return true;
    final overflow = web.window.getComputedStyle(element).overflowY;
    return overflow != 'visible' && overflow != 'clip';
  }

  void _scrolled(web.Element scroller) {
    final bar = web.document.getElementById(elementId);
    if (bar == null || !_follows(bar, scroller)) return;
    final was = _tracker.compact;
    final compact = _tracker.scrolled(
      scroller,
      offset: scroller.scrollTop,
      maxExtent: (scroller.scrollHeight - scroller.clientHeight).toDouble(),
    );
    if (compact != was) onChanged(compact: compact);
  }

  /// Returns the bar in full — another destination was selected, and what
  /// replaces the content starts with the bar at its resting size.
  void reset() => _tracker.reset();

  /// Stops following, and takes the shared listener down with the last bar.
  void dispose() {
    _bars.remove(this);
    final listener = _listener;
    if (_bars.isEmpty && listener != null) {
      web.document.removeEventListener('scroll', listener, true.toJS);
      _listener = null;
    }
  }
}
