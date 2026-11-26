/// Project-level theme for `SidebarSearch`.
library;

import 'package:coui_core/src/component/contracts/sidebar_search/sidebar_search_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `SidebarSearch`.
///
/// Holds the project [style] applied to every `SidebarSearch`.
/// Chrome flows only through these slots; semantic identifiers stay on
/// the widget, where the caller states them.
///
/// ```text
/// design-system default
///   → CoreSidebarSearchTheme.style
///   → widget per-instance style
/// ```
@immutable
class CoreSidebarSearchTheme {
  /// Creates a [CoreSidebarSearchTheme].
  const CoreSidebarSearchTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreSidebarSearchStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarSearchTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
