/// Platform-independent contract for the unified `DropdownMenu`.
library;

import 'package:coui_core/src/component/contracts/dropdown_menu/dropdown_menu_style.dart';
import 'package:coui_core/src/component/contracts/menu/menu_contract.dart';
import 'package:coui_core/src/component/contracts/popover/popover_controller_contract.dart';

/// Contract for the unified `DropdownMenu` component.
///
/// `DropdownMenu` renders a [trigger] that, when activated, reveals
/// its [items] as a floating panel anchored beneath it. Selecting an
/// enabled action item invokes its `onPressed` callback and closes the
/// panel.
///
/// Generic over the platform widget type `W` (Flutter `Widget`, Web
/// `Component`) — all other surfaces are platform-neutral. Distinct
/// from the legacy `CoreDropdownMenuContract` (Epic #1302 nested-style
/// pattern) which the deprecated `DropdownMenu` still implements.
abstract interface class CoreDropdownMenuViewContract<W> {
  /// The element that opens the menu when activated.
  W get trigger;

  /// The action / divider rows revealed in the dropdown panel — the
  /// unified [CoreMenuItem] model shared with `Menu` / `Menubar` /
  /// `ContextMenu`.
  List<CoreMenuItem<W>> get items;

  /// Per-instance style.
  ///
  /// The dropdown composes the unified `Menu`, so its chrome flows through
  /// the single [CoreDropdownMenuStyle] slot: [CoreDropdownMenuStyle.menuStyle]
  /// (a `CoreMenuStyle` — panel box, per-row button, icons, gaps …)
  /// raw-forwarded to the inner `Menu`, plus the placement
  /// [CoreDropdownMenuStyle.menuOffset]. Resolves through the nested-merge
  /// chain (`CoreMenuTheme.style` ← `CoreDropdownMenuTheme.style` ←
  /// `widget.dropdownMenuStyle`).
  CoreDropdownMenuStyle? get dropdownMenuStyle;

  /// Optional controller for imperative open / close.
  ///
  /// Shares the unified [CorePopoverControllerContract] surface with
  /// `Popover` — external callers create a `PopoverController`, pass it
  /// here, and drive open / close themselves (Flutter:
  /// `PopoverController`, Web: `PopoverController`). The dropdown is a
  /// single trigger-anchored panel, so it reuses the same controller
  /// rather than a bespoke one.
  CorePopoverControllerContract? get controller;
}
