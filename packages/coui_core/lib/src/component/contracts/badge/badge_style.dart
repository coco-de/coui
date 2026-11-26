/// Per-instance style for `Badge`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/badge/badge_form.dart';
import 'package:coui_core/src/component/contracts/badge/badge_tone.dart';
import 'package:coui_core/src/component/contracts/badge/badge_tone_style.dart';
import 'package:coui_core/src/component/contracts/badge/badge_variant.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Badge` should render.
///
/// `CoreBadgeStyle` carries every chrome / dimensional override as a
/// flat slot plus nested `CoreTextStyle` / `CoreIconStyle` /
/// `CoreGapStyle` / `CoreFocusOutlineStyle` references for the label /
/// icon / leading-trailing spacer / focus-ring slots. Every default lives
/// here as `static const` so Flutter and Web share one source of truth:
///
/// - [defaultsBySize] — the step's height, padding, gap, label role, icon,
///   dot diameters and the label form's corner.
/// - [defaultsByForm] — what the form changes on top of the step: the
///   label's weight, and the pill corner a number and a dot take.
/// - [defaultsByTone] — each tone's colours for all three strengths and
///   for the dot.
///
/// **Semantic enums (`tone` / `variant` / `form` / `size`) live on the
/// widget, not on this style.** To change a badge's tone pass it as a
/// widget parameter; this style only describes chrome micro-tweaks.
///
/// ```text
/// defaultsBySize[size] → defaultsByForm[form] → defaultsByTone[tone] × variant
///   → CoreBadgeTheme.style                       // 프로젝트 공통
///   → CoreBadgeTheme.toneStyles[tone]
///   → CoreBadgeTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.badgeStyle                          // 인스턴스별
/// ```
@immutable
class CoreBadgeStyle implements CoreStyle<CoreBadgeStyle> {
  /// Creates a [CoreBadgeStyle].
  const CoreBadgeStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.minHeight,
    this.iconLabelGapStyle,
    this.transitionDuration,
    this.labelStyle,
    this.iconStyle,
    this.focusOutlineStyle,
    this.dotSize,
    this.leadingDotSize,
    this.leadingDotColor,
    this.stateLayer,
  });

  // ─── Design-system defaults ──

  /// The pill corner — what a number and a dot take whatever their step.
  ///
  /// [CoreBadgeForm.label] does not take it: a word sits in a rounded
  /// rectangle whose corner is per step in [defaultsBySize]. The pill is
  /// read through [defaultsByForm], not by the resolvers directly.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Border stroke width — drawn only where a border colour is stated,
  /// which by default is [CoreBadgeVariant.outlined].
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// The fill under an outlined badge — fully transparent, so the line
  /// alone carries the tone.
  static const CoreColor defaultOutlinedBackgroundColor = CoreColor.token(
    CoreColors.surface,
    opacity: CoreOpacity.opacity0,
  );

  /// Default chrome transition duration. Web emits this as
  /// `transition-colors duration-{ms}`; Flutter consumers read the
  /// [Duration] directly.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// The wash a pressable badge lays over itself while hovered or pressed
  /// — the label's own colour at the rung's weight, over the fill.
  ///
  /// [CoreStateLayer.standard] (8 / 8 / 16). The focus rung is unused:
  /// focus draws the ring ([defaultFocusOutlineStyle]), and a wash on top
  /// of the ring would make a focused badge read as a hovered one.
  ///
  /// A badge that is not pressable (`onPressed == null`) has no states and
  /// paints no wash.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.standard;

  /// Default focus-outline slot. Pairs 1:1 with the [focusOutlineStyle]
  /// override — the resolver merges this design-system default with the
  /// per-instance override (`defaultFocusOutlineStyle.merge(merged
  /// .focusOutlineStyle)`) so every focus-ring field flows through one
  /// nested [CoreFocusOutlineStyle] slot.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        align: CoreFocusOutlineStyle.defaultAlign,
        borderColor: CoreFocusOutlineStyle.defaultBorderColor,
        borderWidth: CoreFocusOutlineStyle.defaultBorderWidth,
        offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
      );

  /// Per-size dimensional defaults. Single source of truth shared by
  /// Flutter and Web.
  ///
  /// Each step has a minimum height ([minHeight]) and centres its content
  /// in it, so there is no vertical padding. Wrapped or enlarged text
  /// can grow the label form beyond that minimum; count content stays on
  /// one line.
  ///
  /// The corner ([borderRadius]) is the label form's: a quarter of the
  /// height, taken down to the radius ladder (18 → 4, 20 → 4, 24 → 6,
  /// 28 → 6, 32 → 8, 36 → 8). The count and dot forms replace it with the
  /// pill in [defaultsByForm].
  ///
  /// Each step's label states its ROLE, not a bare size, so the role's
  /// tracking and line height come with it. The weight is the form's, in
  /// [defaultsByForm].
  ///
  /// Every size has its own row; `xl2` is the 36 step.
  ///
  /// The map value is `CoreBadgeStyle` itself so the flat slot fields
  /// stay 1:1 with the per-size defaults.
  static const Map<CoreComponentSize, CoreBadgeStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreBadgeStyle(
      minHeight: CoreSize.size18,
      dotSize: CoreSize.size4,
      leadingDotSize: CoreSize.size4,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space6),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXs),
      iconStyle: CoreIconStyle(size: CoreIconSize.size10),
    ),
    CoreComponentSize.sm: CoreBadgeStyle(
      minHeight: CoreSize.size20,
      dotSize: CoreSize.size6,
      leadingDotSize: CoreSize.size4,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space6),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXs),
      iconStyle: CoreIconStyle(size: CoreIconSize.size12),
    ),
    CoreComponentSize.md: CoreBadgeStyle(
      minHeight: CoreSize.size24,
      dotSize: CoreSize.size8,
      leadingDotSize: CoreSize.size6,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
      iconStyle: CoreIconStyle(size: CoreIconSize.size14),
    ),
    CoreComponentSize.lg: CoreBadgeStyle(
      minHeight: CoreSize.size28,
      dotSize: CoreSize.size12,
      leadingDotSize: CoreSize.size6,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space10),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
      iconStyle: CoreIconStyle(size: CoreIconSize.size16),
    ),
    CoreComponentSize.xl: CoreBadgeStyle(
      minHeight: CoreSize.size32,
      dotSize: CoreSize.size16,
      leadingDotSize: CoreSize.size6,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
      iconStyle: CoreIconStyle(size: CoreIconSize.size16),
    ),
    CoreComponentSize.xl2: CoreBadgeStyle(
      minHeight: CoreSize.size36,
      dotSize: CoreSize.size16,
      leadingDotSize: CoreSize.size8,
      padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXl),
      iconStyle: CoreIconStyle(size: CoreIconSize.size18),
    ),
  };

  /// What each form changes on top of its step in [defaultsBySize].
  ///
  /// Merged over the size row, so a field a form leaves null keeps the
  /// step's value:
  ///
  /// - [CoreBadgeForm.label] keeps the role's weight (500) and the step's
  ///   corner.
  /// - [CoreBadgeForm.count] sets the figure at 600 and takes the pill.
  /// - [CoreBadgeForm.dot] takes the pill (a circle at its diameter).
  ///
  /// A word is set at the role's weight like every other label of its
  /// size; a figure in a count is set heavier, because a lone digit at a
  /// small size reads lighter than a word.
  static const Map<CoreBadgeForm, CoreBadgeStyle> defaultsByForm = {
    CoreBadgeForm.label: CoreBadgeStyle(),
    CoreBadgeForm.count: CoreBadgeStyle(
      labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
      borderRadius: defaultBorderRadius,
    ),
    CoreBadgeForm.dot: CoreBadgeStyle(borderRadius: defaultBorderRadius),
  };

  /// Each tone's colours — one row per [CoreBadgeTone], seven colours a
  /// row. [CoreBadgeToneStyle.restingStyleFor] picks the ones a variant
  /// and form paint.
  ///
  /// Every row reads the tone's existing status slots:
  ///
  /// - filled — the tone's colour behind its `on` colour;
  /// - tonal — the tone's container behind its container text;
  /// - outlined — a line in the tone's colour, the container text on the
  ///   page (primary reads `primaryText`, neutral `onSurface`), and for the
  ///   status tones the icon and leading dot in the line's colour;
  /// - dot — the tone's colour (neutral reads `outline`).
  ///
  /// Neutral has no status slots, so it reads the surface ramp: filled is
  /// the highest container, tonal one step down — both behind
  /// `onSurfaceVariant`.
  static const Map<CoreBadgeTone, CoreBadgeToneStyle> defaultsByTone = {
    CoreBadgeTone.neutral: CoreBadgeToneStyle(
      filledBackgroundColor: CoreColor.token(
        CoreColors.surfaceContainerHighest,
      ),
      filledForegroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
      tonalBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
      tonalForegroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
      outlinedBorderColor: CoreColor.token(CoreColors.outline),
      outlinedForegroundColor: CoreColor.token(CoreColors.onSurface),
      dotColor: CoreColor.token(CoreColors.outline),
    ),
    CoreBadgeTone.primary: CoreBadgeToneStyle(
      filledBackgroundColor: CoreColor.token(CoreColors.primary),
      filledForegroundColor: CoreColor.token(CoreColors.onPrimary),
      tonalBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
      tonalForegroundColor: CoreColor.token(CoreColors.onPrimaryContainer),
      outlinedBorderColor: CoreColor.token(CoreColors.primary),
      outlinedForegroundColor: CoreColor.token(CoreColors.primaryText),
      dotColor: CoreColor.token(CoreColors.primary),
    ),
    CoreBadgeTone.info: CoreBadgeToneStyle(
      filledBackgroundColor: CoreColor.token(CoreColors.info),
      filledForegroundColor: CoreColor.token(CoreColors.onInfo),
      tonalBackgroundColor: CoreColor.token(CoreColors.infoContainer),
      tonalForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
      outlinedBorderColor: CoreColor.token(CoreColors.info),
      outlinedForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
      outlinedMarkColor: CoreColor.token(CoreColors.info),
      dotColor: CoreColor.token(CoreColors.info),
    ),
    CoreBadgeTone.success: CoreBadgeToneStyle(
      filledBackgroundColor: CoreColor.token(CoreColors.success),
      filledForegroundColor: CoreColor.token(CoreColors.onSuccess),
      tonalBackgroundColor: CoreColor.token(CoreColors.successContainer),
      tonalForegroundColor: CoreColor.token(CoreColors.onSuccessContainer),
      outlinedBorderColor: CoreColor.token(CoreColors.success),
      outlinedForegroundColor: CoreColor.token(CoreColors.onSuccessContainer),
      outlinedMarkColor: CoreColor.token(CoreColors.success),
      dotColor: CoreColor.token(CoreColors.success),
    ),
    CoreBadgeTone.warning: CoreBadgeToneStyle(
      filledBackgroundColor: CoreColor.token(CoreColors.warning),
      filledForegroundColor: CoreColor.token(CoreColors.onWarning),
      tonalBackgroundColor: CoreColor.token(CoreColors.warningContainer),
      tonalForegroundColor: CoreColor.token(CoreColors.onWarningContainer),
      outlinedBorderColor: CoreColor.token(CoreColors.warning),
      outlinedForegroundColor: CoreColor.token(CoreColors.onWarningContainer),
      outlinedMarkColor: CoreColor.token(CoreColors.warning),
      dotColor: CoreColor.token(CoreColors.warning),
    ),
    CoreBadgeTone.destructive: CoreBadgeToneStyle(
      filledBackgroundColor: CoreColor.token(CoreColors.error),
      filledForegroundColor: CoreColor.token(CoreColors.onError),
      tonalBackgroundColor: CoreColor.token(CoreColors.errorContainer),
      tonalForegroundColor: CoreColor.token(CoreColors.onErrorContainer),
      outlinedBorderColor: CoreColor.token(CoreColors.error),
      outlinedForegroundColor: CoreColor.token(CoreColors.onErrorContainer),
      outlinedMarkColor: CoreColor.token(CoreColors.error),
      dotColor: CoreColor.token(CoreColors.error),
    ),
  };

  // ── Chrome (flat) ────────────────────────────

  /// Fill colour override. For [CoreBadgeForm.dot] this is the dot's
  /// colour. `null` defers to the tone row's colour for the variant
  /// ([CoreBadgeToneStyle.restingStyleFor]).
  final CoreColor? backgroundColor;

  /// Foreground (label / icon / leading dot) colour override. `null`
  /// defers to the tone row's colour for the variant.
  final CoreColor? foregroundColor;

  /// Border stroke colour. `null` defers to the tone row, which states one
  /// only for [CoreBadgeVariant.outlined]; with no colour no border is
  /// drawn.
  final CoreColor? borderColor;

  /// Border stroke width (logical px). `null` defers to
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Border radius. `null` defers to the form's corner — the step's in
  /// [defaultsBySize] for a label, the pill in [defaultsByForm] for a
  /// number and a dot.
  final CoreBorderRadius? borderRadius;

  /// Padding applied to the content row. `null` defers to
  /// `CoreBadgeStyle.defaultsBySize[size]!.padding!`. Horizontal only by
  /// default — the height is [minHeight].
  final CoreEdgeInsets? padding;

  /// Height of the label and count forms (logical px); the content is
  /// centred in it. A count is never narrower than this, so a single digit
  /// stays a circle. `null` defers to
  /// `CoreBadgeStyle.defaultsBySize[size]!.minHeight!`. Unused by
  /// [CoreBadgeForm.dot], which is [dotSize] across.
  final double? minHeight;

  /// Gap between the badge's parts — leading dot, leading slot, label,
  /// trailing slot. `null` defers to
  /// `CoreBadgeStyle.defaultsBySize[size]!.iconLabelGapStyle!`.
  final CoreGapStyle? iconLabelGapStyle;

  /// How long changes to the badge's look (colours, border) animate.
  /// `null` defers to [defaultTransitionDuration].
  final Duration? transitionDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Label text style override. `null` defers to the step's role in
  /// [defaultsBySize] with the form's weight from [defaultsByForm] laid
  /// over it.
  final CoreTextStyle? labelStyle;

  /// Leading / trailing icon style override (applied uniformly to
  /// both slots). `size` defers to
  /// `CoreBadgeStyle.defaultsBySize[size]!.iconStyle!.size!`.
  final CoreIconStyle? iconStyle;

  /// Diameter of the dot in [CoreBadgeForm.dot] (logical px). `null`
  /// defers to `defaultsBySize[size]!.dotSize!`. Unused by the label and
  /// count forms, whose box is [minHeight] tall.
  final double? dotSize;

  /// Diameter of the status dot drawn before the content when the badge's
  /// `showDot` is on (logical px). `null` defers to
  /// `defaultsBySize[size]!.leadingDotSize!`.
  final double? leadingDotSize;

  /// Colour of the status dot drawn before the content when `showDot` is
  /// on. `null` takes the badge's [foregroundColor], so the dot reads as
  /// part of the label; the `outlined` strength of a status tone states it
  /// (with the icon's colour) as the tone's line colour — see
  /// [CoreBadgeToneStyle.outlinedMarkColor].
  final CoreColor? leadingDotColor;

  /// Focus ring style ([CoreFocusOutlineStyle]). `null` defers to
  /// [defaultFocusOutlineStyle]. Only used when the badge is interactive
  /// (`onPressed != null`).
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Hover / pressed wash weights over the fill, in the label's colour.
  /// `null` defers to [defaultStateLayer]. Only consumed when the badge is
  /// interactive (`onPressed != null`); the focus rung is unused.
  final CoreStateLayer? stateLayer;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreBadgeStyle merge(CoreBadgeStyle? other) {
    if (other == null) return this;
    return CoreBadgeStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      minHeight: other.minHeight ?? minHeight,
      iconLabelGapStyle: _mergeGapStyle(
        iconLabelGapStyle,
        other.iconLabelGapStyle,
      ),
      transitionDuration: other.transitionDuration ?? transitionDuration,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      focusOutlineStyle: _mergeFocusOutline(
        focusOutlineStyle,
        other.focusOutlineStyle,
      ),
      dotSize: other.dotSize ?? dotSize,
      leadingDotSize: other.leadingDotSize ?? leadingDotSize,
      leadingDotColor: other.leadingDotColor ?? leadingDotColor,
      stateLayer: other.stateLayer ?? stateLayer,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreBadgeStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    double? minHeight,
    CoreGapStyle? iconLabelGapStyle,
    Duration? transitionDuration,
    CoreTextStyle? labelStyle,
    CoreIconStyle? iconStyle,
    CoreFocusOutlineStyle? focusOutlineStyle,
    double? dotSize,
    double? leadingDotSize,
    CoreColor? leadingDotColor,
    CoreStateLayer? stateLayer,
  }) {
    return CoreBadgeStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      minHeight: minHeight ?? this.minHeight,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      labelStyle: labelStyle ?? this.labelStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      dotSize: dotSize ?? this.dotSize,
      leadingDotSize: leadingDotSize ?? this.leadingDotSize,
      leadingDotColor: leadingDotColor ?? this.leadingDotColor,
      stateLayer: stateLayer ?? this.stateLayer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBadgeStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          minHeight == other.minHeight &&
          iconLabelGapStyle == other.iconLabelGapStyle &&
          transitionDuration == other.transitionDuration &&
          labelStyle == other.labelStyle &&
          iconStyle == other.iconStyle &&
          focusOutlineStyle == other.focusOutlineStyle &&
          dotSize == other.dotSize &&
          leadingDotSize == other.leadingDotSize &&
          leadingDotColor == other.leadingDotColor &&
          stateLayer == other.stateLayer;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    minHeight,
    iconLabelGapStyle,
    transitionDuration,
    labelStyle,
    iconStyle,
    focusOutlineStyle,
    dotSize,
    leadingDotSize,
    leadingDotColor,
    stateLayer,
  );

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

  static CoreFocusOutlineStyle? _mergeFocusOutline(
    CoreFocusOutlineStyle? base,
    CoreFocusOutlineStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGapStyle(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
