/// Theme data for `DropdownMenu` customisation.
library;

import 'package:coui_core/src/component/contracts/dropdown_menu/dropdown_menu_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `DropdownMenu` (`ContextMenu` has its
/// own `CoreContextMenuTheme`; `Menu` / `Menubar` their own themes).
///
/// Holds the project [style] applied to every dropdown menu whose
/// widget-level `dropdownMenuStyle` is null.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreDropdownMenuTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance dropdownMenuStyle
/// ```
@immutable
class CoreDropdownMenuTheme {
  /// Creates a [CoreDropdownMenuTheme].
  const CoreDropdownMenuTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreDropdownMenuStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDropdownMenuTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
