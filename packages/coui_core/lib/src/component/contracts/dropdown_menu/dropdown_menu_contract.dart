/// Platform-independent contract for dropdown / context / menubar
/// menu components.
library;

import 'package:coui_core/src/component/contracts/dropdown_menu/dropdown_menu_style.dart';

/// Contract for a dropdown / context / menubar menu component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [dropdownMenuStyle] field — see [CoreDropdownMenuStyle]
/// for the merge chain. Behaviour fields (autofocus / dismissable
/// …) stay flat on the implementing widget but are intentionally
/// **not** part of this contract — concrete widgets (Flutter
/// `DropdownMenu`, Web `Menu` etc.) declare their own
/// behavioural surface.
abstract interface class CoreDropdownMenuContract {
  /// Per-instance menu style covering popover / trigger button /
  /// item button / header text slot styles plus separator chrome
  /// (color / thickness / indent).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreDropdownMenuTheme.style
  ///   → parent component slot override
  ///   → widget.dropdownMenuStyle
  /// ```
  CoreDropdownMenuStyle? get dropdownMenuStyle;
}
