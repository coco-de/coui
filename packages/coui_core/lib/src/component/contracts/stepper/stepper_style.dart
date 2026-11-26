/// Per-instance style for `Stepper`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
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

/// Immutable style describing how a `Stepper` should render.
///
/// `CoreStepperStyle` carries chrome flat fields for the
/// indicator + connector plus nested label / description / icon
/// slot styles.
///
/// **Semantic enums (`orientation`) live on the widget, not on this
/// style** (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default
///   → CoreStepperTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.stepperStyle                          // 인스턴스별
/// ```
@immutable
class CoreStepperStyle implements CoreStyle<CoreStepperStyle> {
  /// Creates a [CoreStepperStyle].
  const CoreStepperStyle({
    this.indicatorActiveColor,
    this.indicatorCurrentColor,
    this.indicatorInactiveColor,
    this.indicatorBorderColor,
    this.indicatorCurrentBorderColor,
    this.indicatorInactiveBorderColor,
    this.indicatorBorderWidth,
    this.indicatorSize,
    this.indicatorBorderRadius,
    this.indicatorDisabledColor,
    this.indicatorDisabledBorderColor,
    this.connectorActiveColor,
    this.connectorInactiveColor,
    this.connectorDisabledColor,
    this.connectorThickness,
    this.indicatorContentGapStyle,
    this.stepPadding,
    this.connectorMargin,
    this.connectorMarginVertical,
    this.labelGapStyle,
    this.descriptionGapStyle,
    this.connectorMinExtent,
    this.iconSizeRatio,
    this.disabledForegroundColor,
    this.labelStyle,
    this.descriptionStyle,
    this.indicatorIconStyle,
    this.clickableStyle,
    this.indicatorNumberActiveStyle,
    this.indicatorNumberInactiveStyle,
    this.labelVerticalStyle,
    this.labelHorizontalStyle,
    this.labelActiveStyle,
    this.labelUpcomingStyle,
  });

  // ── Defaults (design-system, variant-independent) ──

  /// Default step indicator (circle) diameter (logical px / CSS px,
  /// pre-scaling).
  static const double defaultIndicatorSize = CoreSpace.space24;

  /// Default connector line stroke thickness (logical px / CSS px,
  /// pre-scaling). A 1px hairline.
  static const double defaultConnectorThickness = CoreStrokeWidth.stroke1;

  /// Default indicator border width — the ring the current step's circle
  /// ([defaultIndicatorCurrentBorderColor]) and an upcoming step's circle
  /// ([defaultIndicatorInactiveBorderColor]) wear, and the width of any ring a
  /// caller opts into on a completed circle through [indicatorBorderColor].
  static const double defaultIndicatorBorderWidth = CoreStrokeWidth.stroke1;

  /// Default indicator (circle) corner radius — fully round. Not an
  /// overridable field (the indicator has no `indicatorBorderRadius`
  /// slot; both platforms shape it as `.circle`/`50%`), so this is a
  /// named single-source the resolvers reference instead of the raw
  /// `CoreRadius.radius9999` token (verify_contracts.sh [11/13]).
  static const CoreBorderRadius defaultIndicatorBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default nested [CoreGapStyle] slot for the gap between the
  /// indicator column and the step content. Per-instance override flows
  /// through [indicatorContentGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultIndicatorContentGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default padding below each step content in the vertical layout
  /// (20 logical/CSS px on the bottom edge only — non-final steps
  /// reserve this gap to the next step).
  static const CoreEdgeInsets defaultStepPadding = CoreEdgeInsets.only(
    bottom: CoreSpace.space20,
  );

  /// Default margin between a circle and each half-line beside it in the
  /// horizontal layout (logical px / CSS px, pre-scaling) — zero, so the
  /// line meets the circle's edge and the two half-lines of neighbouring
  /// steps meet each other at the column boundary into one unbroken
  /// connector. The vertical layout's own margin is
  /// [defaultConnectorMarginVertical].
  static const double defaultConnectorMargin = CoreSpace.space0;

  /// Default margin above and below a connector in the vertical layout
  /// (logical px / CSS px, pre-scaling) — zero, so the line leaves one circle
  /// and reaches the next without a break.
  static const double defaultConnectorMarginVertical = CoreSpace.space0;

  /// Default nested [CoreGapStyle] slot for the gap between the
  /// indicator and its label in the horizontal layout. Per-instance
  /// override flows through [labelGapStyle] (merged on top of
  /// this default).
  static const CoreGapStyle defaultLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default nested [CoreGapStyle] slot for the gap between a step's
  /// label and its description. Per-instance override flows through
  /// [descriptionGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  /// Default minimum extent (length) of the connector in the vertical
  /// layout (logical px / CSS px, pre-scaling). Ensures the connector
  /// stays visible even when its row content is shorter than this.
  static const double defaultConnectorMinExtent = CoreSpace.space8;

  /// Check icon size ratio relative to the indicator diameter.
  static const double defaultIconSizeRatio = 0.5;

  /// Default step description text style — combines the `bodySmall`
  /// typography role token and the `onSurfaceVariant` colour into one
  /// [CoreTextStyle] so the Flutter and Web resolvers drive the
  /// description `<div>` / `Text` typography (font-size / weight /
  /// letter-spacing / line-height) and colour from the single
  /// [descriptionStyle] nested slot. Per-instance override flows through
  /// [descriptionStyle] (merged on top of this default).
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default indicator fill colour for the completed steps (`primary`) — the
  /// circle that holds the check glyph ([defaultIndicatorIconColor]). The
  /// resolvers fall back to this when [indicatorActiveColor] is null.
  static const CoreColor defaultIndicatorActiveColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default indicator fill colour for the current step (`surface`) — an
  /// outlined circle, not a filled one: the ring is
  /// [defaultIndicatorCurrentBorderColor]. The resolvers fall back to this
  /// when [indicatorCurrentColor] is null, enabled or disabled.
  static const CoreColor defaultIndicatorCurrentColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default ring colour of the current step's circle (`primary`) — the mark
  /// that sets the step in progress apart from the upcoming ones, whose ring
  /// is the quieter [defaultIndicatorInactiveBorderColor]. The resolvers fall
  /// back to this when [indicatorCurrentBorderColor] is null.
  static const CoreColor defaultIndicatorCurrentBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default indicator fill colour for upcoming steps (`surface`) — an
  /// outlined circle, not a filled one: the ring is
  /// [defaultIndicatorInactiveBorderColor]. The resolvers fall back to this
  /// when [indicatorInactiveColor] is null.
  static const CoreColor defaultIndicatorInactiveColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default ring colour of an upcoming step's circle (`outlineVariant`).
  /// A completed circle wears no ring unless the caller opts in through
  /// [indicatorBorderColor] / [indicatorBorderWidth]; the current circle's
  /// ring is [defaultIndicatorCurrentBorderColor]. The resolvers fall back to
  /// this when [indicatorInactiveBorderColor] is null.
  static const CoreColor defaultIndicatorInactiveBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default connector line colour for completed segments (`primary`) —
  /// the progress made reads along the line as well as on the circles. The
  /// resolvers fall back to this when [connectorActiveColor] is null.
  static const CoreColor defaultConnectorActiveColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default connector line colour for upcoming segments
  /// (`outlineVariant`). The resolvers fall back to this when
  /// [connectorInactiveColor] is null.
  static const CoreColor defaultConnectorInactiveColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default completed-step check-glyph colour (painted over the
  /// `primary` indicator fill — [defaultIndicatorActiveColor]). Reached
  /// through [defaultIndicatorIconStyle], which is what the resolvers read.
  static const CoreColor defaultIndicatorIconColor = CoreColor.token(
    CoreColors.onPrimary,
  );

  /// Default completed-step check-glyph style — the colour only. The
  /// glyph's `size` is the indicator diameter times [defaultIconSizeRatio]
  /// and both of those are per-instance overridable, so the size is a
  /// resolved value rather than a constant and the resolvers layer it on
  /// with `copyWith` before merging the per-instance
  /// [indicatorIconStyle] override on top.
  static const CoreIconStyle defaultIndicatorIconStyle = CoreIconStyle(
    color: defaultIndicatorIconColor,
  );

  /// Default indicator number text style for the current step — the
  /// `labelMedium` role (13) at a semi-bold weight, in the `onSurface`
  /// foreground painted over the `surface` indicator fill
  /// ([defaultIndicatorCurrentColor]). The weight is overlaid on the
  /// token-backed role via `copyWith` so the token slot survives (the
  /// resolver materialises the role then applies the overlay).
  static final CoreTextStyle defaultIndicatorNumberActiveStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelMedium,
        color: CoreColor.token(CoreColors.onSurface),
      ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default indicator number text style for upcoming steps — the
  /// `labelMedium` role at a semi-bold weight, in the `onSurfaceVariant`
  /// foreground painted over the `surface` indicator fill.
  static final CoreTextStyle defaultIndicatorNumberInactiveStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelMedium,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default step label text style for the vertical layout — the
  /// `titleSmall` typography role with the `onSurface` colour and a
  /// semi-bold (600) weight overlay. The role itself is bold (700), so
  /// without the overlay every label would read heavier than the current
  /// step's ([defaultLabelActiveStyle]). The resolvers merge the
  /// per-instance [labelStyle] on top. `final` (not `const`) because the
  /// `copyWith` overlay on a token-backed style is not a const
  /// expression.
  static final CoreTextStyle defaultLabelVerticalStyle =
      const CoreTextStyle.token(
        CoreTextStyles.titleSmall,
        color: CoreColor.token(CoreColors.onSurface),
      ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default step label text style for the horizontal layout — the
  /// `labelLarge` typography role (14, 500) with the `onSurface` colour.
  /// The resolvers merge the per-instance [labelStyle] on top.
  static const CoreTextStyle defaultLabelHorizontalStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default overlay for the current step's label — a semi-bold (600)
  /// weight, in either orientation: the typographic mark that sets the
  /// current step apart from the 500-weight horizontal rest. Per-instance
  /// override flows through [labelActiveStyle] (merged on top of this
  /// default).
  static const CoreTextStyle defaultLabelActiveStyle = CoreTextStyle(
    fontWeight: CoreFontWeight.semiBold,
  );

  /// Default overlay for an upcoming step's label — the `onSurfaceVariant`
  /// colour, in either orientation, so a step not yet reached reads one
  /// step quieter than the completed and current ones. Per-instance
  /// override flows through [labelUpcomingStyle] (merged on top of this
  /// default).
  static const CoreTextStyle defaultLabelUpcomingStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default indicator fill colour of a completed step when the stepper is
  /// disabled (`disabledContainer`). The resolvers fall back to this when
  /// [indicatorDisabledColor] is null.
  static const CoreColor defaultIndicatorDisabledColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default ring colour of the current and upcoming steps' circles when the
  /// stepper is disabled (`disabledOutline`). The resolvers fall back to this
  /// when [indicatorDisabledBorderColor] is null.
  static const CoreColor defaultIndicatorDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default connector line colour when the stepper is disabled
  /// (`disabledOutline`) — every segment, completed or not. The resolvers
  /// fall back to this when [connectorDisabledColor] is null.
  static const CoreColor defaultConnectorDisabledColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default ink of everything a disabled stepper writes or draws on a
  /// circle — the check glyph, the step numbers, the labels and the
  /// descriptions (`disabledContent`), one token so a disabled stepper dims
  /// as a block. The resolvers fall back to this when
  /// [disabledForegroundColor] is null.
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// per-indicator `Clickable` — an empty partial: step indicators take
  /// the Clickable's own standard press / focus / cursor chrome as-is.
  /// Named so the resolver's
  /// `defaultClickableStyle.merge(merged.clickableStyle)` forward has a
  /// single-source default.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle();

  // ── Indicator chrome (flat) ──────────────────

  /// Indicator (circle) fill colour for the completed steps. Falls back to
  /// [defaultIndicatorActiveColor].
  final CoreColor? indicatorActiveColor;

  /// Indicator fill colour for the current step. Falls back to
  /// [defaultIndicatorCurrentColor] — the same fill while the stepper is
  /// disabled.
  final CoreColor? indicatorCurrentColor;

  /// Indicator fill colour for upcoming steps. Falls back to
  /// [defaultIndicatorInactiveColor].
  final CoreColor? indicatorInactiveColor;

  /// Indicator border stroke colour — a ring on **every** step's circle,
  /// whatever its state.
  ///
  /// **No default, and must not have one.** A completed circle has no ring
  /// by default, and this field is half of how a caller asks for one: both
  /// platforms compute `hasBorder = indicatorBorderColor != null ||
  /// indicatorBorderWidth != null` for that circle and draw no stroke when
  /// it is false (Flutter leaves `BoxDecoration.border` null, Web writes no
  /// `border-*` declarations). A constant would make `hasBorder`
  /// permanently true and put a ring on every completed indicator on both
  /// platforms.
  ///
  /// It could not hold the right value anyway. Once a caller does opt in
  /// without naming a colour, the stroke falls back to the indicator's
  /// own fill for that step — `indicatorBorderColor ?? color` on Flutter,
  /// `?? fillCss` on Web — which is per-state and therefore not something
  /// one `static const` can name. [indicatorBorderWidth] has a named
  /// default because a width is the same number in either state; a colour
  /// is not.
  ///
  /// The current and upcoming circles always wear a ring, and state it
  /// through [indicatorCurrentBorderColor] / [indicatorInactiveBorderColor];
  /// a colour stated here wins over both while the stepper is enabled.
  final CoreColor? indicatorBorderColor;

  /// Ring colour of the current step's circle. Falls back to
  /// [defaultIndicatorCurrentBorderColor]; [indicatorBorderColor], when
  /// stated, wins over it while the stepper is enabled.
  final CoreColor? indicatorCurrentBorderColor;

  /// Ring colour of an upcoming step's circle. Falls back to
  /// [defaultIndicatorInactiveBorderColor]; [indicatorBorderColor], when
  /// stated, wins over it.
  final CoreColor? indicatorInactiveBorderColor;

  /// Indicator border stroke width (logical px). Falls back to
  /// [defaultIndicatorBorderWidth] wherever a ring is drawn — the current and
  /// upcoming circles always, a completed one only when the caller opts in.
  final double? indicatorBorderWidth;

  /// Indicator diameter (logical px).
  final double? indicatorSize;

  /// Indicator (circle) corner radius override. Falls back to
  /// [defaultIndicatorBorderRadius] (a full circle) when null.
  final CoreBorderRadius? indicatorBorderRadius;

  /// Indicator fill colour of a completed step while the stepper is
  /// disabled. Falls back to [defaultIndicatorDisabledColor]. The current and
  /// upcoming circles keep [indicatorCurrentColor] / [indicatorInactiveColor]
  /// — their fill is the surface either way.
  final CoreColor? indicatorDisabledColor;

  /// Ring colour of the current and upcoming steps' circles while the
  /// stepper is disabled. Falls back to [defaultIndicatorDisabledBorderColor].
  final CoreColor? indicatorDisabledBorderColor;

  // ── Connector chrome (flat) ──────────────────

  /// Connector line colour for completed segments. Falls back to
  /// [defaultConnectorActiveColor].
  final CoreColor? connectorActiveColor;

  /// Connector line colour for upcoming segments. Falls back to
  /// [defaultConnectorInactiveColor].
  final CoreColor? connectorInactiveColor;

  /// Connector line colour while the stepper is disabled — every
  /// segment. Falls back to [defaultConnectorDisabledColor].
  final CoreColor? connectorDisabledColor;

  /// Connector line thickness (logical px).
  final double? connectorThickness;

  // ── Dimensional chrome (flat) ────────────────

  /// Gap between the indicator column and the step content, passed to
  /// `Gap(gapStyle: …)` on both platforms. Laid over
  /// [defaultIndicatorContentGapStyle].
  final CoreGapStyle? indicatorContentGapStyle;

  /// Padding below each step content in the vertical layout. Falls
  /// back to [defaultStepPadding] when null.
  final CoreEdgeInsets? stepPadding;

  /// Margin between a circle and each half-line beside it in the horizontal
  /// layout (logical px) — the line leaving the circle's start and the one
  /// reaching its end. Falls back to [defaultConnectorMargin] when null.
  final double? connectorMargin;

  /// Margin above and below a connector in the vertical layout (logical
  /// px). Falls back to [defaultConnectorMarginVertical] when null.
  final double? connectorMarginVertical;

  /// Gap between the indicator and its label in the horizontal layout,
  /// passed to `Gap(gapStyle: …)` on both platforms. Laid over
  /// [defaultLabelGapStyle].
  final CoreGapStyle? labelGapStyle;

  /// Gap between a step's label and its description, passed to
  /// `Gap(gapStyle: …)` on both platforms. Laid over
  /// [defaultDescriptionGapStyle].
  final CoreGapStyle? descriptionGapStyle;

  /// Minimum extent (length) of the connector in the vertical layout
  /// (logical px). Falls back to [defaultConnectorMinExtent] when null.
  final double? connectorMinExtent;

  /// Check icon size ratio relative to the indicator diameter. Falls
  /// back to [defaultIconSizeRatio] when null.
  final double? iconSizeRatio;

  /// Ink of the check glyph, the step numbers, the labels and the
  /// descriptions while the stepper is disabled. Falls back to
  /// [defaultDisabledForegroundColor], and wins over the colour the same
  /// slot states for an enabled stepper.
  final CoreColor? disabledForegroundColor;

  // ── Slot Styles (nested) ─────────────────────

  /// Step label text style override for every step, in either
  /// orientation. Merged on top of the orientation default and, on the
  /// current step, on top of the [labelActiveStyle] overlay too, so a
  /// weight stated here reaches every step, the current one included.
  ///
  /// No `default*` of its own: the baseline is the orientation default
  /// ([defaultLabelVerticalStyle] / [defaultLabelHorizontalStyle]) this
  /// overlays, and a default here would sit on top of both and take
  /// their roles away.
  final CoreTextStyle? labelStyle;

  /// Step description text style override.
  final CoreTextStyle? descriptionStyle;

  /// Indicator icon style (applied when an indicator renders an
  /// icon — e.g. checkmark for completed steps).
  final CoreIconStyle? indicatorIconStyle;

  /// Current-step indicator number text style override.
  /// `null` → [defaultIndicatorNumberActiveStyle].
  final CoreTextStyle? indicatorNumberActiveStyle;

  /// Inactive (pending-step) indicator number text style override.
  /// `null` → [defaultIndicatorNumberInactiveStyle].
  final CoreTextStyle? indicatorNumberInactiveStyle;

  /// Step label text style override applied in vertical orientation.
  /// `null` → [defaultLabelVerticalStyle]. Merged with [labelStyle] on
  /// top (per-instance label override applies regardless of
  /// orientation).
  final CoreTextStyle? labelVerticalStyle;

  /// Step label text style override applied in horizontal orientation.
  /// `null` → [defaultLabelHorizontalStyle]. Merged with [labelStyle] on
  /// top.
  final CoreTextStyle? labelHorizontalStyle;

  /// Overlay for the current step's label, in either orientation.
  /// Merged on top of [defaultLabelActiveStyle]; the result sits between
  /// the orientation default and the per-instance [labelStyle].
  final CoreTextStyle? labelActiveStyle;

  /// Overlay for an upcoming step's label, in either orientation. Merged
  /// on top of [defaultLabelUpcomingStyle]; the result sits between the
  /// orientation default and the per-instance [labelStyle]. Only the
  /// visible label takes it — the invisible layers that reserve the
  /// column's width stay the current / reached styles, so an overlay that
  /// changes the weight or size of an upcoming label can outgrow them.
  final CoreTextStyle? labelUpcomingStyle;

  /// Style for each indicator's `Clickable` — press scale, durations,
  /// focus ring, disabled opacity. Laid over [defaultClickableStyle] and
  /// passed to the `Clickable` as is; the `Clickable` fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreStepperStyle merge(CoreStepperStyle? other) {
    if (other == null) return this;
    return CoreStepperStyle(
      indicatorActiveColor: other.indicatorActiveColor ?? indicatorActiveColor,
      indicatorCurrentColor:
          other.indicatorCurrentColor ?? indicatorCurrentColor,
      indicatorInactiveColor:
          other.indicatorInactiveColor ?? indicatorInactiveColor,
      indicatorBorderColor: other.indicatorBorderColor ?? indicatorBorderColor,
      indicatorCurrentBorderColor:
          other.indicatorCurrentBorderColor ?? indicatorCurrentBorderColor,
      indicatorInactiveBorderColor:
          other.indicatorInactiveBorderColor ?? indicatorInactiveBorderColor,
      indicatorBorderWidth: other.indicatorBorderWidth ?? indicatorBorderWidth,
      indicatorSize: other.indicatorSize ?? indicatorSize,
      indicatorBorderRadius:
          other.indicatorBorderRadius ?? indicatorBorderRadius,
      indicatorDisabledColor:
          other.indicatorDisabledColor ?? indicatorDisabledColor,
      indicatorDisabledBorderColor:
          other.indicatorDisabledBorderColor ?? indicatorDisabledBorderColor,
      connectorActiveColor: other.connectorActiveColor ?? connectorActiveColor,
      connectorInactiveColor:
          other.connectorInactiveColor ?? connectorInactiveColor,
      connectorDisabledColor:
          other.connectorDisabledColor ?? connectorDisabledColor,
      connectorThickness: other.connectorThickness ?? connectorThickness,
      indicatorContentGapStyle: _mergeGap(
        indicatorContentGapStyle,
        other.indicatorContentGapStyle,
      ),
      stepPadding: other.stepPadding ?? stepPadding,
      connectorMargin: other.connectorMargin ?? connectorMargin,
      connectorMarginVertical:
          other.connectorMarginVertical ?? connectorMarginVertical,
      labelGapStyle: _mergeGap(
        labelGapStyle,
        other.labelGapStyle,
      ),
      descriptionGapStyle: _mergeGap(
        descriptionGapStyle,
        other.descriptionGapStyle,
      ),
      connectorMinExtent: other.connectorMinExtent ?? connectorMinExtent,
      iconSizeRatio: other.iconSizeRatio ?? iconSizeRatio,
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      indicatorIconStyle: _mergeIcon(
        indicatorIconStyle,
        other.indicatorIconStyle,
      ),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      indicatorNumberActiveStyle: _mergeText(
        indicatorNumberActiveStyle,
        other.indicatorNumberActiveStyle,
      ),
      indicatorNumberInactiveStyle: _mergeText(
        indicatorNumberInactiveStyle,
        other.indicatorNumberInactiveStyle,
      ),
      labelVerticalStyle: _mergeText(
        labelVerticalStyle,
        other.labelVerticalStyle,
      ),
      labelHorizontalStyle: _mergeText(
        labelHorizontalStyle,
        other.labelHorizontalStyle,
      ),
      labelActiveStyle: _mergeText(labelActiveStyle, other.labelActiveStyle),
      labelUpcomingStyle: _mergeText(
        labelUpcomingStyle,
        other.labelUpcomingStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreStepperStyle copyWith({
    CoreColor? indicatorActiveColor,
    CoreColor? indicatorCurrentColor,
    CoreColor? indicatorInactiveColor,
    CoreColor? indicatorBorderColor,
    CoreColor? indicatorCurrentBorderColor,
    CoreColor? indicatorInactiveBorderColor,
    double? indicatorBorderWidth,
    double? indicatorSize,
    CoreBorderRadius? indicatorBorderRadius,
    CoreColor? indicatorDisabledColor,
    CoreColor? indicatorDisabledBorderColor,
    CoreColor? connectorActiveColor,
    CoreColor? connectorInactiveColor,
    CoreColor? connectorDisabledColor,
    double? connectorThickness,
    CoreGapStyle? indicatorContentGapStyle,
    CoreEdgeInsets? stepPadding,
    double? connectorMargin,
    double? connectorMarginVertical,
    CoreGapStyle? labelGapStyle,
    CoreGapStyle? descriptionGapStyle,
    double? connectorMinExtent,
    double? iconSizeRatio,
    CoreColor? disabledForegroundColor,
    CoreTextStyle? labelStyle,
    CoreTextStyle? descriptionStyle,
    CoreIconStyle? indicatorIconStyle,
    CoreClickableStyle? clickableStyle,
    CoreTextStyle? indicatorNumberActiveStyle,
    CoreTextStyle? indicatorNumberInactiveStyle,
    CoreTextStyle? labelVerticalStyle,
    CoreTextStyle? labelHorizontalStyle,
    CoreTextStyle? labelActiveStyle,
    CoreTextStyle? labelUpcomingStyle,
  }) {
    return CoreStepperStyle(
      indicatorActiveColor: indicatorActiveColor ?? this.indicatorActiveColor,
      indicatorCurrentColor:
          indicatorCurrentColor ?? this.indicatorCurrentColor,
      indicatorInactiveColor:
          indicatorInactiveColor ?? this.indicatorInactiveColor,
      indicatorBorderColor: indicatorBorderColor ?? this.indicatorBorderColor,
      indicatorCurrentBorderColor:
          indicatorCurrentBorderColor ?? this.indicatorCurrentBorderColor,
      indicatorInactiveBorderColor:
          indicatorInactiveBorderColor ?? this.indicatorInactiveBorderColor,
      indicatorBorderWidth: indicatorBorderWidth ?? this.indicatorBorderWidth,
      indicatorSize: indicatorSize ?? this.indicatorSize,
      indicatorBorderRadius:
          indicatorBorderRadius ?? this.indicatorBorderRadius,
      indicatorDisabledColor:
          indicatorDisabledColor ?? this.indicatorDisabledColor,
      indicatorDisabledBorderColor:
          indicatorDisabledBorderColor ?? this.indicatorDisabledBorderColor,
      connectorActiveColor: connectorActiveColor ?? this.connectorActiveColor,
      connectorInactiveColor:
          connectorInactiveColor ?? this.connectorInactiveColor,
      connectorDisabledColor:
          connectorDisabledColor ?? this.connectorDisabledColor,
      connectorThickness: connectorThickness ?? this.connectorThickness,
      indicatorContentGapStyle:
          indicatorContentGapStyle ?? this.indicatorContentGapStyle,
      stepPadding: stepPadding ?? this.stepPadding,
      connectorMargin: connectorMargin ?? this.connectorMargin,
      connectorMarginVertical:
          connectorMarginVertical ?? this.connectorMarginVertical,
      labelGapStyle: labelGapStyle ?? this.labelGapStyle,
      descriptionGapStyle: descriptionGapStyle ?? this.descriptionGapStyle,
      connectorMinExtent: connectorMinExtent ?? this.connectorMinExtent,
      iconSizeRatio: iconSizeRatio ?? this.iconSizeRatio,
      disabledForegroundColor:
          disabledForegroundColor ?? this.disabledForegroundColor,
      labelStyle: labelStyle ?? this.labelStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      indicatorIconStyle: indicatorIconStyle ?? this.indicatorIconStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      indicatorNumberActiveStyle:
          indicatorNumberActiveStyle ?? this.indicatorNumberActiveStyle,
      indicatorNumberInactiveStyle:
          indicatorNumberInactiveStyle ?? this.indicatorNumberInactiveStyle,
      labelVerticalStyle: labelVerticalStyle ?? this.labelVerticalStyle,
      labelHorizontalStyle: labelHorizontalStyle ?? this.labelHorizontalStyle,
      labelActiveStyle: labelActiveStyle ?? this.labelActiveStyle,
      labelUpcomingStyle: labelUpcomingStyle ?? this.labelUpcomingStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStepperStyle &&
          runtimeType == other.runtimeType &&
          indicatorActiveColor == other.indicatorActiveColor &&
          indicatorCurrentColor == other.indicatorCurrentColor &&
          indicatorInactiveColor == other.indicatorInactiveColor &&
          indicatorBorderColor == other.indicatorBorderColor &&
          indicatorCurrentBorderColor == other.indicatorCurrentBorderColor &&
          indicatorInactiveBorderColor == other.indicatorInactiveBorderColor &&
          indicatorBorderWidth == other.indicatorBorderWidth &&
          indicatorSize == other.indicatorSize &&
          indicatorBorderRadius == other.indicatorBorderRadius &&
          indicatorDisabledColor == other.indicatorDisabledColor &&
          indicatorDisabledBorderColor == other.indicatorDisabledBorderColor &&
          connectorActiveColor == other.connectorActiveColor &&
          connectorInactiveColor == other.connectorInactiveColor &&
          connectorDisabledColor == other.connectorDisabledColor &&
          connectorThickness == other.connectorThickness &&
          indicatorContentGapStyle == other.indicatorContentGapStyle &&
          stepPadding == other.stepPadding &&
          connectorMargin == other.connectorMargin &&
          connectorMarginVertical == other.connectorMarginVertical &&
          labelGapStyle == other.labelGapStyle &&
          descriptionGapStyle == other.descriptionGapStyle &&
          connectorMinExtent == other.connectorMinExtent &&
          iconSizeRatio == other.iconSizeRatio &&
          disabledForegroundColor == other.disabledForegroundColor &&
          labelStyle == other.labelStyle &&
          descriptionStyle == other.descriptionStyle &&
          indicatorIconStyle == other.indicatorIconStyle &&
          clickableStyle == other.clickableStyle &&
          indicatorNumberActiveStyle == other.indicatorNumberActiveStyle &&
          indicatorNumberInactiveStyle == other.indicatorNumberInactiveStyle &&
          labelVerticalStyle == other.labelVerticalStyle &&
          labelHorizontalStyle == other.labelHorizontalStyle &&
          labelActiveStyle == other.labelActiveStyle &&
          labelUpcomingStyle == other.labelUpcomingStyle;

  @override
  int get hashCode => Object.hashAll([
    indicatorActiveColor,
    indicatorCurrentColor,
    indicatorInactiveColor,
    indicatorBorderColor,
    indicatorCurrentBorderColor,
    indicatorInactiveBorderColor,
    indicatorBorderWidth,
    indicatorSize,
    indicatorBorderRadius,
    indicatorDisabledColor,
    indicatorDisabledBorderColor,
    connectorActiveColor,
    connectorInactiveColor,
    connectorDisabledColor,
    connectorThickness,
    indicatorContentGapStyle,
    stepPadding,
    connectorMargin,
    connectorMarginVertical,
    labelGapStyle,
    descriptionGapStyle,
    connectorMinExtent,
    iconSizeRatio,
    disabledForegroundColor,
    labelStyle,
    descriptionStyle,
    indicatorIconStyle,
    clickableStyle,
    indicatorNumberActiveStyle,
    indicatorNumberInactiveStyle,
    labelVerticalStyle,
    labelHorizontalStyle,
    labelActiveStyle,
    labelUpcomingStyle,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
