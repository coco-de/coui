import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `CategoryBreakdown`.
///
/// Widget tree (`category_breakdown.dart` is render-only):
///
/// ```text
/// Semantics (container, label: semanticLabel)
///   ├─ bar variant
///   │    └─ Column (spacing: rowSpacing)
///   │         └─ row × items            // Semantics(label: rowLabels[i])
///   │              ├─ Row (spacing: labelSpacing)
///   │              │    ├─ label · valueLabels[i] · percentLabel(i)
///   │              └─ track (barHeight, trackColor, barBorderRadius)
///   │                   └─ fill (fractions[i], colors[i])
///   └─ donut variant — Row, or Column once narrower than
///        donutSize × 2 + legendSpacing
///        ├─ donut (donutSize) → CustomPaint arcs + center slot
///        └─ legend Column (spacing: rowSpacing)
///             └─ Row: swatch (swatchSize, colors[i]) · label · value · %
/// ```
class ResolvedCategoryBreakdown {
  /// Creates a [ResolvedCategoryBreakdown].
  const ResolvedCategoryBreakdown({
    required this.geometry,
    required this.colors,
    required this.valueLabels,
    required this.rowLabels,
    required this.trackColor,
    required this.barHeight,
    required this.barBorderRadius,
    required this.rowSpacing,
    required this.rowContentSpacing,
    required this.labelSpacing,
    required this.labelTextStyle,
    required this.valueTextStyle,
    required this.percentTextStyle,
    required this.donutSize,
    required this.donutThickness,
    required this.legendSpacing,
    required this.swatchSize,
    required this.swatchBorderRadius,
  });

  /// Shares, printed percentages and donut arcs.
  final CoreCategoryBreakdownGeometry geometry;

  /// Per-category colour, indexed 1:1 with the items.
  final List<Color> colors;

  /// Per-category display value, indexed 1:1 with the items.
  final List<String> valueLabels;

  /// Per-category accessible sentence (`'<label>, <value>, <share>'`).
  final List<String> rowLabels;

  /// Bar track colour.
  final Color trackColor;

  /// Bar height (logical px).
  final double barHeight;

  /// Bar corner radius.
  final BorderRadius barBorderRadius;

  /// Space between rows (logical px).
  final double rowSpacing;

  /// Space between a row's text and its bar (logical px).
  final double rowContentSpacing;

  /// Space between a row's swatch, label, value and share (logical px).
  final double labelSpacing;

  /// Label typography.
  final TextStyle labelTextStyle;

  /// Value typography.
  final TextStyle valueTextStyle;

  /// Share typography.
  final TextStyle percentTextStyle;

  /// Donut diameter (logical px).
  final double donutSize;

  /// Donut ring thickness (logical px).
  final double donutThickness;

  /// Space between the donut and its legend (logical px).
  final double legendSpacing;

  /// Legend swatch side (logical px).
  final double swatchSize;

  /// Legend swatch corner radius.
  final BorderRadius swatchBorderRadius;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCategoryBreakdown] for the given [context].
///
/// ```text
/// CoreCategoryBreakdownStyle.default*
///   → theme.coreComponentTheme.categoryBreakdown.style
///   → theme.coreComponentTheme.categoryBreakdown.variantStyles[variant]
///   → widget.categoryBreakdownStyle
/// ```
ResolvedCategoryBreakdown resolveCategoryBreakdown(
  BuildContext context, {
  required CoreCategoryBreakdownVariant variant,
  required List<CoreCategoryBreakdownItem> items,
  CoreCategoryBreakdownStyle? categoryBreakdownStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final breakdownTheme = theme.coreComponentTheme?.categoryBreakdown;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCategoryBreakdownStyle(), [
    breakdownTheme?.style,
    breakdownTheme?.variantStyles?[variant],
    categoryBreakdownStyle,
  ]);

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final seriesColors =
      merged.seriesColors ?? CoreCategoryBreakdownStyle.defaultSeriesColors;
  final donutSizeRaw =
      merged.donutSize ?? CoreCategoryBreakdownStyle.defaultDonutSize;
  final donutThicknessRaw =
      merged.donutThickness ?? CoreCategoryBreakdownStyle.defaultDonutThickness;

  // ─── Data layout (shared Core geometry) ──────────────
  final geometry = CoreCategoryBreakdownGeometry.compute(
    [for (final item in items) item.value],
    arcGapTurns: CoreCategoryBreakdownGeometry.arcGapTurnsFor(
      gap:
          merged.donutSegmentSpacing ??
          CoreCategoryBreakdownStyle.defaultDonutSegmentSpacing,
      diameter: donutSizeRaw,
      thickness: donutThicknessRaw,
    ),
  );
  final valueLabels = [
    for (final item in items)
      item.valueLabel ?? CoreCategoryBreakdownGeometry.formatValue(item.value),
  ];
  final rowLabels = [
    for (var i = 0; i < items.length; i++)
      [items[i].label, valueLabels[i], geometry.percentLabel(i)].join(', '),
  ];

  // ─── Stage 2 EMIT — colour ────────────────────────────
  final colors = [
    for (var i = 0; i < items.length; i++)
      scheme
          .resolve(
            items[i].color ??
                (seriesColors.isEmpty
                    ? CoreCategoryBreakdownStyle.defaultSeriesColors.first
                    : seriesColors[i % seriesColors.length]),
          )
          .toValue(),
  ];
  final trackColor = scheme
      .resolve(
        merged.trackColor ?? CoreCategoryBreakdownStyle.defaultTrackColor,
      )
      .toValue();

  // ─── Stage 2 EMIT — dimensions ────────────────────────
  final barHeight =
      (merged.barHeight ?? CoreCategoryBreakdownStyle.defaultBarHeight) *
      scaling;
  final barBorderRadius =
      (merged.barBorderRadius ??
              CoreCategoryBreakdownStyle.defaultBarBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final rowSpacing =
      theme.geometry.space(
        merged.rowSpacing ?? CoreCategoryBreakdownStyle.defaultRowSpacing,
      ) *
      scaling;
  final rowContentSpacing =
      theme.geometry.space(
        merged.rowContentSpacing ??
            CoreCategoryBreakdownStyle.defaultRowContentSpacing,
      ) *
      scaling;
  final labelSpacing =
      theme.geometry.space(
        merged.labelSpacing ?? CoreCategoryBreakdownStyle.defaultLabelSpacing,
      ) *
      scaling;
  final donutSize = donutSizeRaw * scaling;
  final donutThickness = donutThicknessRaw * scaling;
  final legendSpacing =
      theme.geometry.space(
        merged.legendSpacing ?? CoreCategoryBreakdownStyle.defaultLegendSpacing,
      ) *
      scaling;
  final swatchSize =
      (merged.swatchSize ?? CoreCategoryBreakdownStyle.defaultSwatchSize) *
      scaling;
  final swatchBorderRadius =
      (merged.swatchBorderRadius ??
              CoreCategoryBreakdownStyle.defaultSwatchBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;

  // ─── Stage 2 EMIT — typography ────────────────────────
  final labelTextStyle = CoreCategoryBreakdownStyle.defaultLabelStyle
      .merge(merged.labelStyle)
      .toValue(theme: theme);
  final valueTextStyle = CoreCategoryBreakdownStyle.defaultValueStyle
      .merge(merged.valueStyle)
      .toValue(theme: theme);
  final percentTextStyle = CoreCategoryBreakdownStyle.defaultPercentStyle
      .merge(merged.percentStyle)
      .toValue(theme: theme);

  return ResolvedCategoryBreakdown(
    geometry: geometry,
    colors: colors,
    valueLabels: valueLabels,
    rowLabels: rowLabels,
    trackColor: trackColor,
    barHeight: barHeight,
    barBorderRadius: barBorderRadius,
    rowSpacing: rowSpacing,
    rowContentSpacing: rowContentSpacing,
    labelSpacing: labelSpacing,
    labelTextStyle: labelTextStyle,
    valueTextStyle: valueTextStyle,
    percentTextStyle: percentTextStyle,
    donutSize: donutSize,
    donutThickness: donutThickness,
    legendSpacing: legendSpacing,
    swatchSize: swatchSize,
    swatchBorderRadius: swatchBorderRadius,
  );
}
