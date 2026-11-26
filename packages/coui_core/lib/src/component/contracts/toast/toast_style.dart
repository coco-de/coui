/// Per-instance style for `Toast`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/toast/toast_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart' show CoreSize;
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Toast` should render.
///
/// `CoreToastStyle` carries panel chrome / dimensional / close-button
/// / shadow overrides as flat fields plus nested `CoreTextStyle` /
/// `CoreButtonStyle` references for the message / description /
/// action button slots.
///
/// Variant-independent design-system defaults live as `static const`
/// on this class — Flutter and Web resolvers reference the same
/// `CoreToastStyle.defaultX` so the two platforms cannot silently
/// diverge. Variant-dependent chrome (background / foreground /
/// border colours) is supplied by [defaultsByVariant].
///
/// **Semantic enums (`variant`) live on the widget, not on this
/// style** (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default for variant
///   → CoreToastTheme.style                       // 프로젝트 공통
///   → CoreToastTheme.variantStyles[variant]      // variant 별
///   → parent component slot override
///   → widget.toastStyle                          // 인스턴스별
/// ```
@immutable
class CoreToastStyle implements CoreStyle<CoreToastStyle> {
  /// Creates a [CoreToastStyle].
  const CoreToastStyle({
    this.panelBackgroundColor,
    this.panelBorderColor,
    this.panelBorderRadius,
    this.panelBorderWidth,
    this.panelPadding,
    this.panelPaddingWithDismiss,
    this.panelBoxShadow,
    this.minHeight,
    this.contentActionGapStyle,
    this.iconStyle,
    this.iconContentGapStyle,
    this.messageDescriptionGapStyle,
    this.closeInset,
    this.transitionDuration,
    this.messageStyle,
    this.descriptionStyle,
    this.actionButtonStyle,
    this.plainActionButtonStyle,
    this.closeButtonStyle,
  });

  // ── Design-system defaults (Epic #1696 Phase 5) ──
  //
  // Variant-independent defaults — single source of truth shared by
  // the Flutter and Web resolvers.

  /// Default panel corner radius — the `surface` role (16 logical px): the
  /// toast is a dark bubble that floats free of the page, drawn one step
  /// rounder than a panel.
  static const CoreBorderRadius defaultPanelBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.surface,
  );

  /// Default panel border stroke width — none. The panel is a filled
  /// raised surface that reads by its fill and shadow; a hairline in the
  /// same colour as the fill is invisible, and a hairline in any other
  /// colour is not the design.
  static const double defaultPanelBorderWidth = CoreStrokeWidth.stroke0;

  /// Default panel content padding — 18 logical px inline, 14 block. A
  /// snackbar-height band around a single label line, not a card inset.
  static const CoreEdgeInsets defaultPanelPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space18,
    vertical: CoreSpace.space14,
  );

  /// Default panel content padding when a dismiss button is present —
  /// room on the trailing edge for the close button: its 8 corner inset
  /// ([defaultCloseInset]) plus the 40 × 40 circle it draws (`md` row,
  /// `shape: .square`), 48 logical px at the end.
  static const CoreEdgeInsets defaultPanelPaddingWithDismiss =
      CoreEdgeInsets.directional(
        start: CoreSpace.space18,
        top: CoreSpace.space14,
        end: CoreSpace.space48,
        bottom: CoreSpace.space14,
      );

  /// Default panel minimum height — 44 logical px. A one-line toast is
  /// 14 + 19.6 + 14 = 47.6 tall on padding alone, so the floor no longer
  /// lifts it; it still holds a toast whose padding a caller tightened, and
  /// keeps a message-only toast from shrinking under a message + action one.
  static const double defaultMinHeight = CoreSize.size44;

  // ── Toast layer defaults ──
  //
  // The layer that hosts and stacks toasts (Flutter `ToastLayer`) is
  // configured by its own parameters, not by a toast's style: one toast's
  // style cannot state the room between all of them. These are those
  // parameters' defaults, kept here so the value lives in Core like every
  // other design value. Web has no toast layer yet, so Flutter is their only
  // reader.

  /// Default gap between the toasts a toast layer fans out when its stack
  /// expands (8 logical px) — the layer's `spacing` default.
  ///
  /// Spacing: the layer's resolver moves it — and a caller's own value —
  /// with the theme density (4 / 8 / 12), the way every gap moves.
  static const double defaultStackSpacing = CoreSpace.space8;

  /// Default room a toast layer leaves between its stacks and the edges of
  /// the screen (24 logical px on every side) — the layer's `padding`
  /// default.
  ///
  /// Spacing: the layer's resolver moves it with the theme density (20 /
  /// 24 / 28). A caller's own padding is a framework inset the kit never
  /// converts, and is drawn as given.
  static const CoreEdgeInsets defaultLayerPadding = CoreEdgeInsets.all(
    CoreSpace.space24,
  );

  /// Default panel elevation shadow — the `shadow-sm` elevation stack
  /// (single source of truth shared with the Web Tailwind `shadow-sm`
  /// token and the Flutter resolver). The dark fill already separates the
  /// toast from the page, so the shadow only has to seat it.
  ///
  /// Per CLAUDE.md rule 2 (shadow chrome → [CoreShadowLayer] list
  /// 통째). Per-axis scalars (blur / offsetY / opacity) are forbidden —
  /// consumers that need a single axis should read the layer record
  /// component (e.g. `defaultPanelBoxShadow[0].opacity`).
  static const List<CoreShadowLayer> defaultPanelBoxShadow = CoreShadow.sm;

  /// Default gap style between the message + description column and
  /// the action slot — `CoreGapStyle(size: 16)`. Per-instance override
  /// flows through [contentActionGapStyle] (merged on top of this
  /// default).
  static const CoreGapStyle defaultContentActionGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
  );

  /// Default leading-glyph style — 16px, the size the canvas states.
  ///
  /// No colour: the variant row carries it (`CoreToastVariantStyle.iconColor`
  /// — the message colour on the two variants that draw a glyph, null on
  /// `neutral`, which draws none). Per-instance override flows through
  /// [iconStyle], merged on top of this.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default gap between the leading glyph and the content column —
  /// `CoreGapStyle(size: 10)`. Per-instance override flows through
  /// [iconContentGapStyle].
  static const CoreGapStyle defaultIconContentGapStyle = CoreGapStyle(
    size: CoreSpace.space10,
  );

  /// Default gap style between the message and description rows inside
  /// the content column — `CoreGapStyle(size: 2)`: the description reads
  /// as the message's second line, not a separate paragraph. Per-instance
  /// override flows through [messageDescriptionGapStyle].
  static const CoreGapStyle defaultMessageDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  /// Default close-button inset — 8 logical px from the trailing edge and
  /// 0 on the block axis. The close button is centred vertically in the
  /// band the top and bottom insets leave, which by default is the whole
  /// panel height: a one-line toast (~48) holds the 40 × 40 button with 4
  /// above and 4 below, and a toast with a description keeps it on the
  /// panel's centre line rather than pinned to the top. Both resolvers
  /// read the per-side insets at the paint site, so a caller can still
  /// narrow the band or move the button inward. This is panel-layout
  /// chrome (it places the dismiss button inside the panel), not button
  /// chrome, so it stays a flat field while the button's own chrome lives
  /// in [defaultCloseButtonStyle].
  static const CoreEdgeInsets defaultCloseInset = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space8,
  );

  /// Default dismiss-affordance button style — the single source for the
  /// close button's own chrome, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)` on both platforms. The
  /// `plain` variant owns the transparent fill and the hover fade; the
  /// resolvers tint it with the variant row's `closeForeground`
  /// (`inverseOnSurface @ 70%`) fading to `closeHoverForeground` (full
  /// `inverseOnSurface`) on hover. Both widgets compose it with
  /// `shape: .square`, so the button is the `md` row's height on both axes
  /// (40 × 40) with the shape's own zero inset, and the fully rounded corner
  /// here makes that square a circle — the same affordance as Banner's
  /// dismiss, where a rectangle drew the wash as a tall pill around the
  /// glyph. This slot adds that corner, the
  /// hover transition (150 ms), and the focus-ring width
  /// (`focusOutlineStyle.borderWidth`). The former flat
  /// `closePadding` / `closeIconStyle` / `closeButtonHoverDuration` /
  /// `closeButtonFocusRingWidth` fields fold into this nested slot
  /// (child-component-composition).
  ///
  /// The circle sits at [defaultCloseInset] from the panel's corner (16), so
  /// its edge stays inside the panel's curve; the panel height (48 for one
  /// line) holds the 40 row with that inset above and below.
  ///
  /// The focus ring's gap band is on (`offsetColor`): a toast floats over
  /// whatever the page shows, so its ring keeps the two-colour band
  /// (`CoreFocusRing.opaqueOffsetColor`) and a contrasting partner on any
  /// slab colour.
  ///
  /// It states no glyph size: the close glyph takes the square button's own
  /// (`CoreButtonStyle.defaultsBySize[md].iconShapeIconStyle`, 18) through the
  /// button's ambient icon theme — the same glyph Banner's dismiss draws
  /// (#6214).
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    animationDuration: Duration(milliseconds: CoreDuration.fast),
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderWidth: CoreFocusRing.ringWidth,
      offsetColor: CoreFocusRing.opaqueOffsetColor,
    ),
  );

  /// Default [actionButtonStyle] — the part of the action's chrome that is
  /// the same for every variant: the focus ring's gap band is on, the same
  /// two-colour band as the close button for the same reason. Hover and
  /// pressed lay the label colour over the action at the `subtle` ramp
  /// (`stateLayer`): the label is pinned to the slab's colour on hover as
  /// well as at rest, so the wash is the hover cue.
  ///
  /// The resolvers lay the variant's foreground over it and the caller's
  /// [actionButtonStyle] over that, then the action's own `buttonStyle`
  /// wins in the widget — so any of them can restate the band. An action
  /// that is not a `Button` passes through untouched (asChild), so this
  /// value does not reach it.
  ///
  /// It states no inset: an action keeps its own variant's size row — see
  /// [defaultPlainActionButtonStyle] for the one variant that needs one.
  static const CoreButtonStyle defaultActionButtonStyle = CoreButtonStyle(
    stateLayer: CoreStateLayer.subtle,
    focusOutlineStyle: CoreFocusOutlineStyle(
      offsetColor: CoreFocusRing.opaqueOffsetColor,
    ),
  );

  /// Default [plainActionButtonStyle] — the inline inset for an action that
  /// is a `plain` `Button`, and only that variant, for the same reason as
  /// Banner's: `plain` sits flush with its label, so the wash was exactly
  /// the word wide. 6 on each side widens the wash and the hit target
  /// together; the block pair is 0 because the size row's height holds the
  /// row (`xs` is 24), and the corner is the size row's own (6 at `xs`).
  /// Other variants keep their own size row's inset.
  static const CoreButtonStyle defaultPlainActionButtonStyle = CoreButtonStyle(
    padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space6),
  );

  /// Description-text foreground opacity the first inverse-surface toast
  /// used (90 %).
  @Deprecated(
    'Nothing reads it (since 0.162) — the variant row states the '
    'description colour, opacity included (inverse-on-surface at 75 %).',
  )
  static const double defaultDescriptionForegroundOpacity =
      CoreOpacity.opacity90;

  /// Close-glyph resting opacity the first inverse-surface toast used
  /// (70 %).
  @Deprecated(
    'Nothing reads it (since 0.162) — the variant row states the close '
    'colour, opacity included (inverse-on-surface at 70 %).',
  )
  static const double defaultCloseForegroundOpacity = CoreOpacity.opacity70;

  /// Default container chrome transition duration (200 ms). Powers
  /// the `transition-all duration-X` on the panel.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Default message (primary text) typography — the `labelLarge` role
  /// (14 / 1.4) with a semibold (600) weight overlaid. The message is the
  /// one line a toast carries, so it sits one step above the role's 500 to
  /// read at a glance on the dark bubble, and one step below the 700 a
  /// heading would take — it is running text, not a title. The weight is
  /// overlaid on the token-backed role via `copyWith` so the token slot
  /// survives (the resolver emits the role class / theme lookup, then the
  /// overlay). Single source of truth shared
  /// by the Flutter and Web resolvers
  /// (`defaultMessageStyle.merge(merged.messageStyle)`).
  static final CoreTextStyle defaultMessageStyle = const CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default description (secondary text) typography — the `bodySmall`
  /// role. Token-backed so the resolver emits the role class / theme
  /// lookup. The variant-dependent description colour is applied by the
  /// resolver (`descriptionForeground`), not baked into this role
  /// default. Single source of truth shared by Flutter and Web.
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Per-variant default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  /// The three variants, which differ in exactly one thing: the glyph.
  ///
  /// The panel is the same inverse surface (`inverse-surface`) on all of
  /// them, with `inverse-on-surface` text, the description at 75 % of it and
  /// the close glyph at 70 % (fading to full `inverse-on-surface` on hover),
  /// and no border. The glyph is drawn in the message colour too: the state
  /// is carried by the glyph's SHAPE (`circle-check` / `circle-alert`, none
  /// on `neutral`) and by the copy, not by a hue. That is the whole model: a
  /// toast is a dark bubble that stands out from whatever page it floats
  /// over, in one ink — no tinted panel and no tinted mark. The page-tuned
  /// `success` / `error` hues measured under 2:1 on the bubble in Dark,
  /// which is why the mark does not wear them.
  ///
  /// The two quieter tiers are the text colour at an opacity, not a second
  /// token: there is no `inverse-on-surface-variant` in the scheme. The
  /// contrast check composites them over the fill
  /// (`toast_contrast_test.dart`), so it reads what is painted.
  ///
  /// The bubble flips with the mode like every inverse role: a dark grey in
  /// Light, a light grey in Dark.
  static const Map<CoreToastVariant, CoreToastVariantStyle> defaultsByVariant =
      {
        CoreToastVariant.success: CoreToastVariantStyle(
          backgroundColor: CoreColor.token(CoreColors.inverseSurface),
          closeForeground: CoreColor.token(
            CoreColors.inverseOnSurface,
            opacity: CoreOpacity.opacity70,
          ),
          closeHoverForeground: CoreColor.token(CoreColors.inverseOnSurface),
          foregroundColor: CoreColor.token(CoreColors.inverseOnSurface),
          borderColor: CoreColor.token(CoreColors.inverseSurface),
          descriptionForeground: CoreColor.token(
            CoreColors.inverseOnSurface,
            opacity: CoreOpacity.opacity75,
          ),
          iconColor: CoreColor.token(CoreColors.inverseOnSurface),
        ),
        CoreToastVariant.destructive: CoreToastVariantStyle(
          backgroundColor: CoreColor.token(CoreColors.inverseSurface),
          closeForeground: CoreColor.token(
            CoreColors.inverseOnSurface,
            opacity: CoreOpacity.opacity70,
          ),
          closeHoverForeground: CoreColor.token(CoreColors.inverseOnSurface),
          foregroundColor: CoreColor.token(CoreColors.inverseOnSurface),
          borderColor: CoreColor.token(CoreColors.inverseSurface),
          descriptionForeground: CoreColor.token(
            CoreColors.inverseOnSurface,
            opacity: CoreOpacity.opacity75,
          ),
          iconColor: CoreColor.token(CoreColors.inverseOnSurface),
        ),
        CoreToastVariant.neutral: CoreToastVariantStyle(
          backgroundColor: CoreColor.token(CoreColors.inverseSurface),
          closeForeground: CoreColor.token(
            CoreColors.inverseOnSurface,
            opacity: CoreOpacity.opacity70,
          ),
          closeHoverForeground: CoreColor.token(CoreColors.inverseOnSurface),
          foregroundColor: CoreColor.token(CoreColors.inverseOnSurface),
          borderColor: CoreColor.token(CoreColors.inverseSurface),
          descriptionForeground: CoreColor.token(
            CoreColors.inverseOnSurface,
            opacity: CoreOpacity.opacity75,
          ),
          // No glyph. See `CoreToastVariantStyle.iconColor` for why this
          // is null rather than transparent.
        ),
      };

  // ── Panel chrome (flat) ──────────────────────

  /// Panel background fill colour override.
  final CoreColor? panelBackgroundColor;

  /// Panel border stroke colour override.
  final CoreColor? panelBorderColor;

  /// Panel border radius override.
  final CoreBorderRadius? panelBorderRadius;

  /// Panel border stroke width override (logical px). When null,
  /// defers to [defaultPanelBorderWidth] (1).
  final double? panelBorderWidth;

  /// Panel content padding override (no dismiss button). When null,
  /// defers to [defaultPanelPadding].
  final CoreEdgeInsets? panelPadding;

  /// Panel content padding override when a dismiss button is present —
  /// used instead of [panelPadding] so the trailing edge leaves room for
  /// the close button. When null, defers to
  /// [defaultPanelPaddingWithDismiss].
  final CoreEdgeInsets? panelPaddingWithDismiss;

  /// Panel elevation shadow override. When null, defers to
  /// [defaultPanelBoxShadow].
  final List<CoreShadowLayer>? panelBoxShadow;

  /// Panel minimum height override (logical px). When null, defers to
  /// [defaultMinHeight].
  final double? minHeight;

  /// Style of the `Gap` between the message + description column and the
  /// action slot. `null` defers to [defaultContentActionGapStyle].
  final CoreGapStyle? contentActionGapStyle;

  /// Leading-glyph style override. `null` defers to [defaultIconStyle].
  ///
  /// Size and any other icon chrome only — the colour comes from the
  /// variant row (the message colour), so the glyph reads on the bubble.
  final CoreIconStyle? iconStyle;

  /// Gap between the leading glyph and the content column. `null` defers
  /// to [defaultIconContentGapStyle].
  ///
  /// Reached only by the variants that draw a glyph; a toast with none
  /// starts at its content.
  final CoreGapStyle? iconContentGapStyle;

  /// Style of the `Gap` between the message and description rows inside
  /// the content column. `null` defers to
  /// [defaultMessageDescriptionGapStyle].
  final CoreGapStyle? messageDescriptionGapStyle;

  // ── Close button (panel-layout flat) ─────────

  /// Close-button inset — the right side is the button's distance from the
  /// trailing edge, and the top and bottom sides bound the band the button
  /// is centred in vertically. Four-sided so the caller can shift the
  /// dismiss button on any axis; the button's own look is set in
  /// [closeButtonStyle]. When null, defers to [defaultCloseInset].
  ///
  /// This is panel layout (it places the dismiss button inside the
  /// panel), not button chrome, so it stays flat.
  final CoreEdgeInsets? closeInset;

  // ── Motion (flat) ────────────────────────────

  /// Duration of the panel's transitions when its look changes. When
  /// null, defers to [defaultTransitionDuration].
  final Duration? transitionDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Message (primary text) style override.
  final CoreTextStyle? messageStyle;

  /// Description (secondary text) style override.
  final CoreTextStyle? descriptionStyle;

  /// Action button style override.
  ///
  /// To change the action's **variant**, inject the action widget
  /// directly via `Toast(action: Button(variant: outline, ...))`
  /// rather than packing variant into this style — Epic #1302 원칙
  /// 8 (asChild pattern).
  ///
  /// Its default ([defaultActionButtonStyle]) names no colour, deliberately
  /// — a flat default would name one colour for three variants; what the
  /// resolver injects over it is instead the VARIANT's own foreground, the
  /// same way [defaultCloseButtonStyle] is tinted with `closeForeground`:
  ///
  /// ```text
  /// defaultActionButtonStyle             // focus band
  ///   .merge(CoreButtonStyle(foregroundColor: variant.foregroundColor,
  ///                          hoverForegroundColor: variant.foregroundColor))
  ///   .merge(actionButtonStyle)          // this slot
  ///   .merge(action.buttonStyle)         // the caller's own Button, wins
  /// ```
  ///
  /// The action is the caller's widget, but it sits on the toast's own
  /// slab, not on the page surface a `Button`'s default foreground was
  /// chosen for — so the toast says what legible means there by laying the
  /// variant's foreground under it. The caller's explicit style still wins
  /// by merge order, and the caller's own `variant` is still theirs
  /// (asChild).
  final CoreButtonStyle? actionButtonStyle;

  /// Extra styling for an action that is a `plain` `Button` — laid over
  /// [actionButtonStyle] (and its default) for that variant only, and
  /// merged onto [defaultPlainActionButtonStyle]. A caller's
  /// [actionButtonStyle] still wins over the default here, so a padding
  /// stated there reaches every variant.
  final CoreButtonStyle? plainActionButtonStyle;

  /// Close (dismiss) button style override.
  ///
  /// The single entry point for the dismiss-button chrome — padding /
  /// close-glyph (`leadingIconStyle`) / hover transition
  /// (`animationDuration`) / focus-ring width
  /// (`focusOutlineStyle.borderWidth`). Merged onto
  /// [defaultCloseButtonStyle] and raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)` (the `plain` variant
  /// owns the resting-opacity / hover-fade / foreground semantics).
  final CoreButtonStyle? closeButtonStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreToastStyle merge(CoreToastStyle? other) {
    if (other == null) return this;
    return CoreToastStyle(
      panelBackgroundColor: other.panelBackgroundColor ?? panelBackgroundColor,
      panelBorderColor: other.panelBorderColor ?? panelBorderColor,
      panelBorderRadius: other.panelBorderRadius ?? panelBorderRadius,
      panelBorderWidth: other.panelBorderWidth ?? panelBorderWidth,
      panelPadding: other.panelPadding ?? panelPadding,
      panelPaddingWithDismiss:
          other.panelPaddingWithDismiss ?? panelPaddingWithDismiss,
      panelBoxShadow: other.panelBoxShadow ?? panelBoxShadow,
      minHeight: other.minHeight ?? minHeight,
      iconStyle: iconStyle?.merge(other.iconStyle) ?? other.iconStyle,
      iconContentGapStyle: _mergeGapStyle(
        iconContentGapStyle,
        other.iconContentGapStyle,
      ),
      contentActionGapStyle: _mergeGapStyle(
        contentActionGapStyle,
        other.contentActionGapStyle,
      ),
      messageDescriptionGapStyle: _mergeGapStyle(
        messageDescriptionGapStyle,
        other.messageDescriptionGapStyle,
      ),
      closeInset: other.closeInset ?? closeInset,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      messageStyle: _mergeText(messageStyle, other.messageStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      actionButtonStyle: _mergeButton(
        actionButtonStyle,
        other.actionButtonStyle,
      ),
      plainActionButtonStyle: _mergeButton(
        plainActionButtonStyle,
        other.plainActionButtonStyle,
      ),
      closeButtonStyle: _mergeButton(
        closeButtonStyle,
        other.closeButtonStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreToastStyle copyWith({
    CoreColor? panelBackgroundColor,
    CoreColor? panelBorderColor,
    CoreBorderRadius? panelBorderRadius,
    double? panelBorderWidth,
    CoreEdgeInsets? panelPadding,
    CoreEdgeInsets? panelPaddingWithDismiss,
    List<CoreShadowLayer>? panelBoxShadow,
    double? minHeight,
    CoreGapStyle? contentActionGapStyle,
    CoreIconStyle? iconStyle,
    CoreGapStyle? iconContentGapStyle,
    CoreGapStyle? messageDescriptionGapStyle,
    CoreEdgeInsets? closeInset,
    Duration? transitionDuration,
    CoreTextStyle? messageStyle,
    CoreTextStyle? descriptionStyle,
    CoreButtonStyle? actionButtonStyle,
    CoreButtonStyle? plainActionButtonStyle,
    CoreButtonStyle? closeButtonStyle,
  }) {
    return CoreToastStyle(
      panelBackgroundColor: panelBackgroundColor ?? this.panelBackgroundColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
      panelPadding: panelPadding ?? this.panelPadding,
      panelPaddingWithDismiss:
          panelPaddingWithDismiss ?? this.panelPaddingWithDismiss,
      panelBoxShadow: panelBoxShadow ?? this.panelBoxShadow,
      minHeight: minHeight ?? this.minHeight,
      contentActionGapStyle:
          contentActionGapStyle ?? this.contentActionGapStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      iconContentGapStyle: iconContentGapStyle ?? this.iconContentGapStyle,
      messageDescriptionGapStyle:
          messageDescriptionGapStyle ?? this.messageDescriptionGapStyle,
      closeInset: closeInset ?? this.closeInset,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      messageStyle: messageStyle ?? this.messageStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      actionButtonStyle: actionButtonStyle ?? this.actionButtonStyle,
      plainActionButtonStyle:
          plainActionButtonStyle ?? this.plainActionButtonStyle,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreToastStyle &&
          runtimeType == other.runtimeType &&
          panelBackgroundColor == other.panelBackgroundColor &&
          panelBorderColor == other.panelBorderColor &&
          panelBorderRadius == other.panelBorderRadius &&
          panelBorderWidth == other.panelBorderWidth &&
          panelPadding == other.panelPadding &&
          panelPaddingWithDismiss == other.panelPaddingWithDismiss &&
          _shadowEq(panelBoxShadow, other.panelBoxShadow) &&
          minHeight == other.minHeight &&
          contentActionGapStyle == other.contentActionGapStyle &&
          iconStyle == other.iconStyle &&
          iconContentGapStyle == other.iconContentGapStyle &&
          messageDescriptionGapStyle == other.messageDescriptionGapStyle &&
          closeInset == other.closeInset &&
          transitionDuration == other.transitionDuration &&
          messageStyle == other.messageStyle &&
          descriptionStyle == other.descriptionStyle &&
          actionButtonStyle == other.actionButtonStyle &&
          plainActionButtonStyle == other.plainActionButtonStyle &&
          closeButtonStyle == other.closeButtonStyle;

  @override
  int get hashCode => Object.hash(
    panelBackgroundColor,
    panelBorderColor,
    panelBorderRadius,
    panelBorderWidth,
    panelPadding,
    panelPaddingWithDismiss,
    panelBoxShadow == null ? null : Object.hashAll(panelBoxShadow!),
    minHeight,
    contentActionGapStyle,
    iconStyle,
    iconContentGapStyle,
    messageDescriptionGapStyle,
    closeInset,
    transitionDuration,
    messageStyle,
    descriptionStyle,
    actionButtonStyle,
    plainActionButtonStyle,
    closeButtonStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
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

  static CoreGapStyle? _mergeGapStyle(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static bool _shadowEq(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Visual style definition for a [CoreToastVariant].
///
/// Defines colours for: background, foreground, border, and optional
/// description foreground. All values are platform-neutral
/// ([CoreColor]); the consuming renderer converts at use-site (Flutter
/// via `scheme.resolve(...).toValue()`; Web via `'bg-${color}'` /
/// `var(--coui-*)`).
@immutable
class CoreToastVariantStyle {
  /// Creates a toast variant style.
  const CoreToastVariantStyle({
    required this.backgroundColor,
    required this.closeForeground,
    required this.closeHoverForeground,
    required this.foregroundColor,
    required this.borderColor,
    this.descriptionForeground,
    this.iconColor,
  });

  /// Background colour.
  final CoreColor backgroundColor;

  /// Close-glyph resting colour — the text colour at 70 %
  /// (`inverse-on-surface @ 70%`), injected into the dismiss `Button` as its
  /// resting foreground. The contrast check composites it over the fill.
  final CoreColor closeForeground;

  /// Close-glyph hover colour — `inverse-on-surface`, the text colour at
  /// full strength (the hover end of the `plain` fade).
  final CoreColor closeHoverForeground;

  /// Foreground (text) colour.
  final CoreColor foregroundColor;

  /// Border colour.
  final CoreColor borderColor;

  /// Leading-glyph colour, or `null` for a variant that draws no glyph.
  ///
  /// Nullable rather than transparent: "this variant has no glyph" and
  /// "this variant has an invisible glyph" lay out differently — the
  /// second still takes its width and its gap. [CoreToastVariant.neutral]
  /// means the first.
  ///
  /// The two variants that draw one state the message colour
  /// (`inverse-on-surface`): all three fill with the same inverse surface,
  /// so the glyph's shape — together with the copy — is what says which kind
  /// of toast this is, not its hue.
  final CoreColor? iconColor;

  /// Description text colour. When null, the resolver falls back to
  /// [foregroundColor].
  final CoreColor? descriptionForeground;
}
