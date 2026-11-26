/// Web implementation of the `ContextMenu` DOM helpers.
///
/// Selected by the conditional export in `context_menu_dom.dart` for browser
/// builds, so `context_menu.dart` carries no `package:web` import.
///
/// Every read here is made when it is asked for and never kept: a finger that
/// glides over a list is judged against the rows where the browser has them at
/// that instant, scrolled, animating or re-laid out.
library;

import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/roving_focus.dart' show kRovingItemAttribute;
import 'package:coui_web/src/overlay/positioning/fit.dart'
    show kOverlayFitScrollerClass;
import 'package:coui_web/src/util/core_to_css.dart' show measuredPxCss;
import 'package:web/web.dart' as web;

/// The elements that are rows of a menu a finger can choose: the action, the
/// checkbox and the radio rows. A nested menu's rows come after their parent
/// row in document order, which is the order they are laid out in.
const String _kRowSelector =
    '[role="menuitem"],[role="menuitemcheckbox"],[role="menuitemradio"]';

CoreMenuBox _boxOf(web.Element element) {
  final rect = element.getBoundingClientRect();

  return CoreMenuBox(
    left: rect.left,
    top: rect.top,
    right: rect.right,
    bottom: rect.bottom,
  );
}

/// The part of [row] that can be seen: its box clipped to the menu's own box
/// and to every list above it that scrolls (the elements marked
/// `co-fit-scroller`) — an inline submenu's rows sit in two. A row nothing of
/// which can be seen gets an empty box, which no point is inside.
CoreMenuBox _visibleBox(web.Element row, web.Element panel, CoreMenuBox menu) {
  var visible = _boxOf(row).intersect(menu);
  for (
    var ancestor = row.parentElement;
    visible != null && ancestor != null && ancestor != panel;
    ancestor = ancestor.parentElement
  ) {
    if (ancestor.classList.contains(kOverlayFitScrollerClass)) {
      visible = visible.intersect(_boxOf(ancestor));
    }
  }

  return visible ??
      CoreMenuBox(
        left: menu.left,
        top: menu.top,
        right: menu.left,
        bottom: menu.top,
      );
}

/// Measures every interactive row of the menu inside the panel [panelId], in
/// document order, in client coordinates.
///
/// A row's [CoreMenuBox] is the part of it that can be seen (see
/// [_visibleBox]). A row scrolled out of view keeps its place in the list with
/// an empty box, so a finger over the panel's edge is never over a row it
/// cannot see. `enabled` is false for a row that says `aria-disabled`.
///
/// `id` is the row's `data-roving-item` value, which is unique per row across
/// every menu in the panel, nested ones included.
List<({String id, CoreMenuBox box, bool enabled})> measureMenuRows(
  String panelId,
) {
  final panel = web.document.getElementById(panelId);
  if (panel == null) return const [];
  final menu = panel.querySelector('[role="menu"]');
  if (menu == null) return const [];

  final menuBox = _boxOf(menu);
  final rows = panel.querySelectorAll(_kRowSelector);
  final measured = <({String id, CoreMenuBox box, bool enabled})>[];
  for (var index = 0; index < rows.length; index++) {
    final node = rows.item(index);
    if (node == null || !node.isA<web.Element>()) continue;
    final row = node as web.Element;
    measured.add((
      id: row.getAttribute(kRovingItemAttribute) ?? '',
      box: _visibleBox(row, panel, menuBox),
      enabled: row.getAttribute('aria-disabled') != 'true',
    ));
  }

  return measured;
}

/// Activates the row [rowId] of the panel [panelId] exactly as a tap on it
/// does: the row's own `click` runs, so its handler, the menu's "close first"
/// order and a toggle's flip are the ones a tap gets, not a second path.
/// Returns false when the row is not there.
bool clickMenuRow(String panelId, String rowId) {
  final panel = web.document.getElementById(panelId);
  final row = panel?.querySelector('[$kRovingItemAttribute="$rowId"]');
  if (row == null || !row.isA<web.HTMLElement>()) return false;
  (row as web.HTMLElement).click();

  return true;
}

/// The box of the panel [panelId] once it has been given its place, in client
/// coordinates, or `null` while it has not: a panel that has no `left` yet is
/// still where the layout happened to put it, and measuring that would place
/// whatever goes around it around the wrong box.
CoreMenuBox? measurePlacedPanel(String panelId) {
  final panel = web.document.getElementById(panelId);
  if (panel == null || !panel.isA<web.HTMLElement>()) return null;
  if ((panel as web.HTMLElement).style.left.isEmpty) return null;

  return _boxOf(panel);
}

/// The size the element [elementId] takes when nothing but the window holds it
/// — the size a preview is laid out at before the room around the menu says
/// how much of it can be shown — or `null` when it is not there.
///
/// The element is measured where the window is largest for it (its corner at
/// the origin, held to [maxWidth] × [maxHeight]) and put back before the
/// browser paints, so the measurement is the only trace it leaves. The
/// declarative styles are the element's own and are never changed by it.
({double width, double height})? measureNaturalSize(
  String elementId, {
  required double maxWidth,
  required double maxHeight,
}) {
  final element = web.document.getElementById(elementId);
  if (element == null || !element.isA<web.HTMLElement>()) return null;
  final style = (element as web.HTMLElement).style;
  final left = style.left;
  final top = style.top;
  final width = style.maxWidth;
  final height = style.maxHeight;
  style
    ..left = '0px'
    ..top = '0px'
    ..maxWidth = measuredPxCss(maxWidth)
    ..maxHeight = measuredPxCss(maxHeight);
  final rect = element.getBoundingClientRect();
  style
    ..left = left
    ..top = top
    ..maxWidth = width
    ..maxHeight = height;

  return (width: rect.width, height: rect.height);
}

/// Asks the browser for [callback] on its next frame
/// (`requestAnimationFrame`) and returns the function that withdraws the
/// request. The lift of a context menu's source draws one step per frame.
void Function() requestContextMenuFrame(void Function() callback) {
  final id = web.window.requestAnimationFrame(((double _) => callback()).toJS);

  return () => web.window.cancelAnimationFrame(id);
}

/// The browser's monotonic clock (`performance.now()`), the one the lift's
/// timeline is read off. It is the clock `requestAnimationFrame` timestamps
/// are in, and a test of the page can read the same.
Duration contextMenuClock() =>
    Duration(microseconds: (web.window.performance.now() * 1000).round());
