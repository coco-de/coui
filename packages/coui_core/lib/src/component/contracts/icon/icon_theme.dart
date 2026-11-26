/// Theme data for `Icon` customization.
library;

import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Icon`.
///
/// Holds the project [style] applied to every `Icon` whose
/// widget-level `style` is null. Composite parents
/// (`CoreButtonStyle.leadingIconStyle`, etc.) sit between the theme
/// and the widget — see Epic #1302 for the full nested resolve chain:
///
/// ```text
/// design system default
///   → theme.icon.style
///   → parent component slot override
///   → widget per-instance style
/// ```
@immutable
class CoreIconTheme {
  /// Creates a [CoreIconTheme].
  const CoreIconTheme({this.style});

  /// Project-level style. `null` → no project override (the widget
  /// falls back further down the resolve chain).
  final CoreIconStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreIconTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
