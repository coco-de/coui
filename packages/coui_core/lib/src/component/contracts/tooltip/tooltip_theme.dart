/// Theme data for `Tooltip` customisation.
library;

import 'package:coui_core/src/component/contracts/tooltip/tooltip_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Tooltip`.
///
/// Holds the project [style] applied to every `Tooltip` whose
/// widget-level `tooltipStyle` is null.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreTooltipTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance tooltipStyle
/// ```
@immutable
class CoreTooltipTheme {
  /// Creates a [CoreTooltipTheme].
  const CoreTooltipTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreTooltipStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTooltipTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
