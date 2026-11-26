/// Platform-independent contract for unified trend chart components.
///
/// Defines the interface that all TrendChart implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/trend_chart/trend_chart_style.dart';
import 'package:coui_core/src/component/contracts/trend_chart/trend_chart_variant.dart';
import 'package:meta/meta.dart';

/// One data point of a `TrendChart` series.
///
/// The chart never formats anything itself — [label] and [valueLabel]
/// are display strings the caller already formatted for its locale.
/// When they are omitted the chart falls back to locale-neutral forms
/// (ISO date / Latin-digit number) from `CoreTrendChartGeometry`.
@immutable
class CoreTrendPoint {
  /// Creates a [CoreTrendPoint].
  const CoreTrendPoint({
    required this.date,
    required this.value,
    this.label,
    this.valueLabel,
  });

  /// The moment this point describes. Points are drawn in list order
  /// at equal spacing — the date feeds the fallback label only.
  final DateTime date;

  /// The measured value. Must be finite; negative values are allowed.
  final double value;

  /// Caller-formatted x-axis label (e.g. `'3월 1일'`).
  final String? label;

  /// Caller-formatted value (e.g. `'1,234원'`), read by the tooltip and
  /// by assistive technology.
  final String? valueLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTrendPoint &&
          date == other.date &&
          value == other.value &&
          label == other.label &&
          valueLabel == other.valueLabel;

  @override
  int get hashCode => Object.hash(date, value, label, valueLabel);
}

/// Contract for a unified trend chart — a time series drawn as a line
/// or bars, with optional period chips, a summary slot and a reference
/// line (target / budget).
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreTrendChartContract<W> {
  /// How the series is drawn.
  CoreTrendChartVariant get variant;

  /// The series, in display order (oldest first).
  List<CoreTrendPoint> get points;

  /// Optional reference value drawn as a dashed line (target, budget).
  double? get referenceValue;

  /// Caller-formatted legend text for [referenceValue]. The legend row
  /// renders only when both are set.
  String? get referenceLabel;

  /// Formats an axis tick value. `null` uses the locale-neutral
  /// `CoreTrendChartGeometry.formatTick`.
  String Function(double value)? get valueFormatter;

  /// Period chip labels (e.g. `['7일', '30일', '12개월']`). Empty hides
  /// the chip row.
  List<String> get periods;

  /// Index into [periods] of the selected chip.
  int? get selectedPeriodIndex;

  /// Called with the tapped chip's index. `null` renders the chips
  /// non-interactive.
  void Function(int index)? get onPeriodChanged;

  /// Summary slot rendered above the chart — typically a `Stat`.
  W? get summary;

  /// Rendered in place of the plot when [points] is empty.
  W? get empty;

  /// Accessible name of the plot (e.g. `'월별 구독자 추이'`).
  String? get semanticLabel;

  /// Per-instance chrome / dimensional style.
  ///
  /// ```text
  /// CoreTrendChartStyle.default*
  ///   → CoreTrendChartTheme.style
  ///   → CoreTrendChartTheme.variantStyles[variant]
  ///   → widget.trendChartStyle
  /// ```
  CoreTrendChartStyle? get trendChartStyle;
}
