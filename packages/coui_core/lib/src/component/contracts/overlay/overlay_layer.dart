/// Overlay layer category — drives the Z-axis ordering and the
/// `OverlayHandler` slot that floating components dispatch into.
///
/// Mirrors Flutter `CoUIApp.popoverHandler / tooltipHandler /
/// menuHandler` — three independent slots for different floating
/// surfaces. Same enum lives in `coui_core` so Web `CoUIWeb` can
/// expose the matching trio (`CoUIWeb.popoverHandler` etc.) and any
/// floating component (popover, tooltip, dropdown menu, hover card)
/// can ask the host's `CoreOverlayHandler` to mount its panel
/// without caring which slot it belongs to.
library;

/// Overlay slot — picks which `OverlayHandler` an entry mounts into.
enum CoreOverlayLayer {
  /// Click-driven popovers (Select, Autocomplete, DatePicker,
  /// ColorPicker, generic Popover etc.).
  popover,

  /// Hover-driven tooltips (Tooltip, hover hint).
  tooltip,

  /// Click / key-driven menus (Dropdown, NavigationMenu,
  /// ContextMenu).
  menu,

  /// Modal dialogs / alert dialogs / confirm prompts (Dialog,
  /// AlertDialog). Sits above the popover / menu / tooltip stack
  /// because dialogs are full-modal surfaces — anything else open at
  /// the time of dialog show should be visually below the backdrop.
  dialog,
}
