/// Theme data for `ContextMenu` customisation.
library;

import 'package:coui_core/src/component/contracts/context_menu/context_menu_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `ContextMenu`.
///
/// Holds the project [style] applied to every context menu whose
/// widget-level `contextMenuStyle` is null. Kept separate from
/// `CoreDropdownMenuTheme` so context menus and dropdowns can be themed
/// independently.
///
/// ### Resolve chain.
///
/// ```text
/// CoreMenuTheme.style                              // 전역 메뉴 공통
///   → CoreContextMenuTheme.style.menuStyle         // 컨텍스트 메뉴 공통
///   → widget per-instance contextMenuStyle.menuStyle
/// ```
@immutable
class CoreContextMenuTheme {
  /// Creates a [CoreContextMenuTheme].
  const CoreContextMenuTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreContextMenuStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreContextMenuTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
