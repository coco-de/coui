/// Project-level theme for `SidebarRailItem`.
library;

import 'package:coui_core/src/component/contracts/sidebar_rail_item/sidebar_rail_item_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `SidebarRailItem`.
///
/// Holds the project [style] applied to every `SidebarRailItem`.
/// Chrome flows only through these slots; semantic identifiers stay on
/// the widget, where the caller states them.
///
/// ```text
/// design-system default
///   → CoreSidebarRailItemTheme.style
///   → widget per-instance style
/// ```
@immutable
class CoreSidebarRailItemTheme {
  /// Creates a [CoreSidebarRailItemTheme].
  const CoreSidebarRailItemTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreSidebarRailItemStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarRailItemTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
