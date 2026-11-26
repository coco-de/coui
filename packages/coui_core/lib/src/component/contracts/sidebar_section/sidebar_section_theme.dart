/// Project-level theme for `SidebarSection`.
library;

import 'package:coui_core/src/component/contracts/sidebar_section/sidebar_section_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `SidebarSection`.
///
/// Holds the project [style] applied to every `SidebarSection`.
/// Chrome flows only through these slots; semantic identifiers stay on
/// the widget, where the caller states them.
///
/// ```text
/// design-system default
///   → CoreSidebarSectionTheme.style
///   → widget per-instance style
/// ```
@immutable
class CoreSidebarSectionTheme {
  /// Creates a [CoreSidebarSectionTheme].
  const CoreSidebarSectionTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreSidebarSectionStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSidebarSectionTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
