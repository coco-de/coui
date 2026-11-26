/// Project-level theme overrides for trend chart components.
///
/// ```text
/// CoreTrendChartStyle.default*
///   → CoreTrendChartStyle.defaultsByVariant[variant]
///   → CoreTrendChartTheme.style                     // 프로젝트 공통
///   → CoreTrendChartTheme.variantStyles[variant]    // variant 별
///   → widget.trendChartStyle                        // 인스턴스별
/// ```
library;

import 'package:coui_core/src/component/contracts/trend_chart/trend_chart_style.dart';
import 'package:coui_core/src/component/contracts/trend_chart/trend_chart_variant.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `TrendChart`.
@immutable
class CoreTrendChartTheme {
  /// Creates a [CoreTrendChartTheme].
  const CoreTrendChartTheme({this.style, this.variantStyles});

  /// Project-wide style applied to every `TrendChart`.
  final CoreTrendChartStyle? style;

  /// Per-variant project-wide style, merged after [style].
  final Map<CoreTrendChartVariant, CoreTrendChartStyle>? variantStyles;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreTrendChartTheme || style != other.style) return false;
    final a = variantStyles;
    final b = other.variantStyles;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null
        ? null
        : Object.hashAllUnordered(
            variantStyles!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );
}
