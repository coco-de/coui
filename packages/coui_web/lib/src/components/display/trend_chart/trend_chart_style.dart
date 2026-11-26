import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `TrendChart`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // flex column, sectionSpacing gap
///   ├─ summary                              // caller-supplied, optional
///   ├─ periodRow (<div>)                    // flex-wrap, periodSpacing gap
///   │    └─ Chip × periods                  // chipStyle: periodChipStyle
///   ├─ plotRow (<div>)                      // or `empty` when no points
///   │    ├─ tickColumn (<div>, aria-hidden)
///   │    │    ├─ tickLabels (<div>)         // justify-between
///   │    │    │    └─ axisLabel (<span>) × ticks
///   │    │    └─ axisSpacer (<span>)        // holds the date row's height
///   │    └─ plotColumn (<div>)
///   │         ├─ plot (<div role=group>)    // relative, min-height
///   │         │    ├─ gridLines[i] (<div>)
///   │         │    ├─ reference (<svg>) → referenceStroke (<line>)
///   │         │    ├─ bars[i] (<div>)       // bar variant
///   │         │    ├─ line (<svg>) → lineStroke (<polyline>) // line variant
///   │         │    ├─ marker (<div>)        // line variant
///   │         │    └─ hitRow (<div role=list>)
///   │         │         └─ Tooltip(hitSlot) → hitTarget (<div role=listitem>)
///   │         └─ dateRow (<div>, aria-hidden)
///   │              └─ dateLabels[i] (<span>)
///   └─ legend (<div>)
///        ├─ legendSwatch (<svg>) → referenceStroke (<line>)
///        └─ legendLabel (<span>)
/// ```
///
/// Positions are percentages of the plot taken from the shared
/// `CoreTrendChartGeometry`, so a point sits where the Flutter painter
/// puts it. Horizontal offsets use logical properties
/// (`inset-inline-start`) and the line flips under `dir="rtl"`, so time
/// flows in reading order as it does on Flutter.
class ResolvedTrendChart implements WebResolvedChrome {
  /// Creates a [ResolvedTrendChart].
  const ResolvedTrendChart({
    required this.root,
    required this.periodRow,
    required this.plotRow,
    required this.tickColumn,
    required this.tickLabels,
    required this.axisLabel,
    required this.axisSpacer,
    required this.plotColumn,
    required this.plot,
    required this.gridLines,
    required this.reference,
    required this.referenceStroke,
    required this.bars,
    required this.line,
    required this.lineStroke,
    required this.marker,
    required this.hitRow,
    required this.hitSlot,
    required this.hitTarget,
    required this.dateRow,
    required this.dateLabels,
    required this.legend,
    required this.legendSwatch,
    required this.legendLabel,
    required this.periodChipStyle,
    required this.series,
  });

  /// Outer column.
  @override
  final WebElementChrome root;

  /// Period chip row.
  final WebElementChrome periodRow;

  /// Value axis + plot row.
  final WebElementChrome plotRow;

  /// Value-axis column.
  final WebElementChrome tickColumn;

  /// Value-axis label stack (`justify-between`).
  final WebElementChrome tickLabels;

  /// One axis label (value or date).
  final WebElementChrome axisLabel;

  /// Invisible spacer holding the date row's height.
  final WebElementChrome axisSpacer;

  /// Plot + date row column.
  final WebElementChrome plotColumn;

  /// The plot area.
  final WebElementChrome plot;

  /// One grid line per axis tick, ordered bottom → top.
  final List<WebElementChrome> gridLines;

  /// Reference line `<svg>`, or `null` when no reference value is set.
  final WebElementChrome? reference;

  /// Dashed `<line>` used by the reference line and the legend swatch.
  final WebElementChrome referenceStroke;

  /// One bar per point (empty for the line variant).
  final List<WebElementChrome> bars;

  /// Series `<svg>` (line variant).
  final WebElementChrome line;

  /// Series `<polyline>` (line variant).
  final WebElementChrome lineStroke;

  /// Last-point marker (line variant).
  final WebElementChrome marker;

  /// Row of per-point hit slots.
  final WebElementChrome hitRow;

  /// Per-point `Tooltip` wrapper.
  final WebElementChrome hitSlot;

  /// Per-point hit target inside the tooltip.
  final WebElementChrome hitTarget;

  /// Date label row.
  final WebElementChrome dateRow;

  /// One date label cell per shown date — start, centre, end.
  final List<WebElementChrome> dateLabels;

  /// Legend row.
  final WebElementChrome legend;

  /// Legend swatch `<svg>`.
  final WebElementChrome legendSwatch;

  /// Legend text.
  final WebElementChrome legendLabel;

  /// Chrome forwarded raw to every period `Chip`.
  final CoreChipStyle periodChipStyle;

  /// Text and polyline data the chrome above renders.
  final ResolvedTrendChartSeries series;
}

/// Text content and polyline data for one `TrendChart` render — not
/// chrome, so it travels separately from the element chromes.
class ResolvedTrendChartSeries {
  /// Creates a [ResolvedTrendChartSeries].
  const ResolvedTrendChartSeries({
    required this.tickLabels,
    required this.dateLabels,
    required this.pointLabels,
    required this.linePoints,
  });

  /// Value-axis labels, ordered top → bottom.
  final List<String> tickLabels;

  /// Date-axis labels — first, middle and last point.
  final List<String> dateLabels;

  /// Per-point readout (`'<date>, <value>'`), the tooltip message and the
  /// accessible name of each slot.
  final List<String> pointLabels;

  /// `points` attribute of the series polyline, in a `0 0 100 100`
  /// viewBox.
  final String linePoints;
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
  final trendChartTheme = context.theme.coreComponentTheme?.trendChart;

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
  final count = points.length;

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final lineWidth = merged.lineWidth ?? CoreTrendChartStyle.defaultLineWidth;
  final gridLineWidth =
      merged.gridLineWidth ?? CoreTrendChartStyle.defaultGridLineWidth;
  final referenceLineWidth =
      merged.referenceLineWidth ??
      CoreTrendChartStyle.defaultReferenceLineWidth;
  final referenceDashLength =
      merged.referenceDashLength ??
      CoreTrendChartStyle.defaultReferenceDashLength;
  final referenceDashSpacing =
      merged.referenceDashSpacing ??
      CoreTrendChartStyle.defaultReferenceDashSpacing;
  final markerSize = merged.markerSize ?? CoreTrendChartStyle.defaultMarkerSize;
  final markerBorderRadius =
      merged.markerBorderRadius ??
      CoreTrendChartStyle.defaultMarkerBorderRadius;
  final barSpacing = merged.barSpacing ?? CoreTrendChartStyle.defaultBarSpacing;
  final barBorderRadius =
      merged.barBorderRadius ?? CoreTrendChartStyle.defaultBarBorderRadius;
  final plotHeight = merged.plotHeight ?? CoreTrendChartStyle.defaultPlotHeight;
  final sectionSpacing =
      merged.sectionSpacing ?? CoreTrendChartStyle.defaultSectionSpacing;
  final axisLabelSpacing =
      merged.axisLabelSpacing ?? CoreTrendChartStyle.defaultAxisLabelSpacing;
  final legendSpacing =
      merged.legendSpacing ?? CoreTrendChartStyle.defaultLegendSpacing;
  final legendSwatchWidth =
      merged.legendSwatchWidth ?? CoreTrendChartStyle.defaultLegendSwatchWidth;
  final periodSpacing =
      merged.periodSpacing ?? CoreTrendChartStyle.defaultPeriodSpacing;

  // ─── Stage 2 EMIT (theme-free) ────────────────────────
  final seriesBg = emitColor(
    merged.seriesColor,
    CoreTrendChartStyle.defaultSeriesColor,
    .background,
  );
  final seriesText = emitColor(
    merged.seriesColor,
    CoreTrendChartStyle.defaultSeriesColor,
    .text,
  );
  final gridBg = emitColor(
    merged.gridColor,
    CoreTrendChartStyle.defaultGridColor,
    .background,
  );
  final referenceText = emitColor(
    merged.referenceColor,
    CoreTrendChartStyle.defaultReferenceColor,
    .text,
  );
  final axisLabelType = emitTypography(
    merged.axisLabelStyle,
    CoreTrendChartStyle.defaultAxisLabelStyle,
  );
  final legendLabelType = emitTypography(
    merged.legendLabelStyle,
    CoreTrendChartStyle.defaultLegendLabelStyle,
  );
  final periodChipStyle = CoreTrendChartStyle.defaultPeriodChipStyle.merge(
    merged.periodChipStyle,
  );

  String rem(double px) => '${px / kRemDivisor}rem';
  String percent(double fraction) =>
      '${(fraction * kPercentScale).toStringAsFixed(3)}%';
  String join(List<String> classes) =>
      classes.where((c) => c.isNotEmpty).join(' ');

  // ─── Per-point geometry ───────────────────────────────
  final barChromes = <WebElementChrome>[];
  if (variant == CoreTrendChartVariant.bar) {
    final baseline = geometry.baselineFraction;
    // Bar width = one slot minus the spacing; `calc` keeps the slot a
    // percentage and the spacing a length, as the painter does. Pinned:
    // the spacing draws the bar's width, which the Flutter twin leaves
    // out of the density.
    final width =
        'calc(${percent(1 / count)} - ${pinnedLengthCss(barSpacing)})';
    for (var i = 0; i < count; i++) {
      final f = geometry.pointFractions[i];
      final up = f >= baseline;
      final top = 1 - (up ? f : baseline);
      final height = (f - baseline).abs();
      final center = CoreTrendChartGeometry.slotCenter(i, count);
      final far = radiusCss(
        up ? barBorderRadius.topLeft : barBorderRadius.bottomLeft,
      );
      final farEnd = radiusCss(
        up ? barBorderRadius.topRight : barBorderRadius.bottomRight,
      );
      barChromes.add(
        WebElementChrome(
          className: join([WebLayout.absolute, seriesBg.className]),
          inlineStyles: Styles(
            raw: {
              ...?seriesBg.inline,
              'inset-inline-start': 'calc(${percent(center)} - $width / 2)',
              'width': width,
              'top': percent(top),
              'height': percent(height),
              if (up) ...{
                'border-top-left-radius': far,
                'border-top-right-radius': farEnd,
              } else ...{
                'border-bottom-left-radius': far,
                'border-bottom-right-radius': farEnd,
              },
            },
          ),
        ),
      );
    }
  }

  // A `0 0 100 100` viewBox: a fraction maps to user units × 100.
  String coord(double fraction) =>
      (fraction * kPercentScale).toStringAsFixed(3);
  final linePoints = [
    for (var i = 0; i < count; i++)
      [
        coord(CoreTrendChartGeometry.slotCenter(i, count)),
        coord(1 - geometry.pointFractions[i]),
      ].join(','),
  ].join(' ');
  final lastFraction = count == 0 ? 0.0 : geometry.pointFractions[count - 1];
  final lastCenter = count == 0
      ? 0.0
      : CoreTrendChartGeometry.slotCenter(count - 1, count);

  final dateIndices = CoreTrendChartGeometry.dateLabelIndices(count);
  final dateAligns = switch (dateIndices.length) {
    1 => const ['text-center'],
    2 => const ['text-start', 'text-end'],
    _ => const ['text-start', 'text-center', 'text-end'],
  };
  final referenceFraction = geometry.referenceFraction;

  return ResolvedTrendChart(
    root: WebElementChrome(
      className: join([WebLayout.flex, WebLayout.flexCol, WebLayout.wFull]),
      inlineStyles: Styles(raw: {'gap': spaceCss(sectionSpacing)}),
    ),
    periodRow: WebElementChrome(
      className: join([WebLayout.flex, WebLayout.flexWrap]),
      inlineStyles: Styles(raw: {'gap': spaceCss(periodSpacing)}),
    ),
    plotRow: WebElementChrome(
      className: join([WebLayout.flex, WebLayout.itemsStretch]),
      inlineStyles: Styles(raw: {'gap': spaceCss(axisLabelSpacing)}),
    ),
    tickColumn: WebElementChrome(
      className: join([
        WebLayout.flex,
        WebLayout.flexCol,
        WebLayout.itemsEnd,
        WebLayout.shrinkZero,
      ]),
      inlineStyles: Styles(raw: {'gap': spaceCss(axisLabelSpacing)}),
    ),
    tickLabels: WebElementChrome(
      className: join([
        WebLayout.flex1,
        WebLayout.flex,
        WebLayout.flexCol,
        WebLayout.justifyBetween,
        WebLayout.itemsEnd,
      ]),
    ),
    axisLabel: WebElementChrome(
      className: join([axisLabelType.className, 'whitespace-nowrap']),
      inlineStyles: axisLabelType.inline == null
          ? null
          : Styles(raw: axisLabelType.inline),
    ),
    axisSpacer: WebElementChrome(
      className: join([
        axisLabelType.className,
        'whitespace-nowrap',
        WebLayout.invisible,
      ]),
      inlineStyles: axisLabelType.inline == null
          ? null
          : Styles(raw: axisLabelType.inline),
    ),
    plotColumn: WebElementChrome(
      className: join([
        WebLayout.flex1,
        WebLayout.minWZero,
        WebLayout.flex,
        WebLayout.flexCol,
      ]),
      inlineStyles: Styles(raw: {'gap': spaceCss(axisLabelSpacing)}),
    ),
    plot: WebElementChrome(
      className: join([WebLayout.relative, WebLayout.flex1]),
      inlineStyles: Styles(raw: {'min-height': rem(plotHeight)}),
    ),
    gridLines: [
      for (var i = 0; i < geometry.ticks.length; i++)
        WebElementChrome(
          className: join([
            WebLayout.absolute,
            WebLayout.insetXZero,
            gridBg.className,
          ]),
          inlineStyles: Styles(
            raw: {
              ...?gridBg.inline,
              'top': percent(1 - geometry.tickFraction(i)),
              'height': pictureStrokeCss(gridLineWidth),
              'transform': 'translateY(-50%)',
            },
          ),
        ),
    ],
    reference: referenceFraction == null
        ? null
        : WebElementChrome(
            className: join([
              WebLayout.absolute,
              WebLayout.insetXZero,
              WebLayout.wFull,
              WebLayout.overflowVisible,
              referenceText.className,
            ]),
            inlineStyles: Styles(
              raw: {
                ...?referenceText.inline,
                'top': percent(1 - referenceFraction),
                'height': pictureStrokeCss(referenceLineWidth),
                'transform': 'translateY(-50%)',
              },
            ),
          ),
    referenceStroke: WebElementChrome(
      className: '',
      inlineStyles: Styles(
        raw: {
          'stroke-width': pictureStrokeCss(referenceLineWidth),
          'stroke-dasharray':
              '${svgUserUnitCss(referenceDashLength)} '
              '${svgUserUnitCss(referenceDashSpacing)}',
        },
      ),
    ),
    bars: barChromes,
    line: WebElementChrome(
      className: join([
        WebLayout.absolute,
        WebLayout.insetZero,
        WebLayout.wFull,
        WebLayout.hFull,
        WebLayout.overflowVisible,
        'rtl:-scale-x-100',
        seriesText.className,
      ]),
      inlineStyles: seriesText.inline == null
          ? null
          : Styles(raw: seriesText.inline),
    ),
    lineStroke: WebElementChrome(
      className: '',
      inlineStyles: Styles(
        raw: {'stroke-width': pictureStrokeCss(lineWidth)},
      ),
    ),
    marker: WebElementChrome(
      className: join([WebLayout.absolute, seriesBg.className]),
      inlineStyles: Styles(
        raw: {
          ...?seriesBg.inline,
          'inset-inline-start': percent(lastCenter),
          'top': percent(1 - lastFraction),
          'width': rem(markerSize),
          'height': rem(markerSize),
          // Centred on half the marker's own size — geometry, not spacing.
          'margin-inline-start': pinnedLengthCss(-markerSize / 2),
          'margin-top': pinnedLengthCss(-markerSize / 2),
          'border-radius': markerBorderRadius.toValue(),
        },
      ),
    ),
    hitRow: WebElementChrome(
      className: join([
        WebLayout.absolute,
        WebLayout.insetZero,
        WebLayout.flex,
      ]),
    ),
    hitSlot: WebElementChrome(
      className: join([WebLayout.flex1, WebLayout.grid]),
    ),
    hitTarget: WebElementChrome(
      className: join([WebLayout.wFull, WebLayout.hFull]),
    ),
    dateRow: WebElementChrome(
      className: WebLayout.flex,
      inlineStyles: Styles(raw: {'gap': spaceCss(axisLabelSpacing)}),
    ),
    dateLabels: [
      for (final align in dateAligns)
        WebElementChrome(
          className: join([
            WebLayout.flex1,
            WebLayout.minWZero,
            'truncate',
            align,
            axisLabelType.className,
          ]),
          inlineStyles: axisLabelType.inline == null
              ? null
              : Styles(raw: axisLabelType.inline),
        ),
    ],
    legend: WebElementChrome(
      className: join([WebLayout.flex, WebLayout.itemsCenter]),
      inlineStyles: Styles(raw: {'gap': spaceCss(legendSpacing)}),
    ),
    legendSwatch: WebElementChrome(
      className: join([
        WebLayout.shrinkZero,
        WebLayout.overflowVisible,
        referenceText.className,
      ]),
      inlineStyles: Styles(
        raw: {
          ...?referenceText.inline,
          'width': rem(legendSwatchWidth),
          'height': pictureStrokeCss(referenceLineWidth),
        },
      ),
    ),
    legendLabel: WebElementChrome(
      className: join([WebLayout.minWZero, legendLabelType.className]),
      inlineStyles: legendLabelType.inline == null
          ? null
          : Styles(raw: legendLabelType.inline),
    ),
    periodChipStyle: periodChipStyle,
    series: ResolvedTrendChartSeries(
      tickLabels: [for (final tick in geometry.ticks.reversed) format(tick)],
      dateLabels: [
        for (final i in dateIndices)
          points[i].label ?? CoreTrendChartGeometry.formatDate(points[i].date),
      ],
      pointLabels: [
        for (final p in points)
          [
            p.label ?? CoreTrendChartGeometry.formatDate(p.date),
            p.valueLabel ?? format(p.value),
          ].join(', '),
      ],
      linePoints: linePoints,
    ),
  );
}
