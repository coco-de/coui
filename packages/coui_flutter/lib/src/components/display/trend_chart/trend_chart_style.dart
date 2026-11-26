import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `TrendChart`.
///
/// Widget tree (`trend_chart.dart` is render-only):
///
/// ```text
/// Column (spacing: sectionSpacing)
///   ├─ summary                          // caller-supplied, optional
///   ├─ Wrap (spacing: periodSpacing)    // period chips, optional
///   │    └─ Chip × periods              // chipStyle: periodChipStyle
///   ├─ IntrinsicHeight                  // or `empty` when no points
///   │    └─ Row (spacing: axisLabelSpacing)
///   │         ├─ value-axis labels      // tickLabels, top → bottom
///   │         └─ Column
///   │              ├─ plot (minHeight: plotHeight)
///   │              │    ├─ CustomPaint  // grid · reference · series
///   │              │    └─ Row of hit slots → Tooltip(pointLabels[i])
///   │              └─ date labels       // dateLabels
///   └─ legend Row (spacing: legendSpacing)  // reference, optional
/// ```
class ResolvedTrendChart {
  /// Creates a [ResolvedTrendChart].
  const ResolvedTrendChart({
    required this.geometry,
    required this.tickLabels,
    required this.pointLabels,
    required this.dateLabels,
    required this.seriesColor,
    required this.gridColor,
    required this.referenceColor,
    required this.lineWidth,
    required this.gridLineWidth,
    required this.referenceLineWidth,
    required this.referenceDashLength,
    required this.referenceDashSpacing,
    required this.markerSize,
    required this.markerBorderRadius,
    required this.barSpacing,
    required this.barBorderRadius,
    required this.plotHeight,
    required this.sectionSpacing,
    required this.axisLabelSpacing,
    required this.axisLabelTextStyle,
    required this.legendLabelTextStyle,
    required this.legendSpacing,
    required this.legendSwatchWidth,
    required this.periodSpacing,
    required this.periodChipStyle,
  });

  /// Value-axis domain and per-point vertical fractions.
  final CoreTrendChartGeometry geometry;

  /// Value-axis labels, ordered top → bottom.
  final List<String> tickLabels;

  /// Per-point readout (`'<date>, <value>'`), indexed 1:1 with the points
  /// — the tooltip message and the accessible name of each slot.
  final List<String> pointLabels;

  /// Date-axis labels — first, middle and last point.
  final List<String> dateLabels;

  /// Series line / marker / bar colour.
  final Color seriesColor;

  /// Grid line colour.
  final Color gridColor;

  /// Reference line and legend swatch colour.
  final Color referenceColor;

  /// Series line width (logical px).
  final double lineWidth;

  /// Grid line width (logical px).
  final double gridLineWidth;

  /// Reference line width (logical px).
  final double referenceLineWidth;

  /// Reference dash length (logical px).
  final double referenceDashLength;

  /// Reference dash gap (logical px).
  final double referenceDashSpacing;

  /// Last-point marker diameter (logical px).
  final double markerSize;

  /// Corner radius of the last-point marker.
  final BorderRadius markerBorderRadius;

  /// Space between adjacent bars (logical px).
  final double barSpacing;

  /// Corner radius of a bar's far end.
  final BorderRadius barBorderRadius;

  /// Minimum plot height (logical px).
  final double plotHeight;

  /// Vertical space between sections (logical px).
  final double sectionSpacing;

  /// Space between axis labels and the plot (logical px).
  final double axisLabelSpacing;

  /// Axis label typography.
  final TextStyle axisLabelTextStyle;

  /// Legend typography.
  final TextStyle legendLabelTextStyle;

  /// Space between the legend swatch and its text (logical px).
  final double legendSpacing;

  /// Legend swatch width (logical px).
  final double legendSwatchWidth;

  /// Space between period chips (logical px).
  final double periodSpacing;

  /// Chrome forwarded raw to every period `Chip`.
  final CoreChipStyle periodChipStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTrendChart] for the given [context].
///
/// ```text
/// CoreTrendChartStyle.default*
///   → theme.coreComponentTheme.trendChart.style
///   → theme.coreComponentTheme.trendChart.variantStyles[variant]
///   → widget.trendChartStyle
/// ```
ResolvedTrendChart resolveTrendChart(
  BuildContext context, {
  required CoreTrendChartVariant variant,
  required List<CoreTrendPoint> points,
  double? referenceValue,
  String Function(double value)? valueFormatter,
  CoreTrendChartStyle? trendChartStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final trendChartTheme = theme.coreComponentTheme?.trendChart;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTrendChartStyle(), [
    trendChartTheme?.style,
    trendChartTheme?.variantStyles?[variant],
    trendChartStyle,
  ]);

  // ─── Data layout (shared Core geometry) ──────────────
  final geometry = CoreTrendChartGeometry.compute(
    values: [for (final p in points) p.value],
    variant: variant,
    tickCount: merged.axisTickCount ?? CoreTrendChartStyle.defaultAxisTickCount,
    referenceValue: referenceValue,
  );
  final format = valueFormatter ?? geometry.formatTick;
  final tickLabels = [for (final tick in geometry.ticks.reversed) format(tick)];
  final pointLabels = <String>[
    for (final p in points)
      [
        p.label ?? CoreTrendChartGeometry.formatDate(p.date),
        p.valueLabel ?? format(p.value),
      ].join(', '),
  ];
  final dateLabels = [
    for (final i in CoreTrendChartGeometry.dateLabelIndices(points.length))
      points[i].label ?? CoreTrendChartGeometry.formatDate(points[i].date),
  ];

  // ─── Stage 2 EMIT — colour ────────────────────────────
  final seriesColor = scheme
      .resolve(merged.seriesColor ?? CoreTrendChartStyle.defaultSeriesColor)
      .toValue();
  final gridColor = scheme
      .resolve(merged.gridColor ?? CoreTrendChartStyle.defaultGridColor)
      .toValue();
  final referenceColor = scheme
      .resolve(
        merged.referenceColor ?? CoreTrendChartStyle.defaultReferenceColor,
      )
      .toValue();

  // ─── Stage 2 EMIT — dimensions ────────────────────────
  final lineWidth =
      (merged.lineWidth ?? CoreTrendChartStyle.defaultLineWidth) * scaling;
  final gridLineWidth =
      (merged.gridLineWidth ?? CoreTrendChartStyle.defaultGridLineWidth) *
      scaling;
  final referenceLineWidth =
      (merged.referenceLineWidth ??
          CoreTrendChartStyle.defaultReferenceLineWidth) *
      scaling;
  final referenceDashLength =
      (merged.referenceDashLength ??
          CoreTrendChartStyle.defaultReferenceDashLength) *
      scaling;
  final referenceDashSpacing =
      (merged.referenceDashSpacing ??
          CoreTrendChartStyle.defaultReferenceDashSpacing) *
      scaling;
  final markerSize =
      (merged.markerSize ?? CoreTrendChartStyle.defaultMarkerSize) * scaling;
  final markerBorderRadius =
      (merged.markerBorderRadius ??
              CoreTrendChartStyle.defaultMarkerBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final barSpacing =
      (merged.barSpacing ?? CoreTrendChartStyle.defaultBarSpacing) * scaling;
  final barBorderRadius =
      (merged.barBorderRadius ?? CoreTrendChartStyle.defaultBarBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final plotHeight =
      (merged.plotHeight ?? CoreTrendChartStyle.defaultPlotHeight) * scaling;
  final sectionSpacing =
      theme.geometry.space(
        merged.sectionSpacing ?? CoreTrendChartStyle.defaultSectionSpacing,
      ) *
      scaling;
  final axisLabelSpacing =
      theme.geometry.space(
        merged.axisLabelSpacing ?? CoreTrendChartStyle.defaultAxisLabelSpacing,
      ) *
      scaling;
  final legendSpacing =
      theme.geometry.space(
        merged.legendSpacing ?? CoreTrendChartStyle.defaultLegendSpacing,
      ) *
      scaling;
  final legendSwatchWidth =
      (merged.legendSwatchWidth ??
          CoreTrendChartStyle.defaultLegendSwatchWidth) *
      scaling;
  final periodSpacing =
      theme.geometry.space(
        merged.periodSpacing ?? CoreTrendChartStyle.defaultPeriodSpacing,
      ) *
      scaling;

  // ─── Stage 2 EMIT — typography ────────────────────────
  final axisLabelTextStyle = CoreTrendChartStyle.defaultAxisLabelStyle
      .merge(merged.axisLabelStyle)
      .toValue(theme: theme);
  final legendLabelTextStyle = CoreTrendChartStyle.defaultLegendLabelStyle
      .merge(merged.legendLabelStyle)
      .toValue(theme: theme);

  // ─── Nested slot (raw forward — Chip resolves itself) ─
  final periodChipStyle = CoreTrendChartStyle.defaultPeriodChipStyle.merge(
    merged.periodChipStyle,
  );

  return ResolvedTrendChart(
    geometry: geometry,
    tickLabels: tickLabels,
    pointLabels: pointLabels,
    dateLabels: dateLabels,
    seriesColor: seriesColor,
    gridColor: gridColor,
    referenceColor: referenceColor,
    lineWidth: lineWidth,
    gridLineWidth: gridLineWidth,
    referenceLineWidth: referenceLineWidth,
    referenceDashLength: referenceDashLength,
    referenceDashSpacing: referenceDashSpacing,
    markerSize: markerSize,
    markerBorderRadius: markerBorderRadius,
    barSpacing: barSpacing,
    barBorderRadius: barBorderRadius,
    plotHeight: plotHeight,
    sectionSpacing: sectionSpacing,
    axisLabelSpacing: axisLabelSpacing,
    axisLabelTextStyle: axisLabelTextStyle,
    legendLabelTextStyle: legendLabelTextStyle,
    legendSpacing: legendSpacing,
    legendSwatchWidth: legendSwatchWidth,
    periodSpacing: periodSpacing,
    periodChipStyle: periodChipStyle,
  );
}
