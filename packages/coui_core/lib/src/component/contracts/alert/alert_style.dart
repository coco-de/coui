/// Per-instance style for `Alert`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/alert/alert_layout.dart';
import 'package:coui_core/src/component/contracts/alert/alert_variant.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Alert` should render.
///
/// Alert is an *inline card*: rounded, borderless, sitting inside the
/// content's own margins. Its tone is carried by an opaque container fill
/// and the glyph drawn on it — not by a border, and not by an alpha tint.
/// `CoreBannerStyle` is the sibling for the page-level full-bleed band;
/// the two deliberately differ in shape and in which slots carry tone.
///
/// **Semantic enums (`variant`, `layout`) live on the widget, not on this
/// style** (Epic #1302 원칙 6/7). Inject sub-component widgets
/// directly to change their variant (Epic #1302 원칙 8 — asChild).
///
/// Two default tables feed the chain from below: [defaultsByVariant] for
/// what the tone paints (fill, glyph, description colour) and
/// [defaultsByLayout] for how much room the content takes (padding, floor,
/// gap, glyph size, title role and colour).
///
/// ```text
/// defaultsByLayout[layout] + defaultsByVariant[variant]
///   → CoreAlertTheme.style                       // 프로젝트 공통
///   → CoreAlertTheme.variantStyles[variant]
///   → parent component slot override
///   → widget.alertStyle                          // 인스턴스별
/// ```
@immutable
class CoreAlertStyle implements CoreStyle<CoreAlertStyle> {
  /// Creates a [CoreAlertStyle].
  const CoreAlertStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.titleColor,
    this.dismissColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.minHeight,
    this.iconContentGapStyle,
    this.titleBottomMargin,
    this.titleStyle,
    this.descriptionStyle,
    this.iconStyle,
    this.actionButtonStyle,
    this.closeButtonStyle,
  });

  /// Default outer border radius (box-level, 12px).
  ///
  /// Smaller than the 16 it used to be: Alert now reads as an inline
  /// card nested inside content, and the tighter corner keeps it from
  /// competing with the page-level containers it sits within.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius12,
  );

  /// Default border stroke width — **zero**.
  ///
  /// The tinted [CoreAlertVariantStyle.backgroundColor] is the whole
  /// boundary now. A border on top of an opaque tint reads as a second,
  /// fainter edge beside the real one.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke0;

  /// Default border stroke colour — **transparent**, the pair to
  /// [defaultBorderWidth] being zero.
  ///
  /// Stated rather than left implicit so the field has a baseline in Core
  /// instead of in each platform resolver. A colour that lives as a literal
  /// in two resolvers is two values that can drift apart with nothing
  /// visible in between; this is one.
  static const CoreColor defaultBorderColor = CoreColor.transparent;

  /// Default padding — 12 top/bottom, 16 leading, 12 trailing.
  ///
  /// Horizontally asymmetric on purpose: the leading inset is the larger
  /// one, so the glyph sits a full step in from the panel edge while the
  /// trailing slots (action, dismiss glyph) carry their own tap-target
  /// padding. Declared with `directional` rather than `left`/`right`
  /// because an asymmetric horizontal inset is a statement about reading
  /// order — spelled physically it is correct in English and silently
  /// wrong in Arabic, with nothing visible in between
  /// (`cross-platform/localization.md`).
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.directional(
    start: CoreSpace.space16,
    top: CoreSpace.space12,
    end: CoreSpace.space12,
    bottom: CoreSpace.space12,
  );

  /// Default minimum box height (64 logical px).
  ///
  /// Holds the panel at one row height whether or not a description is
  /// present, so a list of alerts does not jitter as descriptions come and
  /// go. A title and one description line measure 12 + 19.6 + 2 + 19.5 +
  /// 12 = 65.1, so a two-line alert sits just above the floor and a
  /// title-only alert is held open to it. Paired with cross-axis centring
  /// in each platform widget — without that, a description-less alert pins
  /// its glyph and title to the top and leaves the extra height empty.
  static const double defaultMinHeight = CoreSize.size64;

  /// Default gap style — `CoreGapStyle(size: 12)` — between the
  /// leading icon and the content column / trailing slots. The whole
  /// nested [CoreGapStyle] slot is forwarded to the `Gap` widget that
  /// separates the slots. Per-instance override flows through
  /// [iconContentGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultIconContentGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default bottom margin (2px) between the title and the
  /// description.
  static const double defaultTitleBottomMargin = CoreSpace.space2;

  /// Default title typography — the `labelLarge` role with a `semiBold`
  /// weight overlay.
  ///
  /// The weight is doing real work: `label-large` (14 / 500) sits one
  /// pixel and one weight step above `body-small` (13 / 400), so without
  /// it the title and description would read as one block and the only
  /// clear hierarchy left would be colour. Token-backed so the resolver
  /// materialises the role through the active theme
  /// (`.toValue(theme:)` / `emitTypography`) and stays dark-mode /
  /// accessibility-scale reactive. Per-instance override flows through
  /// [titleStyle] (merged on top of this default).
  static final CoreTextStyle defaultTitleStyle =
      const CoreTextStyle.token(CoreTextStyles.labelLarge).copyWith(
        fontWeight: CoreFontWeight.semiBold,
      );

  /// Default title colour — `onSurface`, in the stacked layout, for the
  /// variant that states no title colour of its own (`neutral`).
  ///
  /// A tone states its own — the glyph's `on-{tone}-container`, in
  /// [defaultsByVariant] — so the headline reads in the tone the panel
  /// announces, as `CoreBannerStyle`'s does. That pairing measures about 8:1
  /// on the tone's opaque fill, well over AA; `banner_alert_contrast_test`
  /// holds it. (Until 2026-10 every variant drew this neutral colour for the
  /// 14–16:1 it reaches; the designer chose the toned headline.)
  ///
  /// The inline strip states its own (see [defaultsByLayout]). Override
  /// through [titleColor], or through `titleStyle.color`, which the
  /// `CoreTextStyle` slot honours in full.
  static const CoreColor defaultTitleColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default description typography role — `bodySmall`. Token-backed
  /// (same rationale as [defaultTitleStyle]). Per-instance override
  /// flows through [descriptionStyle] (merged on top of this default).
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Default leading icon style — `size` only (colour comes from the
  /// variant's `iconColor`). 18 logical px, drawn straight onto the panel,
  /// in the stacked layout; the inline strip draws a 16 (see
  /// [defaultsByLayout]). Per-instance override flows through [iconStyle]
  /// (merged on top of the layout's row). The size is also handed to a
  /// caller's `leading` widget as the ambient icon size.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size18,
  );

  /// Default dismiss-affordance button style — the single source for the
  /// dismiss button's own chrome, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)` on both platforms. The
  /// `plain` variant owns the transparent-fill / hover-fade / focus-ring
  /// semantics; this slot adds only the tight 4 logical-px tap-target
  /// padding, the 4 logical-px corner radius (soft enough to read as a
  /// button without matching the panel's larger radius), the hover
  /// transition (150 ms), and the 16 logical-px close glyph
  /// (`leadingIconStyle`). The former flat `closeButtonPadding` /
  /// `closeButtonBorderRadius` / `dismissAnimationDuration` /
  /// `dismissFocusOutlineStyle` fields fold into this nested slot
  /// (child-component-composition).
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    padding: CoreEdgeInsets.all(CoreSpace.space4),
    animationDuration: Duration(milliseconds: CoreDuration.fast),
    leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
  );

  /// Default dismiss glyph colour — `onSurfaceVariant` at full opacity.
  ///
  /// States the resting colour outright instead of deriving it by
  /// multiplying the variant icon colour by 0.7. The old derivation
  /// produced a composited value that no contrast check could read
  /// (it depended on whatever tint happened to sit behind it), which is
  /// exactly the shape of defect this redesign exists to remove.
  ///
  /// No matching instance field — the override path is
  /// `closeButtonStyle.foregroundColor` / `hoverForegroundColor`.
  static const CoreColor defaultDismissColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Per-layout default styles — the measurements a layout decides.
  ///
  /// Every row states the same six fields, so `defaultsByLayout[layout]!`
  /// always answers padding, floor, glyph-to-content gap, glyph size, title
  /// role and title colour. The resolver reads these *under* the merge
  /// chain (`merged.X ?? row.X`), so a Theme or instance override wins in
  /// either layout.
  ///
  /// * `stacked` — the panel. Every value is the named `default*` constant
  ///   above, so those constants stay the single source for it.
  /// * `inline` — the status strip. 10 above and below, 14 at either end,
  ///   10 between the leading slot and the text, a 16 glyph when no
  ///   `leading` is given, and **no floor**: the strip is as tall as its
  ///   content (10 + 24 + 10 = 44 with an `md` badge as `leading`,
  ///   10 + 19.5 + 10 with the glyph alone). The title is one line of
  ///   `bodySmall` in `onSurfaceVariant` — the strip has room for one voice,
  ///   and the leading badge or glyph carries the emphasis, so the title
  ///   reads as the body text it replaces rather than as a heading.
  ///
  /// `static final` rather than `const` because the stacked title role
  /// carries a weight overlay ([defaultTitleStyle]), which `copyWith`
  /// produces at run time.
  static final Map<CoreAlertLayout, CoreAlertStyle> defaultsByLayout = {
    CoreAlertLayout.stacked: CoreAlertStyle(
      padding: defaultPadding,
      minHeight: defaultMinHeight,
      iconContentGapStyle: defaultIconContentGapStyle,
      iconStyle: defaultIconStyle,
      titleStyle: defaultTitleStyle,
      titleColor: defaultTitleColor,
    ),
    CoreAlertLayout.inline: const CoreAlertStyle(
      padding: CoreEdgeInsets.symmetric(
        vertical: CoreSpace.space10,
        horizontal: CoreSpace.space14,
      ),
      // No floor: the strip is as tall as its content.
      minHeight: 0,
      iconContentGapStyle: CoreGapStyle(size: CoreSpace.space10),
      iconStyle: CoreIconStyle(size: CoreIconSize.size16),
      titleStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
      titleColor: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
  };

  /// Per-variant default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  ///
  /// Only the fill and the glyph colour vary by tone. Title colour and
  /// dismiss colour are identical across all five variants and therefore
  /// live as `static const default*` above rather than being repeated
  /// five times here; the description reads `on-surface-variant` on every
  /// tone and stays in the row as the one place a tone could state its
  /// own.
  ///
  /// **Every background is an opaque container token, never an alpha
  /// tint.** The previous table painted `{tone}` at 10 % alpha and then
  /// put text in that same `{tone}` on top of it — background and
  /// foreground drawn from one colour, which cannot produce contrast no
  /// matter what the alpha is. Four of five variants failed the 4.5:1
  /// body-text floor that way, warning worst at 1.71. The fix needed no
  /// new tokens: the `{tone}-container` / `on-{tone}-container` pairs
  /// were already defined in all four modes. If an
  /// `CoreColor.token(..., opacity: …)` background ever reappears here,
  /// that defect is back.
  static const Map<CoreAlertVariant, CoreAlertVariantStyle> defaultsByVariant =
      {
        CoreAlertVariant.neutral: CoreAlertVariantStyle(
          backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
          descriptionColor: CoreColor.token(CoreColors.onSurfaceVariant),
          iconColor: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
        CoreAlertVariant.info: CoreAlertVariantStyle(
          backgroundColor: CoreColor.token(CoreColors.infoContainer),
          descriptionColor: CoreColor.token(CoreColors.onSurfaceVariant),
          iconColor: CoreColor.token(CoreColors.onInfoContainer),
          titleColor: CoreColor.token(CoreColors.onInfoContainer),
        ),
        CoreAlertVariant.success: CoreAlertVariantStyle(
          backgroundColor: CoreColor.token(CoreColors.successContainer),
          descriptionColor: CoreColor.token(CoreColors.onSurfaceVariant),
          iconColor: CoreColor.token(CoreColors.onSuccessContainer),
          titleColor: CoreColor.token(CoreColors.onSuccessContainer),
        ),
        CoreAlertVariant.warning: CoreAlertVariantStyle(
          backgroundColor: CoreColor.token(CoreColors.warningContainer),
          descriptionColor: CoreColor.token(CoreColors.onSurfaceVariant),
          iconColor: CoreColor.token(CoreColors.onWarningContainer),
          titleColor: CoreColor.token(CoreColors.onWarningContainer),
        ),
        CoreAlertVariant.destructive: CoreAlertVariantStyle(
          backgroundColor: CoreColor.token(CoreColors.errorContainer),
          descriptionColor: CoreColor.token(CoreColors.onSurfaceVariant),
          iconColor: CoreColor.token(CoreColors.onErrorContainer),
          titleColor: CoreColor.token(CoreColors.onErrorContainer),
        ),
      };

  /// Alert panel background fill colour.
  final CoreColor? backgroundColor;

  /// Foreground colour applied to title / description / icon when
  /// the per-slot style does not override it.
  final CoreColor? foregroundColor;

  /// Border stroke colour.
  ///
  /// Alert draws no border of its own since 0.131 — it fills opaquely, and
  /// [defaultBorderWidth] is zero. The slot stays so a caller can opt one
  /// back in by stating a colour AND a width; a colour alone strokes
  /// nothing.
  final CoreColor? borderColor;

  /// Title colour. `null` → the variant's `titleColor` in
  /// [defaultsByVariant] (a tone's `on-{tone}-container`), then the layout's
  /// row in [defaultsByLayout] ([defaultTitleColor] when stacked) for the
  /// variant that states none. Wins over [foregroundColor] for the title on
  /// both platforms.
  final CoreColor? titleColor;

  /// Dismiss-glyph colour. `null` → [defaultDismissColor].
  ///
  /// Replaces the opacity multiplier this used to carry — a colour times
  /// an alpha resolves against whatever panel sits behind it, which no
  /// guard can check. A token can be.
  final CoreColor? dismissColor;

  /// Border stroke width (logical px). `null` → [defaultBorderWidth],
  /// which is now zero.
  final double? borderWidth;

  /// Border radius.
  final CoreBorderRadius? borderRadius;

  /// Padding. `null` → the layout's row in [defaultsByLayout]
  /// ([defaultPadding] when stacked).
  final CoreEdgeInsets? padding;

  /// Minimum box height (logical px). `null` → the layout's row in
  /// [defaultsByLayout] ([defaultMinHeight] when stacked, none inline).
  final double? minHeight;

  /// Gap between the leading icon and the content column / trailing
  /// slots, passed as is to the `Gap` that separates them. Laid over the
  /// layout's row in [defaultsByLayout] ([defaultIconContentGapStyle] when
  /// stacked).
  final CoreGapStyle? iconContentGapStyle;

  /// Bottom margin between the title and description (logical px).
  /// `null` defers to [defaultTitleBottomMargin].
  final double? titleBottomMargin;

  /// Title text style override, merged on top of the layout's row in
  /// [defaultsByLayout] ([defaultTitleStyle] when stacked).
  final CoreTextStyle? titleStyle;

  /// Description text style override.
  final CoreTextStyle? descriptionStyle;

  /// Leading icon style override, laid over the layout's row in
  /// [defaultsByLayout] ([defaultIconStyle] when stacked). Its size is the
  /// icon size that a `leading` widget you pass inherits.
  final CoreIconStyle? iconStyle;

  /// Look of the action button — colours, padding, corners. Used only when
  /// the action you pass is a `Button`, and laid under that button's own
  /// `buttonStyle`, which still wins.
  ///
  /// **Deliberately has no `default*` — absence is the design.** The
  /// action is a caller-supplied widget, and the alert only reaches into
  /// it when the caller asked for chrome: both widgets rebuild a `Button`
  /// action with `resolved.actionButtonStyle!.merge(…)` only in the
  /// `when resolved.actionButtonStyle != null` arm of their pattern match,
  /// and render the action untouched otherwise. A constant would
  /// make that rebuild unconditional, so every alert would re-style a
  /// button it was handed — the composed `Button`'s own variant defaults
  /// are the baseline here, and overriding them from the parent is exactly
  /// what this slot is for when a caller opts in. Unlike [closeButtonStyle],
  /// which the alert draws itself and therefore does default
  /// ([defaultCloseButtonStyle]), this affordance is not the alert's to
  /// design.
  final CoreButtonStyle? actionButtonStyle;

  /// Close (dismiss) button style override.
  ///
  /// The single entry point for the dismiss-button chrome — padding /
  /// corner radius / close-glyph (`leadingIconStyle`) / hover transition
  /// (`animationDuration`) / focus ring (`focusOutlineStyle`) /
  /// idle-vs-hover foreground (`foregroundColor` /
  /// `hoverForegroundColor`). Merged onto [defaultCloseButtonStyle] and
  /// raw-forwarded to `Button(variant: .plain, buttonStyle: …)` (the
  /// `plain` variant owns the transparent-fill / hover-fade semantics).
  final CoreButtonStyle? closeButtonStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreAlertStyle merge(CoreAlertStyle? other) {
    if (other == null) return this;
    return CoreAlertStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      titleColor: other.titleColor ?? titleColor,
      dismissColor: other.dismissColor ?? dismissColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      minHeight: other.minHeight ?? minHeight,
      iconContentGapStyle: _mergeGap(
        iconContentGapStyle,
        other.iconContentGapStyle,
      ),
      titleBottomMargin: other.titleBottomMargin ?? titleBottomMargin,
      titleStyle: _mergeText(titleStyle, other.titleStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      actionButtonStyle: _mergeButton(
        actionButtonStyle,
        other.actionButtonStyle,
      ),
      closeButtonStyle: _mergeButton(closeButtonStyle, other.closeButtonStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreAlertStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    CoreColor? borderColor,
    CoreColor? titleColor,
    CoreColor? dismissColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    double? minHeight,
    CoreGapStyle? iconContentGapStyle,
    double? titleBottomMargin,
    CoreTextStyle? titleStyle,
    CoreTextStyle? descriptionStyle,
    CoreIconStyle? iconStyle,
    CoreButtonStyle? actionButtonStyle,
    CoreButtonStyle? closeButtonStyle,
  }) {
    return CoreAlertStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderColor: borderColor ?? this.borderColor,
      titleColor: titleColor ?? this.titleColor,
      dismissColor: dismissColor ?? this.dismissColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      minHeight: minHeight ?? this.minHeight,
      iconContentGapStyle: iconContentGapStyle ?? this.iconContentGapStyle,
      titleBottomMargin: titleBottomMargin ?? this.titleBottomMargin,
      titleStyle: titleStyle ?? this.titleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      actionButtonStyle: actionButtonStyle ?? this.actionButtonStyle,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAlertStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          titleColor == other.titleColor &&
          dismissColor == other.dismissColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          minHeight == other.minHeight &&
          iconContentGapStyle == other.iconContentGapStyle &&
          titleBottomMargin == other.titleBottomMargin &&
          titleStyle == other.titleStyle &&
          descriptionStyle == other.descriptionStyle &&
          iconStyle == other.iconStyle &&
          actionButtonStyle == other.actionButtonStyle &&
          closeButtonStyle == other.closeButtonStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    foregroundColor,
    borderColor,
    titleColor,
    dismissColor,
    borderWidth,
    borderRadius,
    padding,
    minHeight,
    iconContentGapStyle,
    titleBottomMargin,
    titleStyle,
    descriptionStyle,
    iconStyle,
    actionButtonStyle,
    closeButtonStyle,
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

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Visual style definition for a [CoreAlertVariant].
///
/// Carries the slots a tone may state: the panel fill, the description
/// colour (`on-surface-variant` on every tone today), the glyph colour and
/// the title colour. A tone's title takes the glyph's `on-{tone}-container`,
/// so the headline reads in the tone the panel announces; `neutral` states
/// none and keeps the layout's title colour. The dismiss glyph is the same on
/// every variant, so it lives as a `static const default*` on
/// [CoreAlertStyle].
///
/// All values are platform-neutral ([CoreColor]); the consuming renderer
/// converts at use-site (Flutter via `scheme.resolve(...).toValue()`;
/// Web via `'bg-${color}'` / `var(--coui-*)`).
@immutable
class CoreAlertVariantStyle {
  /// Creates an alert variant style.
  const CoreAlertVariantStyle({
    required this.backgroundColor,
    required this.descriptionColor,
    required this.iconColor,
    this.titleColor,
  });

  /// Panel background fill — the tone's opaque `{tone}-container`.
  final CoreColor backgroundColor;

  /// Description text colour — `on-surface-variant` on every tone, so the
  /// copy reads as copy and the tone is carried by the fill and the glyph.
  ///
  /// The title does *not* use this — it takes [titleColor].
  final CoreColor descriptionColor;

  /// Glyph colour — the tone's `on-{tone}-container`, drawn straight onto
  /// the panel fill.
  final CoreColor iconColor;

  /// Title colour — the tone's `on-{tone}-container`, the glyph's colour, in
  /// either layout. `null` (`neutral`) defers to the layout's title colour
  /// ([CoreAlertStyle.defaultsByLayout]): `on-surface` stacked,
  /// `on-surface-variant` inline. A style's `titleColor` or
  /// `foregroundColor` still outranks it.
  final CoreColor? titleColor;
}
