/// SSR-safe stub for the `ContextMenu` DOM helpers.
///
/// There is no document on the server, so nothing is measured and nothing is
/// activated. The browser implementation lives in `context_menu_dom_web.dart`.
library;

import 'package:coui_core/coui_core.dart';

/// Stub — no rows to measure without a DOM.
List<({String id, CoreMenuBox box, bool enabled})> measureMenuRows(
  String panelId,
) => const [];

/// Stub — no row to activate without a DOM.
bool clickMenuRow(String panelId, String rowId) => false;

/// Stub — no panel to measure without a DOM.
CoreMenuBox? measurePlacedPanel(String panelId) => null;

/// Stub — no element to measure without a DOM.
({double width, double height})? measureNaturalSize(
  String elementId, {
  required double maxWidth,
  required double maxHeight,
}) => null;

/// Stub — no frames without a DOM; the request is never answered.
void Function() requestContextMenuFrame(void Function() callback) => () {};

/// Stub — no clock without a DOM.
Duration contextMenuClock() => Duration.zero;
