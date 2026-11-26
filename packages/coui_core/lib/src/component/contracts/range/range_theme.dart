/// Theme data for `Range` customisation.
library;

import 'package:coui_core/src/component/contracts/range/range_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Range`.
///
/// Holds the project [style] applied to every `Range` whose
/// widget-level `rangeStyle` is null. Range has no public variant
/// enum, so there is no `variantStyles` map.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreRangeTheme.style                          // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance rangeStyle
/// ```
@immutable
class CoreRangeTheme {
  /// Creates a [CoreRangeTheme].
  const CoreRangeTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreRangeStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRangeTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
