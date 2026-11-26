/// Per-instance style for `Steps`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/step_item/step_item_style.dart';
import 'package:coui_core/src/component/contracts/steps/steps_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Steps` should render.
///
/// `CoreStepsStyle` carries chrome flat fields (indicator size /
/// connector thickness / indicator colour / etc.) plus nested
/// [CoreGapStyle] slots for the two named 1-off gaps inside the step
/// layout — used by both the horizontal and vertical numbered layouts —
/// and the nested [stepItemStyle] slot the list layout forwards to every
/// `StepItem` row it stacks.
///
/// ```text
/// design system default
///   → CoreStepsTheme.style                          // 프로젝트 공통
///   → CoreStepsTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.stepsStyle                             // 인스턴스별
/// ```
@immutable
class CoreStepsStyle implements CoreStyle<CoreStepsStyle> {
  /// Creates a [CoreStepsStyle].
  const CoreStepsStyle({
    this.indicatorSize,
    this.indicatorBorderRadius,
    this.indicatorContentGapStyle,
    this.indicatorConnectorGapStyle,
    this.indicatorConnectorGapHorizontalStyle,
    this.stepPadding,
    this.stepPaddingHorizontal,
    this.connectorThickness,
    this.iconSizeRatio,
    this.connectorColor,
    this.activeConnectorColor,
    this.indicatorColor,
    this.indicatorBorderColor,
    this.indicatorBorderWidth,
    this.activeIndicatorColor,
    this.failedIndicatorColor,
    this.activeLabelColor,
    this.inactiveLabelColor,
    this.failedLabelColor,
    this.titleColor,
    this.inactiveTitleColor,
    this.descriptionColor,
    this.labelStyle,
    this.titleStyle,
    this.currentTitleStyle,
    this.descriptionStyle,
    this.stepItemStyle,
  });

  // ── Defaults (design-system, variant-independent) ──

  /// Default indicator circle diameter (logical px / CSS px, pre-scaling).
  static const double defaultIndicatorSize = CoreSpace.space28;

  /// Default indicator (circle) corner radius — fully round. Not an
  /// overridable field (the indicator has no radius slot; both
  /// platforms shape it as `.circle`/`50%`), so this is a named
  /// single-source the resolver references instead of the raw
  /// `CoreRadius.radius9999` token (verify_contracts.sh [11/13]).
  static const CoreBorderRadius defaultIndicatorBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default nested [CoreGapStyle] slot for the gap between the indicator
  /// column and the step content. 1-off gap between two named siblings —
  /// forwarded to `Gap` (Flutter) and emitted as inline `padding-left`
  /// on the content column (Web).
  static const CoreGapStyle defaultIndicatorContentGapStyle = CoreGapStyle(
    size: CoreSpace.space20,
  );

  /// Default nested [CoreGapStyle] slot for the gap above and below the
  /// connector line inside the indicator column. 1-off gap surrounding
  /// the connector sibling (same value applied on both sides) —
  /// forwarded to the two `Gap` siblings (Flutter) and emitted as
  /// inline `margin-top`/`margin-bottom` (or `margin-left`/`margin-right`
  /// in horizontal) on the connector (Web).
  static const CoreGapStyle defaultIndicatorConnectorGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default nested [CoreGapStyle] slot for the gap on either side of the
  /// connector line inside the indicator **row** of the horizontal layout —
  /// between the indicator circle and the line, and between the line and
  /// the next step. Wider than the vertical column's
  /// [defaultIndicatorConnectorGapStyle]: a row's line runs sideways into
  /// open space, a column's runs between two stacked circles, so the same
  /// 4 that keeps the column tight leaves the row's line touching the
  /// circle. A separate field (not one value) because the two layouts state
  /// different distances.
  static const CoreGapStyle defaultIndicatorConnectorGapHorizontalStyle =
      CoreGapStyle(size: CoreSpace.space8);

  /// Default padding below each step content in the vertical layout
  /// (32 logical/CSS px on the bottom edge only — non-final steps
  /// reserve this gap to the next step).
  static const CoreEdgeInsets defaultStepPadding = CoreEdgeInsets.only(
    bottom: CoreSpace.space32,
  );

  /// Default outer padding around each step content in the horizontal
  /// layout (logical px / CSS px, pre-scaling). Carries the top
  /// (`CoreSpace.space12`) and right (`CoreSpace.space16`) values
  /// previously emitted by the per-axis defaults; the widget zeroes the
  /// right side on the last item so the connector still ends cleanly.
  static const CoreEdgeInsets defaultStepPaddingHorizontal =
      CoreEdgeInsets.directional(
        top: CoreSpace.space12,
        end: CoreSpace.space16,
      );

  /// Default connector line stroke thickness (logical px / CSS px,
  /// pre-scaling).
  static const double defaultConnectorThickness = CoreStrokeWidth.stroke1;

  /// Check icon size ratio relative to the indicator diameter.
  static const double defaultIconSizeRatio = 0.5;

  /// Default fill colour of completed / current step indicators
  /// (`primary` token).
  static const CoreColor defaultActiveIndicatorColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default fill colour of upcoming (not yet reached) step indicators
  /// (`surface` token). An upcoming indicator is an outlined circle, not a
  /// filled one — the fill is the page's own and the ring that sets it
  /// apart is [defaultIndicatorBorderColor].
  static const CoreColor defaultIndicatorColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default ring colour of upcoming (not yet reached) step indicators
  /// (`outlineVariant` token). Completed, current and failed indicators
  /// are filled and draw no ring.
  static const CoreColor defaultIndicatorBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default ring thickness of upcoming step indicators (logical px / CSS
  /// px, pre-scaling).
  static const double defaultIndicatorBorderWidth = CoreStrokeWidth.stroke1;

  /// Default colour of a connector line that has not been walked yet — the
  /// one leading out of a current, upcoming or failed step
  /// (`outlineVariant` token). The segment after a completed step reads
  /// [defaultActiveConnectorColor] instead, so the line fills in as the
  /// steps are reached.
  static const CoreColor defaultConnectorColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default colour of the connector line leading out of a completed step
  /// (`primary` token — the same ink as the completed indicator's fill).
  static const CoreColor defaultActiveConnectorColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default label colour inside completed / current step indicators
  /// (on the active fill — `onPrimary` token).
  static const CoreColor defaultActiveLabelColor = CoreColor.token(
    CoreColors.onPrimary,
  );

  /// Default label colour inside upcoming step indicators (on the
  /// inactive fill — `onSurfaceVariant` token).
  static const CoreColor defaultInactiveLabelColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default fill colour of a failed step's indicator (`error` token). A
  /// failed step is not reached and not upcoming — it wears its own fill
  /// so the stop is read without the number.
  static const CoreColor defaultFailedIndicatorColor = CoreColor.token(
    CoreColors.error,
  );

  /// Default colour of the cross a failed step's indicator draws on its
  /// fill (`onError` token — the ink paired with
  /// [defaultFailedIndicatorColor]).
  static const CoreColor defaultFailedLabelColor = CoreColor.token(
    CoreColors.onError,
  );

  /// Default content title colour (`onSurface` token) — every step that
  /// has been reached, plus a failed one.
  static const CoreColor defaultTitleColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default content title colour of an upcoming step
  /// (`onSurfaceVariant` token) — a step not yet reached reads quieter
  /// than the ones that have been, so the current step stands out.
  static const CoreColor defaultInactiveTitleColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default content description colour (`onSurfaceVariant` token).
  static const CoreColor defaultDescriptionColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default indicator label typography — `labelLarge` role with a
  /// `semiBold` font-weight overlay (the step number is always stronger than
  /// the role's own medium). `final` (not `const`) because the `copyWith`
  /// overlay on a token-backed style is not a const expression.
  // A label role, not a body one — the slot is a control's LABEL.
  // `labelLarge` is 14 / 500 / 1.4; the semi-bold is the step number's own.
  static final CoreTextStyle defaultLabelStyle = const CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default content title typography for every step — the `titleSmall`
  /// role with a semi-bold (600) weight overlay. The role itself is bold
  /// (700), so the overlay is what keeps a title at the weight of the step
  /// numbers beside it. `final` (not `const`) because the `copyWith`
  /// overlay on a token-backed style is not a const expression.
  static final CoreTextStyle defaultTitleStyle = const CoreTextStyle.token(
    CoreTextStyles.titleSmall,
  ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default overlay for the current step's title — the same semi-bold (600)
  /// as every other step's, stated on its own so a caller can lift the
  /// current step alone through [currentTitleStyle] (merged on top of this
  /// default). What marks the current step is its filled indicator and the
  /// full-strength title colour, not a heavier weight.
  static const CoreTextStyle defaultCurrentTitleStyle = CoreTextStyle(
    fontWeight: CoreFontWeight.semiBold,
  );

  /// Default content description typography (`bodySmall` role).
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Default for [stepItemStyle] — the partial the list layout lays under
  /// every row before the caller's override, carrying only the fields in
  /// which a row `Steps` hosts differs from a `StepItem` on its own.
  ///
  /// None differ today: a hosted row is the same row, stacked flush (the
  /// list adds no gap between rows — each row's own padding is the rhythm).
  /// Everything is left `null` for the `StepItem` resolver to fill from
  /// [CoreStepItemStyle]'s own defaults — a copy of them here would be a
  /// second source.
  static const CoreStepItemStyle defaultStepItemStyle = CoreStepItemStyle();

  // ── Chrome (flat) ────────────────────────────

  /// Indicator circle diameter (logical px).
  final double? indicatorSize;

  /// Indicator (circle) corner radius override. Falls back to
  /// [defaultIndicatorBorderRadius] (a full circle) when null.
  final CoreBorderRadius? indicatorBorderRadius;

  /// Padding below each step content in the vertical layout. Falls
  /// back to [defaultStepPadding] when null.
  final CoreEdgeInsets? stepPadding;

  /// Outer padding around each step content in the horizontal layout —
  /// carries the top + right insets (the widget zeroes the right inset
  /// on the last item so the connector still ends cleanly).
  final CoreEdgeInsets? stepPaddingHorizontal;

  /// Connector line stroke thickness (logical px).
  final double? connectorThickness;

  /// Check icon size ratio relative to the indicator diameter.
  final double? iconSizeRatio;

  /// Colour of a connector line that has not been walked yet — the one
  /// leading out of a current, upcoming or failed step. Falls back to
  /// [defaultConnectorColor].
  final CoreColor? connectorColor;

  /// Colour of the connector line leading out of a completed step. Falls
  /// back to [defaultActiveConnectorColor].
  final CoreColor? activeConnectorColor;

  /// Inactive indicator fill colour. Falls back to [defaultIndicatorColor].
  final CoreColor? indicatorColor;

  /// Ring colour of upcoming indicators. Falls back to
  /// [defaultIndicatorBorderColor].
  final CoreColor? indicatorBorderColor;

  /// Ring thickness of upcoming indicators. Falls back to
  /// [defaultIndicatorBorderWidth].
  final double? indicatorBorderWidth;

  /// Active indicator fill colour. Falls back to
  /// [defaultActiveIndicatorColor].
  final CoreColor? activeIndicatorColor;

  /// Failed step indicator fill colour. Falls back to
  /// [defaultFailedIndicatorColor].
  final CoreColor? failedIndicatorColor;

  /// Label colour inside completed / current step indicators (on the
  /// active fill). Falls back to [defaultActiveLabelColor].
  final CoreColor? activeLabelColor;

  /// Label colour inside upcoming step indicators (on the inactive
  /// fill). Falls back to [defaultInactiveLabelColor].
  final CoreColor? inactiveLabelColor;

  /// Colour of the cross inside a failed step's indicator (on the failed
  /// fill). Falls back to [defaultFailedLabelColor].
  final CoreColor? failedLabelColor;

  /// Content title colour of every step that has been reached, and of a
  /// failed one. Falls back to [defaultTitleColor].
  final CoreColor? titleColor;

  /// Content title colour of an upcoming step. Falls back to
  /// [defaultInactiveTitleColor].
  final CoreColor? inactiveTitleColor;

  /// Content description colour. Falls back to [defaultDescriptionColor].
  final CoreColor? descriptionColor;

  /// Indicator label typography. Merged on top of [defaultLabelStyle].
  final CoreTextStyle? labelStyle;

  /// Content title typography for every step. Merged on top of
  /// [defaultTitleStyle], and on the current step on top of the
  /// [currentTitleStyle] overlay too, so a weight stated here reaches
  /// every step, the current one included.
  final CoreTextStyle? titleStyle;

  /// Overlay for the current step's title typography. Merged on top of
  /// [defaultCurrentTitleStyle]; the result sits between
  /// [defaultTitleStyle] and the per-instance [titleStyle].
  final CoreTextStyle? currentTitleStyle;

  /// Content description typography. Merged on top of
  /// [defaultDescriptionStyle].
  final CoreTextStyle? descriptionStyle;

  // ── Slot Styles (nested) ─────────────────────

  /// Gap between the indicator column and the step content. Laid over
  /// [defaultIndicatorContentGapStyle].
  final CoreGapStyle? indicatorContentGapStyle;

  /// Gap above and below the connector line inside the indicator column.
  /// Laid over [defaultIndicatorConnectorGapStyle].
  final CoreGapStyle? indicatorConnectorGapStyle;

  /// Gap on either side of the connector line inside the indicator row of
  /// the horizontal layout. Laid over
  /// [defaultIndicatorConnectorGapHorizontalStyle]; the vertical layout
  /// uses [indicatorConnectorGapStyle].
  final CoreGapStyle? indicatorConnectorGapHorizontalStyle;

  /// Style of each row in the list layout ([CoreStepsVariant.list]) — the
  /// `StepItem` it stacks. Laid over [defaultStepItemStyle] and passed to
  /// each row as is; the `StepItem` fills the rest from
  /// [CoreStepItemStyle]'s defaults. The status is not set here — each row
  /// takes its item's.
  final CoreStepItemStyle? stepItemStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreStepsStyle merge(CoreStepsStyle? other) {
    if (other == null) return this;
    return CoreStepsStyle(
      indicatorSize: other.indicatorSize ?? indicatorSize,
      indicatorBorderRadius:
          other.indicatorBorderRadius ?? indicatorBorderRadius,
      indicatorContentGapStyle: _mergeGap(
        indicatorContentGapStyle,
        other.indicatorContentGapStyle,
      ),
      indicatorConnectorGapStyle: _mergeGap(
        indicatorConnectorGapStyle,
        other.indicatorConnectorGapStyle,
      ),
      indicatorConnectorGapHorizontalStyle: _mergeGap(
        indicatorConnectorGapHorizontalStyle,
        other.indicatorConnectorGapHorizontalStyle,
      ),
      stepPadding: other.stepPadding ?? stepPadding,
      stepPaddingHorizontal:
          other.stepPaddingHorizontal ?? stepPaddingHorizontal,
      connectorThickness: other.connectorThickness ?? connectorThickness,
      iconSizeRatio: other.iconSizeRatio ?? iconSizeRatio,
      connectorColor: other.connectorColor ?? connectorColor,
      activeConnectorColor: other.activeConnectorColor ?? activeConnectorColor,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorBorderColor: other.indicatorBorderColor ?? indicatorBorderColor,
      indicatorBorderWidth: other.indicatorBorderWidth ?? indicatorBorderWidth,
      activeIndicatorColor: other.activeIndicatorColor ?? activeIndicatorColor,
      failedIndicatorColor: other.failedIndicatorColor ?? failedIndicatorColor,
      activeLabelColor: other.activeLabelColor ?? activeLabelColor,
      inactiveLabelColor: other.inactiveLabelColor ?? inactiveLabelColor,
      failedLabelColor: other.failedLabelColor ?? failedLabelColor,
      titleColor: other.titleColor ?? titleColor,
      inactiveTitleColor: other.inactiveTitleColor ?? inactiveTitleColor,
      descriptionColor: other.descriptionColor ?? descriptionColor,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      titleStyle: _mergeText(titleStyle, other.titleStyle),
      currentTitleStyle: _mergeText(currentTitleStyle, other.currentTitleStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      stepItemStyle:
          stepItemStyle?.merge(other.stepItemStyle) ?? other.stepItemStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreStepsStyle copyWith({
    double? indicatorSize,
    CoreBorderRadius? indicatorBorderRadius,
    CoreGapStyle? indicatorContentGapStyle,
    CoreGapStyle? indicatorConnectorGapStyle,
    CoreGapStyle? indicatorConnectorGapHorizontalStyle,
    CoreEdgeInsets? stepPadding,
    CoreEdgeInsets? stepPaddingHorizontal,
    double? connectorThickness,
    double? iconSizeRatio,
    CoreColor? connectorColor,
    CoreColor? activeConnectorColor,
    CoreColor? indicatorColor,
    CoreColor? indicatorBorderColor,
    double? indicatorBorderWidth,
    CoreColor? activeIndicatorColor,
    CoreColor? failedIndicatorColor,
    CoreColor? activeLabelColor,
    CoreColor? inactiveLabelColor,
    CoreColor? failedLabelColor,
    CoreColor? titleColor,
    CoreColor? inactiveTitleColor,
    CoreColor? descriptionColor,
    CoreTextStyle? labelStyle,
    CoreTextStyle? titleStyle,
    CoreTextStyle? currentTitleStyle,
    CoreTextStyle? descriptionStyle,
    CoreStepItemStyle? stepItemStyle,
  }) {
    return CoreStepsStyle(
      indicatorSize: indicatorSize ?? this.indicatorSize,
      indicatorBorderRadius:
          indicatorBorderRadius ?? this.indicatorBorderRadius,
      indicatorContentGapStyle:
          indicatorContentGapStyle ?? this.indicatorContentGapStyle,
      indicatorConnectorGapStyle:
          indicatorConnectorGapStyle ?? this.indicatorConnectorGapStyle,
      indicatorConnectorGapHorizontalStyle:
          indicatorConnectorGapHorizontalStyle ??
          this.indicatorConnectorGapHorizontalStyle,
      stepPadding: stepPadding ?? this.stepPadding,
      stepPaddingHorizontal:
          stepPaddingHorizontal ?? this.stepPaddingHorizontal,
      connectorThickness: connectorThickness ?? this.connectorThickness,
      iconSizeRatio: iconSizeRatio ?? this.iconSizeRatio,
      connectorColor: connectorColor ?? this.connectorColor,
      activeConnectorColor: activeConnectorColor ?? this.activeConnectorColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorBorderColor: indicatorBorderColor ?? this.indicatorBorderColor,
      indicatorBorderWidth: indicatorBorderWidth ?? this.indicatorBorderWidth,
      activeIndicatorColor: activeIndicatorColor ?? this.activeIndicatorColor,
      failedIndicatorColor: failedIndicatorColor ?? this.failedIndicatorColor,
      activeLabelColor: activeLabelColor ?? this.activeLabelColor,
      inactiveLabelColor: inactiveLabelColor ?? this.inactiveLabelColor,
      failedLabelColor: failedLabelColor ?? this.failedLabelColor,
      titleColor: titleColor ?? this.titleColor,
      inactiveTitleColor: inactiveTitleColor ?? this.inactiveTitleColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      labelStyle: labelStyle ?? this.labelStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      currentTitleStyle: currentTitleStyle ?? this.currentTitleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      stepItemStyle: stepItemStyle ?? this.stepItemStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStepsStyle &&
          runtimeType == other.runtimeType &&
          indicatorSize == other.indicatorSize &&
          indicatorBorderRadius == other.indicatorBorderRadius &&
          indicatorContentGapStyle == other.indicatorContentGapStyle &&
          indicatorConnectorGapStyle == other.indicatorConnectorGapStyle &&
          indicatorConnectorGapHorizontalStyle ==
              other.indicatorConnectorGapHorizontalStyle &&
          stepPadding == other.stepPadding &&
          stepPaddingHorizontal == other.stepPaddingHorizontal &&
          connectorThickness == other.connectorThickness &&
          iconSizeRatio == other.iconSizeRatio &&
          connectorColor == other.connectorColor &&
          activeConnectorColor == other.activeConnectorColor &&
          indicatorColor == other.indicatorColor &&
          indicatorBorderColor == other.indicatorBorderColor &&
          indicatorBorderWidth == other.indicatorBorderWidth &&
          activeIndicatorColor == other.activeIndicatorColor &&
          failedIndicatorColor == other.failedIndicatorColor &&
          activeLabelColor == other.activeLabelColor &&
          inactiveLabelColor == other.inactiveLabelColor &&
          failedLabelColor == other.failedLabelColor &&
          titleColor == other.titleColor &&
          inactiveTitleColor == other.inactiveTitleColor &&
          descriptionColor == other.descriptionColor &&
          labelStyle == other.labelStyle &&
          titleStyle == other.titleStyle &&
          currentTitleStyle == other.currentTitleStyle &&
          descriptionStyle == other.descriptionStyle &&
          stepItemStyle == other.stepItemStyle;

  @override
  int get hashCode => Object.hashAll([
    indicatorSize,
    indicatorBorderRadius,
    indicatorContentGapStyle,
    indicatorConnectorGapStyle,
    indicatorConnectorGapHorizontalStyle,
    stepPadding,
    stepPaddingHorizontal,
    connectorThickness,
    iconSizeRatio,
    connectorColor,
    activeConnectorColor,
    indicatorColor,
    indicatorBorderColor,
    indicatorBorderWidth,
    activeIndicatorColor,
    failedIndicatorColor,
    activeLabelColor,
    inactiveLabelColor,
    failedLabelColor,
    titleColor,
    inactiveTitleColor,
    descriptionColor,
    labelStyle,
    titleStyle,
    currentTitleStyle,
    descriptionStyle,
    stepItemStyle,
  ]);

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
