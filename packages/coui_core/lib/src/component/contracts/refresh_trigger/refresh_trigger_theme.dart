/// Theme data for `RefreshTrigger` customisation.
library;

import 'package:coui_core/src/component/contracts/refresh_trigger/refresh_trigger_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `RefreshTrigger`.
///
/// Holds the project [style] applied to every `RefreshTrigger`
/// whose widget-level `refreshTriggerStyle` is null.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreRefreshTriggerStyle.defaultX)
///   → CoreRefreshTriggerTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance refreshTriggerStyle
/// ```
@immutable
class CoreRefreshTriggerTheme {
  /// Creates a [CoreRefreshTriggerTheme].
  const CoreRefreshTriggerTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreRefreshTriggerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRefreshTriggerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
