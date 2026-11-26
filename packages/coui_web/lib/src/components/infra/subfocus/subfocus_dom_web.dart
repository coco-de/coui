/// Web implementation of `SubfocusScope`'s DOM traversal helpers.
///
/// Isolates every `package:web` / `dart:js_interop` dependency so
/// [co_subfocus.dart] stays SSR-safe behind [subfocus_dom.dart].
library;

import 'package:web/web.dart' as web;

/// Spatial arrow-key traversal direction for [moveSubfocus].
enum SubfocusMoveDirection {
  /// Up arrow.
  up,

  /// Down arrow.
  down,

  /// Left arrow.
  left,

  /// Right arrow.
  right,
}

/// Selector matching a `Subfocus` item element.
const _kSubfocusItemSelector = '[data-co-subfocus-id]';

/// Collects every enabled `Subfocus` item element inside the scope.
///
/// A CSS attribute selector matches only elements, so each `NodeList`
/// entry is safely an [web.Element]; the `focus()` call casts to
/// [web.HTMLElement] at the point of use (DOM focus always lands on an
/// `HTMLElement`), mirroring `blurActiveElement` in `web_dom_utils`.
List<web.Element> _items(web.Element scope) {
  final nodes = scope.querySelectorAll(_kSubfocusItemSelector);
  final result = <web.Element>[];
  for (var i = 0; i < nodes.length; i++) {
    // `package:web` types are extension types over `JSObject`; widening
    // to `Object?` lets the `is` check narrow from a real Dart type.
    final Object? node = nodes.item(i);
    if (node is web.Element &&
        node.getAttribute('data-co-subfocus-enabled') != 'false') {
      result.add(node);
    }
  }
  return result;
}

/// Moves DOM focus to [element] via the stronger `HTMLElement` API.
void _focus(web.Element element) {
  final html = element as web.HTMLElement;
  html.focus();
}

/// Moves DOM focus to the nearest `Subfocus` item in [direction].
///
/// Mirrors the Flutter `SubfocusScope.moveFocus` spatial algorithm —
/// it measures each candidate's offset from the currently focused item
/// and focuses the closest one strictly ahead along the requested
/// axis. When nothing is focused yet it focuses the first item.
void moveSubfocus(String scopeId, SubfocusMoveDirection direction) {
  final scope = web.document.getElementById(scopeId);
  if (scope == null) return;
  final items = _items(scope);
  if (items.isEmpty) return;

  final active = web.document.activeElement;
  final current = active != null && items.contains(active) ? active : null;
  if (current == null) {
    _focus(items.first);
    return;
  }

  final currentRect = current.getBoundingClientRect();
  final currentX = currentRect.left.toDouble();
  final currentY = currentRect.top.toDouble();
  final horizontal = direction == .left || direction == .right;
  final forward = direction == .down || direction == .right;

  web.Element? nearest;
  double? nearestDelta;
  for (final item in items) {
    if (item == current) continue;
    final rect = item.getBoundingClientRect();
    final dx = rect.left.toDouble() - currentX;
    final dy = rect.top.toDouble() - currentY;
    final delta = horizontal ? (forward ? dx : -dx) : (forward ? dy : -dy);
    if (delta <= 0) continue;
    if (nearestDelta == null || delta < nearestDelta) {
      nearest = item;
      nearestDelta = delta;
    }
  }
  if (nearest != null) _focus(nearest);
}

/// Focuses the first enabled `Subfocus` item inside the scope.
void focusFirstSubfocus(String scopeId) {
  final scope = web.document.getElementById(scopeId);
  if (scope == null) return;
  final items = _items(scope);
  if (items.isNotEmpty) _focus(items.first);
}
