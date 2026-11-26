/// Per-instance style for `CategoryBreakdown`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `CategoryBreakdown` should render.
///
/// Every field is nullable; the resolver fills a null field from the
/// matching `default*` constant below. Both platforms read these
/// constants, so a default changed here moves Flutter and Web together.
///
/// ```text
/// CoreCategoryBreakdownStyle.default*
///   → CoreCategoryBreakdownTheme.style                     // 프로젝트 공통
///   → CoreCategoryBreakdownTheme.variantStyles[variant]    // variant 별
///   → widget.categoryBreakdownStyle                        // 인스턴스별
/// ```
@immutable
class CoreCategoryBreakdownStyle
    implements CoreStyle<CoreCategoryBreakdownStyle> {
  /// Creates a [CoreCategoryBreakdownStyle].
  const CoreCategoryBreakdownStyle({
    this.seriesColors,
    this.trackColor,
    this.barHeight,
    this.barBorderRadius,
    this.rowSpacing,
    this.rowContentSpacing,
    this.labelSpacing,
    this.labelStyle,
    this.valueStyle,
    this.percentStyle,
    this.donutSize,
    this.donutThickness,
    this.donutSegmentSpacing,
    this.legendSpacing,
    this.swatchSize,
    this.swatchBorderRadius,
  });

  /// Default for [seriesColors].
  ///
  /// `tertiary` is deliberately absent: a brand may map its tertiary slots
  /// onto the same steps as `primary` (CoUI does), and two adjacent
  /// categories drawn in one ink read as a single category. Resolvers cannot
  /// skip the duplicate for us — Web emits token names and never sees the
  /// resolved colour — so the default list has to be distinct by name.
  static const List<CoreColor> defaultSeriesColors = [
    CoreColor.token(CoreColors.primary),
    CoreColor.token(CoreColors.secondary),
    CoreColor.token(CoreColors.success),
    CoreColor.token(CoreColors.warning),
    CoreColor.token(CoreColors.info),
    CoreColor.token(CoreColors.error),
  ];

  /// Default for [trackColor].
  static const CoreColor defaultTrackColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default for [barHeight].
  static const double defaultBarHeight = CoreSpace.space8;

  /// Default for [barBorderRadius].
  static const CoreBorderRadius defaultBarBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default for [rowSpacing].
  static const double defaultRowSpacing = CoreSpace.space12;

  /// Default for [rowContentSpacing].
  static const double defaultRowContentSpacing = CoreSpace.space6;

  /// Default for [labelSpacing].
  static const double defaultLabelSpacing = CoreSpace.space8;

  /// Default for [labelStyle].
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default for [valueStyle].
  static const CoreTextStyle defaultValueStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default for [percentStyle].
  static const CoreTextStyle defaultPercentStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default for [donutSize].
  static const double defaultDonutSize = CoreSpace.space160;

  /// Default for [donutThickness].
  static const double defaultDonutThickness = CoreSpace.space24;

  /// Default for [donutSegmentSpacing].
  static const double defaultDonutSegmentSpacing = CoreSpace.space2;

  /// Default for [legendSpacing].
  static const double defaultLegendSpacing = CoreSpace.space16;

  /// Default for [swatchSize].
  static const double defaultSwatchSize = CoreSize.size10;

  /// Default for [swatchBorderRadius].
  static const CoreBorderRadius defaultSwatchBorderRadius =
      CoreBorderRadius.all(CoreRadiusRole.part);

  /// Colours assigned to categories in order, cycling when there are more
  /// categories than colours. An item's own `color` wins.
  final List<CoreColor>? seriesColors;

  /// Colour of the empty part of each bar.
  final CoreColor? trackColor;

  /// Height of each bar (logical px).
  final double? barHeight;

  /// Corner radius of the bar track and its fill.
  final CoreBorderRadius? barBorderRadius;

  /// Vertical space between category rows (logical px).
  final double? rowSpacing;

  /// Vertical space between a row's text line and its bar (logical px).
  final double? rowContentSpacing;

  /// Horizontal space between a row's swatch, label, value and share (logical
  /// px).
  final double? labelSpacing;

  /// Typography of each category label.
  final CoreTextStyle? labelStyle;

  /// Typography of each category value.
  final CoreTextStyle? valueStyle;

  /// Typography of each category share.
  final CoreTextStyle? percentStyle;

  /// Diameter of the donut (logical px).
  final double? donutSize;

  /// Ring thickness of the donut (logical px).
  final double? donutThickness;

  /// Empty space between adjacent donut arcs, measured along the ring (logical
  /// px).
  final double? donutSegmentSpacing;

  /// Space between the donut and its legend — beside it, or below it once the
  /// legend wraps (logical px).
  final double? legendSpacing;

  /// Side of the colour swatch in each donut legend row (logical px).
  final double? swatchSize;

  /// Corner radius of the legend swatch.
  final CoreBorderRadius? swatchBorderRadius;

  @override
  CoreCategoryBreakdownStyle merge(CoreCategoryBreakdownStyle? other) {
    if (other == null) return this;
    return CoreCategoryBreakdownStyle(
      seriesColors: other.seriesColors ?? seriesColors,
      trackColor: other.trackColor ?? trackColor,
      barHeight: other.barHeight ?? barHeight,
      barBorderRadius: other.barBorderRadius ?? barBorderRadius,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      rowContentSpacing: other.rowContentSpacing ?? rowContentSpacing,
      labelSpacing: other.labelSpacing ?? labelSpacing,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
      valueStyle: valueStyle?.merge(other.valueStyle) ?? other.valueStyle,
      percentStyle:
          percentStyle?.merge(other.percentStyle) ?? other.percentStyle,
      donutSize: other.donutSize ?? donutSize,
      donutThickness: other.donutThickness ?? donutThickness,
      donutSegmentSpacing: other.donutSegmentSpacing ?? donutSegmentSpacing,
      legendSpacing: other.legendSpacing ?? legendSpacing,
      swatchSize: other.swatchSize ?? swatchSize,
      swatchBorderRadius: other.swatchBorderRadius ?? swatchBorderRadius,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreCategoryBreakdownStyle copyWith({
    List<CoreColor>? seriesColors,
    CoreColor? trackColor,
    double? barHeight,
    CoreBorderRadius? barBorderRadius,
    double? rowSpacing,
    double? rowContentSpacing,
    double? labelSpacing,
    CoreTextStyle? labelStyle,
    CoreTextStyle? valueStyle,
    CoreTextStyle? percentStyle,
    double? donutSize,
    double? donutThickness,
    double? donutSegmentSpacing,
    double? legendSpacing,
    double? swatchSize,
    CoreBorderRadius? swatchBorderRadius,
  }) {
    return CoreCategoryBreakdownStyle(
      seriesColors: seriesColors ?? this.seriesColors,
      trackColor: trackColor ?? this.trackColor,
      barHeight: barHeight ?? this.barHeight,
      barBorderRadius: barBorderRadius ?? this.barBorderRadius,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      rowContentSpacing: rowContentSpacing ?? this.rowContentSpacing,
      labelSpacing: labelSpacing ?? this.labelSpacing,
      labelStyle: labelStyle ?? this.labelStyle,
      valueStyle: valueStyle ?? this.valueStyle,
      percentStyle: percentStyle ?? this.percentStyle,
      donutSize: donutSize ?? this.donutSize,
      donutThickness: donutThickness ?? this.donutThickness,
      donutSegmentSpacing: donutSegmentSpacing ?? this.donutSegmentSpacing,
      legendSpacing: legendSpacing ?? this.legendSpacing,
      swatchSize: swatchSize ?? this.swatchSize,
      swatchBorderRadius: swatchBorderRadius ?? this.swatchBorderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCategoryBreakdownStyle &&
          runtimeType == other.runtimeType &&
          _listEquals(seriesColors, other.seriesColors) &&
          trackColor == other.trackColor &&
          barHeight == other.barHeight &&
          barBorderRadius == other.barBorderRadius &&
          rowSpacing == other.rowSpacing &&
          rowContentSpacing == other.rowContentSpacing &&
          labelSpacing == other.labelSpacing &&
          labelStyle == other.labelStyle &&
          valueStyle == other.valueStyle &&
          percentStyle == other.percentStyle &&
          donutSize == other.donutSize &&
          donutThickness == other.donutThickness &&
          donutSegmentSpacing == other.donutSegmentSpacing &&
          legendSpacing == other.legendSpacing &&
          swatchSize == other.swatchSize &&
          swatchBorderRadius == other.swatchBorderRadius;

  @override
  int get hashCode => Object.hashAll([
    if (seriesColors == null) null else Object.hashAll(seriesColors!),
    trackColor,
    barHeight,
    barBorderRadius,
    rowSpacing,
    rowContentSpacing,
    labelSpacing,
    labelStyle,
    valueStyle,
    percentStyle,
    donutSize,
    donutThickness,
    donutSegmentSpacing,
    legendSpacing,
    swatchSize,
    swatchBorderRadius,
  ]);
}

bool _listEquals(List<CoreColor>? a, List<CoreColor>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
