/// Theme data for `Drawer` customisation.
library;

import 'package:coui_core/src/component/contracts/drawer/drawer_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Drawer`.
///
/// Holds the project [style] applied to every `Drawer` whose
/// widget-level `drawerStyle` is null.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreDrawerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance drawerStyle
/// ```
///
/// ### Type parameters
///
/// Mirrors [CoreDrawerStyle]:
///   - `Clr` — colour type (Flutter `Color`, Web `String`).
@immutable
class CoreDrawerTheme {
  /// Creates a [CoreDrawerTheme].
  const CoreDrawerTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreDrawerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDrawerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
