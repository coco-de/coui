/// Project-level theme for `SidebarGroup`.
library;

import 'package:coui_core/src/component/contracts/sidebar_group/sidebar_group_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `SidebarGroup`.
///
/// Holds the project [style] applied to every `SidebarGroup`.
/// Chrome flows only through these slots; semantic identifiers stay on
/// the widget, where the caller states them.
///
/// ```text
/// design-system default
///   → CoreSidebarGroupTheme.style
///   → widget per-instance style
/// ```
@immutable
class CoreSidebarGroupTheme {
  /// Creates a [CoreSidebarGroupTheme].
  const CoreSidebarGroupTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreSidebarGroupStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarGroupTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
