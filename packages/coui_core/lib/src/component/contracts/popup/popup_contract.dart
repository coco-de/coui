/// Platform-independent contract for popup components.
library;

import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';

/// Contract for a unified `Popup` floating-panel component.
///
/// `Popup` is a chrome-styled container for floating content such as
/// menus, dropdowns and tooltips. It lays its [children] out along
/// [direction] and is shown / hidden through the [open] flag.
///
/// Generic over the platform widget type `W` (Flutter `Widget`, Web
/// `Component`) — all other surfaces are platform-neutral.
abstract interface class CorePopupContract<W> {
  /// Content laid out inside the popup panel.
  List<W> get children;

  /// Whether the popup panel is visible.
  bool get open;

  /// Axis the [children] are laid out along.
  CoreAxis get direction;

  /// Per-instance panel chrome style.
  ///
  /// Resolves through the nested-merge chain
  /// (`CorePopupStyle.defaultX` ← `theme.popup.style` ←
  /// `widget.popupStyle`).
  CorePopupStyle? get popupStyle;
}
