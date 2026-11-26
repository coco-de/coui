/// Per-instance style for `Banner`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/banner/banner_emphasis.dart';
import 'package:coui_core/src/component/contracts/banner/banner_variant.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Banner` should render.
///
/// `CoreBannerStyle` carries every chrome / dimensional override as a
/// flat slot plus nested `CoreTextStyle` / `CoreIconStyle` /
/// `CoreButtonStyle` / `CoreGapStyle` references for the title /
/// description / icon / action / close button slots and the
/// inter-slot spacers. All defaults — variant-independent dimensional
/// (`padding`, `iconContentGapStyle`, `borderRadius`,
/// `borderWidth`, the dismiss-button chrome bundled in
/// [defaultCloseButtonStyle], focus ring) **and** variant-dependent
/// chrome (`backgroundColor` / `borderColor` / `iconColor` / `textColor`)
/// — live here as `static const` so Flutter and Web share a single
/// source of truth (Epic #1696 Phase 3, Tokens 폐기).
///
/// **Semantic enums (`variant`) live on the widget, not on this
/// style** (Epic #1302 원칙 6/7). To change a banner's variant pass
/// it as a widget parameter.
///
/// To change an action / close button's **variant** (e.g. ghost vs
/// destructive) inject the widget directly via
/// `Banner(action: Button(variant: destructive, ...))` rather
/// than packing variant into [actionButtonStyle] / [closeButtonStyle]
/// (Epic #1302 원칙 8 — asChild pattern).
///
/// ```text
/// design system default
///   → CoreBannerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.bannerStyle                          // 인스턴스별
/// ```
@immutable
class CoreBannerStyle implements CoreStyle<CoreBannerStyle> {
  /// Creates a [CoreBannerStyle].
  const CoreBannerStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.minHeight,
    this.padding,
    this.iconContentGapStyle,
    this.contentDismissGapStyle,
    this.titleDescriptionGapStyle,
    this.contentMinWidth,
    this.trailingRunSpacing,
    this.titleStyle,
    this.descriptionStyle,
    this.iconStyle,
    this.actionButtonStyle,
    this.plainActionButtonStyle,
    this.closeButtonStyle,
  });

  // ─── Design-system defaults (Phase 6f option D) ──

  /// Default thickness of the bottom rule (1px — `CoreStrokeWidth.stroke1`).
  ///
  /// **The rule is bottom-only, and that is structural rather than
  /// configurable.** A banner is a full-bleed band: it reaches the page
  /// edge on both sides, so a left/right stroke would terminate in
  /// mid-air, and a top stroke would double up with whatever sits above.
  /// Only the bottom edge separates the band from the content it sits
  /// over. There is therefore no side-selection field here — per
  /// `core/theme-axis-composition.md`, directional vocabulary is not
  /// invented ahead of a consumer that reads it, and no variant in the
  /// design picks a different side.
  ///
  /// A variant suppresses the rule by leaving
  /// [CoreBannerVariantStyle.borderColor] null, not by zeroing this
  /// width — `solid` does exactly that.
  ///
  /// The rule must not add to the band's height: both platforms draw it
  /// inside the box (CSS `box-sizing: border-box`, Flutter an inner
  /// edge), otherwise `weak` renders 1px taller than `solid` and the two
  /// stop lining up.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default border radius — square (0).
  ///
  /// A banner spans the full page width, so rounded corners would pull
  /// the fill away from the page edge and read as a floating card. The
  /// square corner is what makes the band read as page furniture rather
  /// than as content — this is the scale's deliberate `radius0` step,
  /// not an absence of styling.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.zero;

  /// Default minimum band height (72 logical px).
  ///
  /// Pinned so a banner is the same height whether or not it carries a
  /// description — without it the band collapses to roughly the
  /// trailing affordance plus padding when the description is absent,
  /// and two banners stacked in a page shift relative to each other
  /// purely on content. 72 is the same row height `list-tile` uses for
  /// its two-line form, which is structurally the same object (leading
  /// affordance + up to two lines of text).
  ///
  /// Consumers must pair this with centre cross-axis alignment;
  /// otherwise a description-less banner pins its icon and title to the
  /// top and leaves the reserved space empty underneath.
  static const double defaultMinHeight = CoreSize.size72;

  /// Default padding — `vertical: space12`, `horizontal: space16`.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space16,
    vertical: CoreSpace.space12,
  );

  /// Default gap style between leading icon / text column / trailing.
  /// Per-instance override flows through [iconContentGapStyle] (merged
  /// on top of this default).
  static const CoreGapStyle defaultIconContentGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default leading variant-icon style — carries the default variant
  /// icon size (`size16`, logical px). The glyph colour is resolved
  /// per-variant (or from `iconStyle.color`) at render time, so it is
  /// not baked into this design-system default; the resolver overlays
  /// the resolved colour before forwarding the slot to
  /// `Icon(iconStyle: …)`.
  ///
  /// 16 rather than the former 24: the band no longer distinguishes
  /// itself from an inline alert by the weight of its icon (that job now
  /// belongs to the full-bleed shape), so the icon can sit at the same
  /// optical weight as the label beside it.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default gap style before the dismiss button.
  /// Per-instance override flows through [contentDismissGapStyle].
  static const CoreGapStyle defaultContentDismissGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default vertical gap style between the title and description.
  /// Per-instance override flows through [titleDescriptionGapStyle].
  static const CoreGapStyle defaultTitleDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default [contentMinWidth] — 240 (`CoreLayout.layout240`).
  ///
  /// The message column (title + description) stays beside the trailing
  /// group — the action and the dismiss button — only while it can keep
  /// this much width. Below it the trailing group moves to a line of its
  /// own under the message instead of squeezing the text into a column a
  /// few words wide, which on a phone left the action too narrow to hit.
  ///
  /// The decision compares this floor plus the content-to-trailing gap
  /// plus the trailing group's own width against the width the message
  /// and the trailing group share — never the banner's own width against a
  /// breakpoint, so the same banner wraps or not by what it carries. Once
  /// the trailing group has its own line the message takes the whole
  /// width, even when that is narrower than this floor.
  ///
  /// A layout bound rather than spacing: density does not move it.
  static const double defaultContentMinWidth = CoreLayout.layout240;

  /// Default [trailingRunSpacing] — `space8`.
  ///
  /// The vertical distance between the message column and the trailing
  /// line when the trailing group has wrapped below it. The wrapped line
  /// starts where the message text starts (after the leading icon), not at
  /// the band's edge, so the buttons read as belonging to the message.
  /// Spacing, so density moves it.
  static const double defaultTrailingRunSpacing = CoreSpace.space8;

  /// Default dismiss-affordance button style — the single source for
  /// the close button's own chrome, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)` on both platforms. The
  /// `plain` variant owns the transparent-fill / hover-fade semantics;
  /// both widgets compose it with `shape: .square`, so the button is the
  /// size row's height on both axes (40 × 40 at the default `md`) and the
  /// shape's own zero inset applies — an icon-only affordance is square
  /// (the CoUI convention the full-screen Command back button follows), and
  /// the fully rounded corner below makes that square a circle. A
  /// rectangle-shape inset here would draw the hover and pressed wash as a
  /// tall pill around the glyph (28 × 40). This slot adds the fully
  /// rounded corner and the 150 ms hover transition. It states no glyph
  /// size: the close glyph takes the square button's own
  /// (`CoreButtonStyle.defaultsBySize[md].iconShapeIconStyle`, 18) through
  /// the button's ambient icon theme, like every icon-only button of that
  /// size — Toast's close is the same affordance and draws the same glyph
  /// (#6214). Colour stays null so the glyph inherits the button
  /// foreground. The former flat
  /// `dismissIconStyle` / `dismissButtonPadding` / `dismissBorderRadius`
  /// / `dismissButtonOpacity` / `dismissButtonHoverOpacity` /
  /// `transitionDuration` fields fold into this nested slot
  /// (child-component-composition).
  ///
  /// Hover and pressed lay the glyph colour over the button at the
  /// `subtle` ramp (`stateLayer`): the glyph is pinned to the banner's
  /// own colour at rest and on hover, so the wash is the only hover cue
  /// left, and it reads on a pale and a saturated banner alike.
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    animationDuration: Duration(milliseconds: CoreDuration.fast),
    stateLayer: CoreStateLayer.subtle,
  );

  /// Default action-affordance button style — a partial, per
  /// `core/style-contract.md`'s partial-slot-forward rule: Banner states
  /// no dimension of its action's chrome, so `Button`'s own resolver fills
  /// them. The one field it states is the hover and pressed cue: the label
  /// colour laid over the button at the `subtle` ramp (`stateLayer`), the
  /// same ramp the kit's other non-swapping buttons use. The label is
  /// pinned to the banner's colour on hover too (below), so without the
  /// wash nothing would change under the pointer.
  ///
  /// One value does travel, and it is not stated here because it is not a
  /// constant: both resolvers merge the **variant's foreground** over this
  /// partial before forwarding, then the caller's `actionButtonStyle` over
  /// that. Left alone the label kept `plain`'s own colour — picked for a
  /// light neutral surface — so on a solid banner it read as a dark grey
  /// word on a saturated fill while everything around it tracked the tone.
  ///
  /// It states no inset: an action keeps its own variant's size row (an
  /// `outline` `sm` is 12 a side inside and outside a banner alike) — see
  /// [defaultPlainActionButtonStyle] for the one variant that needs one.
  static const CoreButtonStyle defaultActionButtonStyle = CoreButtonStyle(
    stateLayer: CoreStateLayer.subtle,
  );

  /// Default [plainActionButtonStyle] — the inline inset for an action that
  /// is a `plain` `Button`, and only that variant. `plain` sits flush with
  /// the text around it (inline padding 0), which on a banner made the wash
  /// exactly the label wide — a highlighter stroke over the word rather
  /// than a button under the pointer. 8 on each side widens the wash and
  /// the hit target together; the block pair is 0 because the size row's
  /// height holds the row (`sm` is 32), and the corner is the size row's
  /// own (8 at `sm`). Every other variant already has an inset of its own,
  /// and the button's own size row is the one place its inset is decided —
  /// restating it here would draw the same `sm` outline narrower inside a
  /// banner than outside one.
  static const CoreButtonStyle defaultPlainActionButtonStyle = CoreButtonStyle(
    padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
  );

  /// Default focus ring stroke width (logical px).
  static const double defaultFocusRingWidth = CoreFocusRing.ringWidth;

  /// Default focus ring offset from the banner outer edge (logical px).
  static const double defaultFocusRingOffset = CoreFocusRing.ringOffset;

  /// Default focus ring colour token.
  static const CoreColor defaultFocusRingColor = CoreFocusRing.ringColor;

  /// Default title typography slot — `labelLarge`, at the role's own
  /// medium weight.
  ///
  /// No weight overlay: the message and the description are told apart by
  /// role and colour together — `label-large` (14 / 500) against
  /// `body-small` (13 / 400), and on every `weak` band the description
  /// steps down to `onSurfaceVariant` while the message keeps the band's
  /// own foreground. A semi-bold message on top of that read heavier than
  /// the announcement it carries.
  static const CoreTextStyle defaultTitleStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  /// Default description typography slot — `bodySmall`.
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Per-variant, per-emphasis default styles. Single source of truth
  /// shared by Flutter and Web — each platform resolves the [CoreColor]
  /// via its own extension (`.toValue()` / `scheme.resolve(...)`).
  ///
  /// Two axes, nested rather than flattened: `variant` says what kind of
  /// message this is, `emphasis` says how hard it presses. A flattened
  /// 10-key enum would make every future tone two hand-authored entries
  /// instead of one, with nothing to catch a missing half.
  ///
  /// **The fill is an opaque container token, never a tint.** Every
  /// entry below used to be the tone's own accent colour at 10 % alpha
  /// with that *same* accent as the label on top — a pairing whose
  /// contrast cannot come out right no matter what the alpha is, because
  /// both operands move together. `warning` measured 1.71:1. The
  /// `{tone}Container` / `on{Tone}Container` pairs used here were
  /// already defined in all four modes; nothing new was minted. Do not
  /// reintroduce an alpha here — a composited fill also defeats the
  /// contrast guards, which can only read declared token pairs.
  ///
  /// The name stays `defaultsByVariant` even though the value type
  /// changed, and there is deliberately **no** compatibility shim
  /// returning the old flat shape: a shim would have to pick an
  /// emphasis, and a call site that kept compiling while silently
  /// getting only the `weak` half is worse than one that fails to
  /// compile. The type change is the migration signal.
  ///
  /// **Every `weak` description is `onSurfaceVariant`**, whatever the
  /// tone: the message keeps the tone's own `on{Tone}Container` and the
  /// description steps down to the shared secondary text colour, so the
  /// two-line block reads as message then detail on every band. Measured
  /// against the four `{tone}Container` fills that pair is 6.4–7.0:1 in
  /// light and dark (CoUI preset), so the step down stays above AA. A
  /// `solid` band keeps one token for both — its fill is the saturated
  /// tone, and the secondary text colour is not designed against it.
  static const Map<
    CoreBannerVariant,
    Map<CoreBannerEmphasis, CoreBannerVariantStyle>
  >
  defaultsByVariant = {
    CoreBannerVariant.neutral: {
      CoreBannerEmphasis.weak: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainerLow),
        borderColor: CoreColor.token(
          CoreColors.outline,
          fallbacks: [CoreColors.onSurface],
        ),
        iconColor: CoreColor.token(CoreColors.onSurface),
        textColor: CoreColor.token(CoreColors.onSurface),
        descriptionColor: CoreColor.token(
          CoreColors.onSurfaceVariant,
          fallbacks: [CoreColors.onSurface],
        ),
      ),
      CoreBannerEmphasis.solid: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.primary),
        iconColor: CoreColor.token(CoreColors.onPrimary),
        textColor: CoreColor.token(CoreColors.onPrimary),
        descriptionColor: CoreColor.token(CoreColors.onPrimary),
        focusOutlineStyle: CoreFocusOutlineStyle(
          offsetColor: CoreFocusRing.opaqueOffsetColor,
        ),
      ),
    },
    CoreBannerVariant.info: {
      CoreBannerEmphasis.weak: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.infoContainer),
        borderColor: CoreColor.token(
          CoreColors.outline,
          fallbacks: [CoreColors.onSurface],
        ),
        iconColor: CoreColor.token(CoreColors.onInfoContainer),
        textColor: CoreColor.token(CoreColors.onInfoContainer),
        descriptionColor: CoreColor.token(
          CoreColors.onSurfaceVariant,
          fallbacks: [CoreColors.onSurface],
        ),
      ),
      CoreBannerEmphasis.solid: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.info),
        iconColor: CoreColor.token(CoreColors.onInfo),
        textColor: CoreColor.token(CoreColors.onInfo),
        descriptionColor: CoreColor.token(CoreColors.onInfo),
        focusOutlineStyle: CoreFocusOutlineStyle(
          offsetColor: CoreFocusRing.opaqueOffsetColor,
        ),
      ),
    },
    CoreBannerVariant.success: {
      CoreBannerEmphasis.weak: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.successContainer),
        borderColor: CoreColor.token(
          CoreColors.outline,
          fallbacks: [CoreColors.onSurface],
        ),
        iconColor: CoreColor.token(CoreColors.onSuccessContainer),
        textColor: CoreColor.token(CoreColors.onSuccessContainer),
        descriptionColor: CoreColor.token(
          CoreColors.onSurfaceVariant,
          fallbacks: [CoreColors.onSurface],
        ),
      ),
      CoreBannerEmphasis.solid: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.success),
        iconColor: CoreColor.token(CoreColors.onSuccess),
        textColor: CoreColor.token(CoreColors.onSuccess),
        descriptionColor: CoreColor.token(CoreColors.onSuccess),
        focusOutlineStyle: CoreFocusOutlineStyle(
          offsetColor: CoreFocusRing.opaqueOffsetColor,
        ),
      ),
    },
    CoreBannerVariant.warning: {
      CoreBannerEmphasis.weak: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.warningContainer),
        borderColor: CoreColor.token(
          CoreColors.outline,
          fallbacks: [CoreColors.onSurface],
        ),
        iconColor: CoreColor.token(CoreColors.onWarningContainer),
        textColor: CoreColor.token(CoreColors.onWarningContainer),
        descriptionColor: CoreColor.token(
          CoreColors.onSurfaceVariant,
          fallbacks: [CoreColors.onSurface],
        ),
      ),
      CoreBannerEmphasis.solid: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.warning),
        iconColor: CoreColor.token(CoreColors.onWarning),
        textColor: CoreColor.token(CoreColors.onWarning),
        descriptionColor: CoreColor.token(CoreColors.onWarning),
        focusOutlineStyle: CoreFocusOutlineStyle(
          offsetColor: CoreFocusRing.opaqueOffsetColor,
        ),
      ),
    },
    CoreBannerVariant.destructive: {
      CoreBannerEmphasis.weak: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.errorContainer),
        borderColor: CoreColor.token(
          CoreColors.outline,
          fallbacks: [CoreColors.onSurface],
        ),
        iconColor: CoreColor.token(CoreColors.onErrorContainer),
        textColor: CoreColor.token(CoreColors.onErrorContainer),
        descriptionColor: CoreColor.token(
          CoreColors.onSurfaceVariant,
          fallbacks: [CoreColors.onSurface],
        ),
      ),
      CoreBannerEmphasis.solid: CoreBannerVariantStyle(
        backgroundColor: CoreColor.token(CoreColors.error),
        iconColor: CoreColor.token(CoreColors.onError),
        textColor: CoreColor.token(CoreColors.onError),
        descriptionColor: CoreColor.token(CoreColors.onError),
        focusOutlineStyle: CoreFocusOutlineStyle(
          offsetColor: CoreFocusRing.opaqueOffsetColor,
        ),
      ),
    },
  };

  // ── Chrome (flat) ────────────────────────────

  /// Banner panel background fill colour.
  final CoreColor? backgroundColor;

  /// Foreground colour applied to the title / description / icon
  /// when the per-slot style does not override it.
  final CoreColor? foregroundColor;

  /// Bottom-rule colour. `null` suppresses the rule entirely.
  final CoreColor? borderColor;

  /// Bottom-rule thickness (logical px). `null` defers to
  /// [defaultBorderWidth]. See that constant for why the rule is
  /// bottom-only and why it must not add to the band's height.
  final double? borderWidth;

  /// Border radius. `null` defers to [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// Minimum band height (logical px). `null` defers to
  /// [defaultMinHeight].
  final double? minHeight;

  /// Padding. `null` defers to [defaultPadding].
  final CoreEdgeInsets? padding;

  /// Gap after the leading icon, and between the text column and an
  /// action that shares its line. `null` defers to
  /// [defaultIconContentGapStyle].
  ///
  /// The icon's gap is a `Gap`; the column-to-action gap is the wrapping
  /// body's own gap, so it is not drawn once the action has wrapped.
  final CoreGapStyle? iconContentGapStyle;

  /// Gap before the dismiss button — after the action, or after the text
  /// column when there is no action. `null` defers to
  /// [defaultContentDismissGapStyle].
  final CoreGapStyle? contentDismissGapStyle;

  /// Vertical gap between the title and the description, passed to the
  /// `Gap` between them. `null` defers to [defaultTitleDescriptionGapStyle].
  final CoreGapStyle? titleDescriptionGapStyle;

  /// Narrowest the message column may get while the trailing group sits
  /// beside it (logical px). Below it the trailing group moves to its own
  /// line under the message. `null` defers to [defaultContentMinWidth].
  final double? contentMinWidth;

  /// Vertical distance between the message column and the trailing
  /// group once the trailing group has moved to its own line (logical
  /// px). `null` defers to [defaultTrailingRunSpacing].
  final double? trailingRunSpacing;

  // ── Slot Styles (nested) ─────────────────────

  /// Title text style override.
  final CoreTextStyle? titleStyle;

  /// Description text style override.
  final CoreTextStyle? descriptionStyle;

  /// Leading icon style override.
  final CoreIconStyle? iconStyle;

  /// Look of the action (`action:`) button — colours, padding, corners.
  /// Laid over the banner variant's foreground colour, so fields set here
  /// win, and passed to the action as is when it is a `Button`.
  ///
  /// Both resolvers inject that variant foreground.
  final CoreButtonStyle? actionButtonStyle;

  /// Extra styling for an action that is a `plain` `Button` — laid over
  /// [actionButtonStyle] (and its default) for that variant only, and
  /// merged onto [defaultPlainActionButtonStyle]. A caller's
  /// [actionButtonStyle] still wins over the default here, so a padding
  /// stated there reaches every variant.
  final CoreButtonStyle? plainActionButtonStyle;

  /// Look of the close (`onDismiss`) button — colours, padding, corners.
  /// Laid over [defaultCloseButtonStyle] and the banner variant's
  /// foreground colour, then passed as is to
  /// `Button(variant: .plain, buttonStyle: …)` on both platforms.
  final CoreButtonStyle? closeButtonStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreBannerStyle merge(CoreBannerStyle? other) {
    if (other == null) return this;
    return CoreBannerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      minHeight: other.minHeight ?? minHeight,
      padding: other.padding ?? padding,
      iconContentGapStyle: _mergeGapStyle(
        iconContentGapStyle,
        other.iconContentGapStyle,
      ),
      contentDismissGapStyle: _mergeGapStyle(
        contentDismissGapStyle,
        other.contentDismissGapStyle,
      ),
      titleDescriptionGapStyle: _mergeGapStyle(
        titleDescriptionGapStyle,
        other.titleDescriptionGapStyle,
      ),
      contentMinWidth: other.contentMinWidth ?? contentMinWidth,
      trailingRunSpacing: other.trailingRunSpacing ?? trailingRunSpacing,
      titleStyle: _mergeText(titleStyle, other.titleStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      actionButtonStyle: _mergeButton(
        actionButtonStyle,
        other.actionButtonStyle,
      ),
      plainActionButtonStyle: _mergeButton(
        plainActionButtonStyle,
        other.plainActionButtonStyle,
      ),
      closeButtonStyle: _mergeButton(closeButtonStyle, other.closeButtonStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreBannerStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    double? minHeight,
    CoreEdgeInsets? padding,
    CoreGapStyle? iconContentGapStyle,
    CoreGapStyle? contentDismissGapStyle,
    CoreGapStyle? titleDescriptionGapStyle,
    double? contentMinWidth,
    double? trailingRunSpacing,
    CoreTextStyle? titleStyle,
    CoreTextStyle? descriptionStyle,
    CoreIconStyle? iconStyle,
    CoreButtonStyle? actionButtonStyle,
    CoreButtonStyle? plainActionButtonStyle,
    CoreButtonStyle? closeButtonStyle,
  }) {
    return CoreBannerStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      minHeight: minHeight ?? this.minHeight,
      padding: padding ?? this.padding,
      iconContentGapStyle: iconContentGapStyle ?? this.iconContentGapStyle,
      contentDismissGapStyle:
          contentDismissGapStyle ?? this.contentDismissGapStyle,
      titleDescriptionGapStyle:
          titleDescriptionGapStyle ?? this.titleDescriptionGapStyle,
      contentMinWidth: contentMinWidth ?? this.contentMinWidth,
      trailingRunSpacing: trailingRunSpacing ?? this.trailingRunSpacing,
      titleStyle: titleStyle ?? this.titleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      actionButtonStyle: actionButtonStyle ?? this.actionButtonStyle,
      plainActionButtonStyle:
          plainActionButtonStyle ?? this.plainActionButtonStyle,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBannerStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          minHeight == other.minHeight &&
          padding == other.padding &&
          iconContentGapStyle == other.iconContentGapStyle &&
          contentDismissGapStyle == other.contentDismissGapStyle &&
          titleDescriptionGapStyle == other.titleDescriptionGapStyle &&
          contentMinWidth == other.contentMinWidth &&
          trailingRunSpacing == other.trailingRunSpacing &&
          titleStyle == other.titleStyle &&
          descriptionStyle == other.descriptionStyle &&
          iconStyle == other.iconStyle &&
          actionButtonStyle == other.actionButtonStyle &&
          plainActionButtonStyle == other.plainActionButtonStyle &&
          closeButtonStyle == other.closeButtonStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    minHeight,
    padding,
    iconContentGapStyle,
    contentDismissGapStyle,
    titleDescriptionGapStyle,
    contentMinWidth,
    trailingRunSpacing,
    titleStyle,
    descriptionStyle,
    iconStyle,
    actionButtonStyle,
    plainActionButtonStyle,
    closeButtonStyle,
  ]);

  static CoreGapStyle? _mergeGapStyle(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

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
}

/// Visual style definition for one ([CoreBannerVariant],
/// [CoreBannerEmphasis]) pair.
///
/// Defines colours for: background, bottom rule, icon, title, and
/// description. All values are platform-neutral ([CoreColor]); the
/// consuming renderer converts at use-site (Flutter via
/// `scheme.resolve(...).toValue()`; Web via `'bg-${color}'` /
/// `var(--coui-*)`).
///
/// The background is always an **opaque container token**. The former
/// 10 %-alpha tint is gone: it put the tone's accent colour on top of a
/// wash of that same accent, so the label and its own background moved
/// together and the contrast could not be fixed by tuning the alpha.
@immutable
class CoreBannerVariantStyle {
  /// Creates a banner variant style.
  const CoreBannerVariantStyle({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.descriptionColor,
    this.borderColor,
    this.focusOutlineStyle,
  });

  /// Background colour.
  final CoreColor backgroundColor;

  /// Bottom-rule colour, or `null` when this pair draws no rule.
  ///
  /// Nullable rather than transparent-valued: a `solid` band has no rule
  /// at all, and saying so with `null` lets the resolver skip the stroke
  /// instead of painting an invisible one that still has to be laid out.
  final CoreColor? borderColor;

  /// Icon colour.
  ///
  /// Separate from [textColor] even though every entry currently gives
  /// them the same token — they are different surfaces (a glyph and a
  /// run of text), and `core/layer-mapping.md` keeps fields distinct
  /// when they are consumed in different places, so that one can be
  /// re-tuned without dragging the other with it.
  final CoreColor iconColor;

  /// Title colour. The action label and the dismiss glyph follow this
  /// same token — they are chrome belonging to the band, not to the
  /// message, so they read at title strength.
  final CoreColor textColor;

  /// Description colour.
  ///
  /// A separate field from [textColor] because the two part ways on every
  /// `weak` pair: the message keeps the tone's foreground and the
  /// description steps down to `onSurfaceVariant`. On a `solid` pair both
  /// carry the same token.
  final CoreColor descriptionColor;

  /// Focus-ring slot this pair lays under the band's close and action
  /// buttons, or `null` when the ring needs nothing beyond `Button`'s own.
  ///
  /// Only the `solid` pairs state one, and what they state is the ring's
  /// gap band (`CoreFocusRing.opaqueOffsetColor`). A solid band fills
  /// with the tone's own saturated colour — a colour the ring was never
  /// designed against — so the ring needs the two-colour band to keep a
  /// contrasting partner. A `weak` pair is a light container the ring
  /// already reads on, so it leaves the band transparent. Both resolvers
  /// merge this beneath the caller's `closeButtonStyle` /
  /// `actionButtonStyle`, so either can restate it.
  final CoreFocusOutlineStyle? focusOutlineStyle;
}
