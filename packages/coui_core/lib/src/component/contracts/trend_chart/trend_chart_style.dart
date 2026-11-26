/// Per-instance style for `TrendChart`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/chip/chip_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/dashed_border.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `TrendChart` should render.
///
/// Every field is nullable; the resolver fills a null field from the
/// matching `default*` constant below. Both platforms read these
/// constants, so a default changed here moves Flutter and Web together.
///
/// ```text
/// CoreTrendChartStyle.default*
///   → CoreTrendChartTheme.style                     // 프로젝트 공통
///   → CoreTrendChartTheme.variantStyles[variant]    // variant 별
///   → widget.trendChartStyle                        // 인스턴스별
/// ```
@immutable
class CoreTrendChartStyle implements CoreStyle<CoreTrendChartStyle> {
  /// Creates a [CoreTrendChartStyle].
  const CoreTrendChartStyle({
    this.seriesColor,
    this.gridColor,
    this.referenceColor,
    this.lineWidth,
    this.gridLineWidth,
    this.referenceLineWidth,
    this.referenceDashLength,
    this.referenceDashSpacing,
    this.markerSize,
    this.markerBorderRadius,
    this.barSpacing,
    this.barBorderRadius,
    this.plotHeight,
    this.sectionSpacing,
    this.axisLabelSpacing,
    this.axisTickCount,
    this.axisLabelStyle,
    this.legendLabelStyle,
    this.legendSpacing,
    this.legendSwatchWidth,
    this.periodSpacing,
    this.periodChipStyle,
  });

  /// Default for [seriesColor].
  static const CoreColor defaultSeriesColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default for [gridColor].
  static const CoreColor defaultGridColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default for [referenceColor].
  static const CoreColor defaultReferenceColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default for [lineWidth].
  static const double defaultLineWidth = CoreStrokeWidth.stroke2;

  /// Default for [gridLineWidth].
  static const double defaultGridLineWidth = CoreStrokeWidth.stroke1;

  /// Default for [referenceLineWidth].
  static const double defaultReferenceLineWidth = CoreStrokeWidth.stroke1;

  /// Default for [referenceDashLength].
  static const double defaultReferenceDashLength = CoreDashedBorder.dashLength;

  /// Default for [referenceDashSpacing].
  static const double defaultReferenceDashSpacing = CoreDashedBorder.dashGap;

  /// Default for [markerSize].
  static const double defaultMarkerSize = CoreSize.size8;

  /// Default for [markerBorderRadius] — fully round, a dot.
  static const CoreBorderRadius defaultMarkerBorderRadius =
      CoreBorderRadius.all(
        CoreRadius.radius9999,
      );

  /// Default for [barSpacing].
  static const double defaultBarSpacing = CoreSpace.space4;

  /// Default for [barBorderRadius].
  static const CoreBorderRadius defaultBarBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.part,
  );

  /// Default for [plotHeight].
  static const double defaultPlotHeight = CoreSpace.space160;

  /// Default for [sectionSpacing].
  static const double defaultSectionSpacing = CoreSpace.space12;

  /// Default for [axisLabelSpacing].
  static const double defaultAxisLabelSpacing = CoreSpace.space8;

  /// Default for [axisTickCount].
  static const int defaultAxisTickCount = 4;

  /// Default for [axisLabelStyle].
  static const CoreTextStyle defaultAxisLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default for [legendLabelStyle].
  static const CoreTextStyle defaultLegendLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default for [legendSpacing].
  static const double defaultLegendSpacing = CoreSpace.space8;

  /// Default for [legendSwatchWidth].
  static const double defaultLegendSwatchWidth = CoreSpace.space16;

  /// Default for [periodSpacing].
  static const double defaultPeriodSpacing = CoreSpace.space8;

  /// Default for [periodChipStyle].
  static const CoreChipStyle defaultPeriodChipStyle = CoreChipStyle();

  /// Colour of the line, its end marker and the bars.
  final CoreColor? seriesColor;

  /// Colour of the horizontal grid lines at each axis tick.
  final CoreColor? gridColor;

  /// Colour of the dashed reference line and its legend swatch.
  final CoreColor? referenceColor;

  /// Stroke width of the series line (logical px).
  final double? lineWidth;

  /// Stroke width of each grid line (logical px).
  final double? gridLineWidth;

  /// Stroke width of the reference line (logical px).
  final double? referenceLineWidth;

  /// Length of one dash of the reference line (logical px).
  final double? referenceDashLength;

  /// Gap between two dashes of the reference line (logical px).
  final double? referenceDashSpacing;

  /// Diameter of the marker on the last point of a line (logical px).
  final double? markerSize;

  /// Corner radius of the last-point marker.
  final CoreBorderRadius? markerBorderRadius;

  /// Horizontal space between two adjacent bars (logical px).
  final double? barSpacing;

  /// Corner radius of a bar's far end — the end away from the zero baseline.
  /// The baseline end stays square.
  final CoreBorderRadius? barBorderRadius;

  /// Minimum height of the plot area (logical px). The plot grows when the axis
  /// labels need more room (large text).
  final double? plotHeight;

  /// Vertical space between the summary, the period chips, the plot and the
  /// legend (logical px). Flows into `Column.spacing` / CSS `gap`.
  final double? sectionSpacing;

  /// Space between the value axis labels and the plot, and between the plot and
  /// the date labels (logical px).
  final double? axisLabelSpacing;

  /// Target number of value-axis intervals. The axis rounds to a nice step, so
  /// the drawn count can differ by one.
  final int? axisTickCount;

  /// Typography of the value-axis and date-axis labels.
  final CoreTextStyle? axisLabelStyle;

  /// Typography of the reference-line legend text.
  final CoreTextStyle? legendLabelStyle;

  /// Space between the legend swatch and its text (logical px).
  final double? legendSpacing;

  /// Width of the dashed legend swatch (logical px).
  final double? legendSwatchWidth;

  /// Space between period chips, both along a row and between wrapped rows
  /// (logical px).
  final double? periodSpacing;

  /// Style for the period chips, passed to every period `Chip`.
  final CoreChipStyle? periodChipStyle;

  @override
  CoreTrendChartStyle merge(CoreTrendChartStyle? other) {
    if (other == null) return this;
    return CoreTrendChartStyle(
      seriesColor: other.seriesColor ?? seriesColor,
      gridColor: other.gridColor ?? gridColor,
      referenceColor: other.referenceColor ?? referenceColor,
      lineWidth: other.lineWidth ?? lineWidth,
      gridLineWidth: other.gridLineWidth ?? gridLineWidth,
      referenceLineWidth: other.referenceLineWidth ?? referenceLineWidth,
      referenceDashLength: other.referenceDashLength ?? referenceDashLength,
      referenceDashSpacing: other.referenceDashSpacing ?? referenceDashSpacing,
      markerSize: other.markerSize ?? markerSize,
      markerBorderRadius: other.markerBorderRadius ?? markerBorderRadius,
      barSpacing: other.barSpacing ?? barSpacing,
      barBorderRadius: other.barBorderRadius ?? barBorderRadius,
      plotHeight: other.plotHeight ?? plotHeight,
      sectionSpacing: other.sectionSpacing ?? sectionSpacing,
      axisLabelSpacing: other.axisLabelSpacing ?? axisLabelSpacing,
      axisTickCount: other.axisTickCount ?? axisTickCount,
      axisLabelStyle:
          axisLabelStyle?.merge(other.axisLabelStyle) ?? other.axisLabelStyle,
      legendLabelStyle:
          legendLabelStyle?.merge(other.legendLabelStyle) ??
          other.legendLabelStyle,
      legendSpacing: other.legendSpacing ?? legendSpacing,
      legendSwatchWidth: other.legendSwatchWidth ?? legendSwatchWidth,
      periodSpacing: other.periodSpacing ?? periodSpacing,
      periodChipStyle:
          periodChipStyle?.merge(other.periodChipStyle) ??
          other.periodChipStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreTrendChartStyle copyWith({
    CoreColor? seriesColor,
    CoreColor? gridColor,
    CoreColor? referenceColor,
    double? lineWidth,
    double? gridLineWidth,
    double? referenceLineWidth,
    double? referenceDashLength,
    double? referenceDashSpacing,
    double? markerSize,
    CoreBorderRadius? markerBorderRadius,
    double? barSpacing,
    CoreBorderRadius? barBorderRadius,
    double? plotHeight,
    double? sectionSpacing,
    double? axisLabelSpacing,
    int? axisTickCount,
    CoreTextStyle? axisLabelStyle,
    CoreTextStyle? legendLabelStyle,
    double? legendSpacing,
    double? legendSwatchWidth,
    double? periodSpacing,
    CoreChipStyle? periodChipStyle,
  }) {
    return CoreTrendChartStyle(
      seriesColor: seriesColor ?? this.seriesColor,
      gridColor: gridColor ?? this.gridColor,
      referenceColor: referenceColor ?? this.referenceColor,
      lineWidth: lineWidth ?? this.lineWidth,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      referenceLineWidth: referenceLineWidth ?? this.referenceLineWidth,
      referenceDashLength: referenceDashLength ?? this.referenceDashLength,
      referenceDashSpacing: referenceDashSpacing ?? this.referenceDashSpacing,
      markerSize: markerSize ?? this.markerSize,
      markerBorderRadius: markerBorderRadius ?? this.markerBorderRadius,
      barSpacing: barSpacing ?? this.barSpacing,
      barBorderRadius: barBorderRadius ?? this.barBorderRadius,
      plotHeight: plotHeight ?? this.plotHeight,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      axisLabelSpacing: axisLabelSpacing ?? this.axisLabelSpacing,
      axisTickCount: axisTickCount ?? this.axisTickCount,
      axisLabelStyle: axisLabelStyle ?? this.axisLabelStyle,
      legendLabelStyle: legendLabelStyle ?? this.legendLabelStyle,
      legendSpacing: legendSpacing ?? this.legendSpacing,
      legendSwatchWidth: legendSwatchWidth ?? this.legendSwatchWidth,
      periodSpacing: periodSpacing ?? this.periodSpacing,
      periodChipStyle: periodChipStyle ?? this.periodChipStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTrendChartStyle &&
          runtimeType == other.runtimeType &&
          seriesColor == other.seriesColor &&
          gridColor == other.gridColor &&
          referenceColor == other.referenceColor &&
          lineWidth == other.lineWidth &&
          gridLineWidth == other.gridLineWidth &&
          referenceLineWidth == other.referenceLineWidth &&
          referenceDashLength == other.referenceDashLength &&
          referenceDashSpacing == other.referenceDashSpacing &&
          markerSize == other.markerSize &&
          markerBorderRadius == other.markerBorderRadius &&
          barSpacing == other.barSpacing &&
          barBorderRadius == other.barBorderRadius &&
          plotHeight == other.plotHeight &&
          sectionSpacing == other.sectionSpacing &&
          axisLabelSpacing == other.axisLabelSpacing &&
          axisTickCount == other.axisTickCount &&
          axisLabelStyle == other.axisLabelStyle &&
          legendLabelStyle == other.legendLabelStyle &&
          legendSpacing == other.legendSpacing &&
          legendSwatchWidth == other.legendSwatchWidth &&
          periodSpacing == other.periodSpacing &&
          periodChipStyle == other.periodChipStyle;

  @override
  int get hashCode => Object.hashAll([
    seriesColor,
    gridColor,
    referenceColor,
    lineWidth,
    gridLineWidth,
    referenceLineWidth,
    referenceDashLength,
    referenceDashSpacing,
    markerSize,
    markerBorderRadius,
    barSpacing,
    barBorderRadius,
    plotHeight,
    sectionSpacing,
    axisLabelSpacing,
    axisTickCount,
    axisLabelStyle,
    legendLabelStyle,
    legendSpacing,
    legendSwatchWidth,
    periodSpacing,
    periodChipStyle,
  ]);
}
