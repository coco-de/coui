import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform trend chart — a time series drawn as a line or
/// bars, with optional period chips, a summary slot and a dashed
/// reference line.
///
/// Data and every display string come from the caller; the chart only
/// positions them. Uses [CoreTrendChartContract] from `coui_core`, so the
/// Web `TrendChart` takes the same named properties.
///
/// Example:
/// ```dart
/// TrendChart(
///   semanticLabel: '월별 구독자 추이',
///   summary: const Stat(label: '구독자', value: '12,480'),
///   periods: const ['7일', '30일', '12개월'],
///   selectedPeriodIndex: 1,
///   onPeriodChanged: (i) => setState(() => period = i),
///   points: [
///     CoreTrendPoint(date: DateTime(2026, 9), value: 11200, label: '9월'),
///     CoreTrendPoint(date: DateTime(2026, 10), value: 12480, label: '10월'),
///   ],
/// )
/// ```
class TrendChart extends StatelessWidget
    implements CoreTrendChartContract<Widget> {
  /// Creates a [TrendChart].
  const TrendChart({
    required this.points,
    super.key,
    this.variant = CoreTrendChartVariant.defaultVariant,
    this.referenceValue,
    this.referenceLabel,
    this.valueFormatter,
    this.periods = const [],
    this.selectedPeriodIndex,
    this.onPeriodChanged,
    this.summary,
    this.empty,
    this.semanticLabel,
    this.trendChartStyle,
  });

  @override
  final CoreTrendChartVariant variant;

  @override
  final List<CoreTrendPoint> points;

  @override
  final double? referenceValue;

  @override
  final String? referenceLabel;

  @override
  final String Function(double value)? valueFormatter;

  @override
  final List<String> periods;

  @override
  final int? selectedPeriodIndex;

  @override
  final void Function(int index)? onPeriodChanged;

  @override
  final Widget? summary;

  @override
  final Widget? empty;

  @override
  final String? semanticLabel;

  @override
  final CoreTrendChartStyle? trendChartStyle;

  /// Returns a copy of this [TrendChart] with the given fields replaced.
  TrendChart copyWith({
    Key? key,
    CoreTrendChartVariant? variant,
    List<CoreTrendPoint>? points,
    double? referenceValue,
    String? referenceLabel,
    String Function(double value)? valueFormatter,
    List<String>? periods,
    int? selectedPeriodIndex,
    void Function(int index)? onPeriodChanged,
    Widget? summary,
    Widget? empty,
    String? semanticLabel,
    CoreTrendChartStyle? trendChartStyle,
  }) {
    return TrendChart(
      key: key ?? this.key,
      variant: variant ?? this.variant,
      points: points ?? this.points,
      referenceValue: referenceValue ?? this.referenceValue,
      referenceLabel: referenceLabel ?? this.referenceLabel,
      valueFormatter: valueFormatter ?? this.valueFormatter,
      periods: periods ?? this.periods,
      selectedPeriodIndex: selectedPeriodIndex ?? this.selectedPeriodIndex,
      onPeriodChanged: onPeriodChanged ?? this.onPeriodChanged,
      summary: summary ?? this.summary,
      empty: empty ?? this.empty,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      trendChartStyle: trendChartStyle ?? this.trendChartStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTrendChart(
      context,
      variant: variant,
      points: points,
      referenceValue: referenceValue,
      valueFormatter: valueFormatter,
      trendChartStyle: trendChartStyle,
    );
    final currentEmpty = empty;
    final currentSummary = summary;
    final currentReferenceLabel = referenceLabel;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: resolved.sectionSpacing,
      children: [
        ?currentSummary,
        if (periods.isNotEmpty)
          Wrap(
            spacing: resolved.periodSpacing,
            runSpacing: resolved.periodSpacing,
            children: [
              for (var i = 0; i < periods.length; i++)
                Chip(
                  label: periods[i],
                  selected: i == selectedPeriodIndex,
                  onTap: onPeriodChanged == null
                      ? null
                      : () => onPeriodChanged!(i),
                  chipStyle: resolved.periodChipStyle,
                ),
            ],
          ),
        if (points.isEmpty)
          ?currentEmpty
        else
          _TrendPlot(
            resolved: resolved,
            variant: variant,
            semanticLabel: semanticLabel,
          ),
        if (points.isNotEmpty &&
            referenceValue != null &&
            currentReferenceLabel != null)
          Row(
            spacing: resolved.legendSpacing,
            children: [
              ExcludeSemantics(
                child: CustomPaint(
                  size: Size(
                    resolved.legendSwatchWidth,
                    resolved.referenceLineWidth,
                  ),
                  painter: _DashPainter(
                    color: resolved.referenceColor,
                    dashLength: resolved.referenceDashLength,
                    dashGap: resolved.referenceDashSpacing,
                    strokeWidth: resolved.referenceLineWidth,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  currentReferenceLabel,
                  style: resolved.legendLabelTextStyle,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// The axes and the plot. Split out so the build above stays a list of
/// sections.
class _TrendPlot extends StatelessWidget {
  const _TrendPlot({
    required this.resolved,
    required this.variant,
    required this.semanticLabel,
  });

  final ResolvedTrendChart resolved;
  final CoreTrendChartVariant variant;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final labelStyle = resolved.axisLabelTextStyle;
    final dateLabels = resolved.dateLabels;
    // Date labels pin to the start, centre and end of the plot — the
    // three positions read correctly at any width, so no label can run
    // into its neighbour.
    final dateAligns = switch (dateLabels.length) {
      1 => const [TextAlign.center],
      2 => const [TextAlign.start, TextAlign.end],
      _ => const [TextAlign.start, TextAlign.center, TextAlign.end],
    };

    // `IntrinsicHeight` lets the value-axis labels push the plot taller
    // when they need more room than `plotHeight` (large text) instead of
    // overflowing it.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: .stretch,
        spacing: resolved.axisLabelSpacing,
        children: [
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: .end,
              spacing: resolved.axisLabelSpacing,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: .spaceBetween,
                    crossAxisAlignment: .end,
                    children: [
                      for (final label in resolved.tickLabels)
                        Text(label, style: labelStyle, maxLines: 1),
                    ],
                  ),
                ),
                // Holds the date-label row's height so the value axis
                // ends where the plot ends.
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Text(' ', style: labelStyle, maxLines: 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: resolved.axisLabelSpacing,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: resolved.plotHeight),
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: semanticLabel,
                      child: Stacks(
                        children: [
                          Position.fill(
                            child: ExcludeSemantics(
                              child: CustomPaint(
                                painter: _TrendChartPainter(
                                  resolved: resolved,
                                  variant: variant,
                                  textDirection: Directionality.of(context),
                                ),
                              ),
                            ),
                          ),
                          Position.fill(
                            child: Row(
                              children: [
                                for (final label in resolved.pointLabels)
                                  Expanded(
                                    child: Semantics(
                                      label: label,
                                      child: ExcludeSemantics(
                                        child: Tooltip(
                                          message: label,
                                          child: const SizedBox.expand(),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Row(
                    spacing: resolved.axisLabelSpacing,
                    children: [
                      for (var i = 0; i < dateLabels.length; i++)
                        Expanded(
                          child: Text(
                            dateLabels[i],
                            style: labelStyle,
                            textAlign: dateAligns[i],
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the grid, the reference line and the series from paint-ready
/// values. Mirrors horizontally under a right-to-left [textDirection] so
/// time flows in reading order — the hit-slot `Row` above it mirrors on
/// its own.
class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.resolved,
    required this.variant,
    required this.textDirection,
  });

  final ResolvedTrendChart resolved;
  final CoreTrendChartVariant variant;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = resolved.geometry;
    final count = geometry.pointFractions.length;
    double yOf(double fraction) => size.height * (1 - fraction);
    double xOf(int index) {
      final f = CoreTrendChartGeometry.slotCenter(index, count);
      return size.width * (textDirection == .rtl ? 1 - f : f);
    }

    final gridPaint = Paint()
      ..color = resolved.gridColor
      ..strokeWidth = resolved.gridLineWidth;
    for (var i = 0; i < geometry.ticks.length; i++) {
      final y = yOf(geometry.tickFraction(i));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final referenceFraction = geometry.referenceFraction;
    if (referenceFraction != null) {
      _paintDashes(
        canvas,
        y: yOf(referenceFraction),
        width: size.width,
        paint: Paint()
          ..color = resolved.referenceColor
          ..strokeWidth = resolved.referenceLineWidth,
        dashLength: resolved.referenceDashLength,
        dashGap: resolved.referenceDashSpacing,
      );
    }

    if (count == 0) return;
    final seriesPaint = Paint()..color = resolved.seriesColor;

    switch (variant) {
      case .bar:
        final slot = size.width / count;
        final barWidth = (slot - resolved.barSpacing).clamp(0.0, slot);
        final baseline = yOf(geometry.baselineFraction);
        final radius = resolved.barBorderRadius;
        for (var i = 0; i < count; i++) {
          final y = yOf(geometry.pointFractions[i]);
          final rect = Rect.fromLTRB(
            xOf(i) - barWidth / 2,
            y < baseline ? y : baseline,
            xOf(i) + barWidth / 2,
            y < baseline ? baseline : y,
          );
          if (rect.height <= 0) continue;
          // Round the far end only; the baseline end stays square so the
          // bar reads as starting from zero.
          final up = y < baseline;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: up ? radius.topLeft : .zero,
              topRight: up ? radius.topRight : .zero,
              bottomLeft: up ? .zero : radius.bottomLeft,
              bottomRight: up ? .zero : radius.bottomRight,
            ),
            seriesPaint,
          );
        }
      case .line:
        if (count > 1) {
          final path = Path()..moveTo(xOf(0), yOf(geometry.pointFractions[0]));
          for (var i = 1; i < count; i++) {
            path.lineTo(xOf(i), yOf(geometry.pointFractions[i]));
          }
          canvas.drawPath(
            path,
            Paint()
              ..color = resolved.seriesColor
              ..style = .stroke
              ..strokeWidth = resolved.lineWidth
              ..strokeJoin = .round
              ..strokeCap = .round,
          );
        }
        canvas.drawRRect(
          resolved.markerBorderRadius.toRRect(
            Rect.fromCircle(
              center: Offset(
                xOf(count - 1),
                yOf(geometry.pointFractions[count - 1]),
              ),
              radius: resolved.markerSize / 2,
            ),
          ),
          seriesPaint,
        );
    }
  }

  @override
  bool shouldRepaint(_TrendChartPainter oldDelegate) =>
      oldDelegate.resolved != resolved ||
      oldDelegate.variant != variant ||
      oldDelegate.textDirection != textDirection;
}

/// The legend swatch — one dashed segment in the reference style.
class _DashPainter extends CustomPainter {
  _DashPainter({
    required this.color,
    required this.dashLength,
    required this.dashGap,
    required this.strokeWidth,
  });

  final Color color;
  final double dashLength;
  final double dashGap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    _paintDashes(
      canvas,
      y: size.height / 2,
      width: size.width,
      paint: Paint()
        ..color = color
        ..strokeWidth = strokeWidth,
      dashLength: dashLength,
      dashGap: dashGap,
    );
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.dashGap != dashGap ||
      oldDelegate.strokeWidth != strokeWidth;
}

void _paintDashes(
  Canvas canvas, {
  required double y,
  required double width,
  required Paint paint,
  required double dashLength,
  required double dashGap,
}) {
  if (dashLength <= 0) return;
  for (var x = 0.0; x < width; x += dashLength + dashGap) {
    final end = x + dashLength < width ? x + dashLength : width;
    canvas.drawLine(Offset(x, y), Offset(end, y), paint);
  }
}

/// Chain sugar for merging a [CoreTrendChartStyle] patch into
/// [TrendChart.trendChartStyle]. Mirrors the Web `TrendChart.withStyle`
/// extension so both platforms read identically.
extension TrendChartStyleChain on TrendChart {
  /// Returns a copy of this [TrendChart] with [patch] merged into
  /// [trendChartStyle] (patch fields win on conflict).
  TrendChart withStyle(CoreTrendChartStyle patch) => copyWith(
    trendChartStyle: (trendChartStyle ?? const CoreTrendChartStyle()).merge(
      patch,
    ),
  );
}
