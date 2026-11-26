/// Theme overrides for the unified ToggleGroup component.
library;

import 'package:coui_core/src/component/contracts/toggle_group/toggle_group_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for a unified `ToggleGroup`.
///
/// Every chrome / dimensional override flows through the single [style]
/// slot. `ToggleGroup` has no variant enum, so there is no
/// `variantStyles` map.
@immutable
class CoreToggleGroupTheme {
  /// Creates a [CoreToggleGroupTheme].
  const CoreToggleGroupTheme({this.style});

  /// Project-wide style applied to every `ToggleGroup`.
  ///
  /// Resolved before any per-instance `toggleGroupStyle`.
  final CoreToggleGroupStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreToggleGroupTheme && other.style == style;

  @override
  int get hashCode => style.hashCode;
}
