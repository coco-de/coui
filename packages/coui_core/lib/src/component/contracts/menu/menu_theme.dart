/// Theme data for `Menu` customization.
library;

import 'package:coui_core/src/component/contracts/menu/menu_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `Menu`.
///
/// Per-instance chrome flows through the composite [style] field —
/// see [CoreMenuStyle].
@immutable
class CoreMenuTheme {
  /// Creates a [CoreMenuTheme].
  const CoreMenuTheme({this.style});

  /// Project-wide composite style applied to every `Menu`.
  ///
  /// Resolved before any per-instance `widget.menuStyle`.
  final CoreMenuStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenuTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
