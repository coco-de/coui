import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'trend_chart.stories.g.dart';

/// Default preview width for the trend chart.
const _kTrendChartWidth = 360.0;

/// Knob input for [TrendChart] stories.
class TrendChartInput {
  /// Creates a [TrendChartInput].
  const TrendChartInput({
    this.width = _kTrendChartWidth,
    this.variant = CoreTrendChartVariant.line,
    this.showReference = true,
  });

  /// Horizontal size of the chart preview.
  final double width;

  /// Line or bar.
  final CoreTrendChartVariant variant;

  /// Whether to draw the dashed target line and its legend.
  final bool showReference;
}

/// Navigation metadata for the TrendChart component.
const kComponentMeta = ComponentMeta(name: 'TrendChart', path: 'display');

/// Story metadata for [TrendChart].
const kMeta = Meta(TrendChart.new, argsType: TrendChartInput.new);

final List<CoreTrendPoint> _points = [
  for (final (i, value) in <double>[
    8200,
    9100,
    8800,
    10400,
    11200,
    12480,
  ].indexed)
    CoreTrendPoint(
      date: DateTime(2026, 4 + i),
      value: value,
      label: '${4 + i}월',
      valueLabel: '${value.toInt()}명',
    ),
];

/// Default builder mapping [TrendChartInput] args to a [TrendChart].
final TrendChartDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: args.width,
    child: child,
  ),
  builder: (context, args) => TrendChart(
    variant: args.variant,
    semanticLabel: '월별 구독자 추이',
    summary: const Stat(label: '구독자', value: '12,480명'),
    periods: const ['7일', '30일', '12개월'],
    selectedPeriodIndex: 1,
    referenceValue: args.showReference ? 12000 : null,
    referenceLabel: args.showReference ? '목표 12,000명' : null,
    points: _points,
  ),
);

/// Line chart with period chips, summary and target line.
final $Default = _Story();
