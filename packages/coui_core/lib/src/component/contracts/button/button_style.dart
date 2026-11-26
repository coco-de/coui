/// Per-instance style for `Button`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/cast_motion.dart';
import 'package:coui_core/src/component/contracts/button/button_variant.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/hover/hover_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/dashed_border.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Button` should render.
///
/// `CoreButtonStyle` carries chrome / dimensional overrides as flat
/// fields and slot styling for label / leading / trailing icons as
/// nested `CoreTextStyle` / `CoreIconStyle` references — Epic #1302's
/// "atomic-style nesting" rule (slot Style is the same Style the
/// slot's own component already exposes).
///
/// **Semantic enums (`variant` / `size` / `shape`) live on the widget,
/// not on this style** (Epic #1302 원칙 6/7). They identify the button
/// instance and are passed as widget parameters; this style holds only
/// chrome / dimensional / nested-slot overrides on top of whichever
/// variant / size the widget was instantiated with.
///
/// ```text
/// design system default for variant
///   → CoreButtonTheme.style                       // 프로젝트 공통
///   → CoreButtonTheme.variantStyles[variant]      // variant 별 (lookup by widget.variant)
///   → parent component slot override
///       (e.g. CorePopoverStyle.triggerStyle when Button 이 popover trigger)
///   → widget.buttonStyle                          // 인스턴스별
/// ```
@immutable
class CoreButtonStyle implements CoreStyle<CoreButtonStyle> {
  /// Creates a [CoreButtonStyle].
  const CoreButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.hoverBackgroundColor,
    this.hoverForegroundColor,
    this.hoverBorderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.castMotion,
    this.dashedBorder,
    this.dashedBorderColor,
    this.dashLength,
    this.dashSpacing,
    this.height,
    this.width,
    this.minWidth,
    this.maxWidth,
    this.padding,
    this.iconLabelGapStyle,
    this.circleBorderRadius,
    this.iconShapePadding,
    this.animationDuration,
    this.castHideDuration,
    this.pressedScale,
    this.disableHoverEffect,
    this.stateLayer,
    this.focusOutlineStyle,
    this.labelStyle,
    this.leadingIconStyle,
    this.trailingIconStyle,
    this.iconShapeIconStyle,
  });

  // ═══════════════════════════════════════════════════
  // 2. Defaults — single (Epic #1601 PoC)
  // ═══════════════════════════════════════════════════
  //
  // Design-system defaults applied by `resolveButton` when neither
  // the theme nor the per-instance Style sets the matching prop. Each
  // const here is paired one-to-one with a prop on `CoreButtonStyle` —
  // the resolver does `merged.X ?? CoreButtonStyle.defaultX`. Single
  // source of truth shared by Flutter and Web (Phase 6f option D).

  /// A size-independent control corner (8), retired together with its
  /// twin [borderRadiusFor]: the design-system corner is the size row's
  /// [borderRadius] (`defaultsBySize[size].borderRadius`, the control
  /// height × 0.25), read through [borderRadiusForSize].
  @Deprecated(
    'Per-size now: read defaultsBySize[size].borderRadius through '
    'borderRadiusForSize instead (since 0.156) — the control corner is '
    'the control height of the size × 0.25, so one value cannot answer '
    'for every size.',
  )
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default for [dashedBorderColor] — muted `onSurface × 30% alpha`
  /// outline, expressed as a `CoreColor.token(slot, opacity)` so the
  /// alpha rides on the token reference instead of an inline ARGB.
  static const CoreColor defaultDashedBorderColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.opacity30,
  );

  /// Default for [animationDuration] — chrome state transitions
  /// (hover / focus / pressed).
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default for [castHideDuration] — the engage-squash pair's shared
  /// clock (the shadow hide and the travel move together, #4407). Kept
  /// apart from [defaultAnimationDuration] deliberately: pairing a hide
  /// with a travel needs one clock, and that clock is not the chrome
  /// transition speed.
  static const Duration defaultCastHideDuration = Duration(
    milliseconds: CoreDuration.ms50,
  );

  /// Default for [pressedScale] — how far a pressed button shrinks.
  ///
  /// The same factor the hover `scaleDown` effect uses rather than a
  /// second copy of the number: both say "this control is being pushed",
  /// so a change to that feel moves them together. It is the value the
  /// Flutter button already shrank to on mobile before both platforms
  /// read it from here.
  ///
  /// Only the press wears it. A style whose engage vocabulary is a shift
  /// into the cast (`CoreSurfaceGeometryConstraint.shadowOffsetAdd`)
  /// pins the scale to `1.0` on a button that casts, on both platforms,
  /// so the two affordances never compound.
  static const double defaultPressedScale =
      CoreHoverStyle.defaultScaleDownFactor;

  /// Default for [castMotion] — what the cast does when engaged.
  ///
  /// [CoreCastMotion.defaultMotion] so a button that says nothing still
  /// reads like the rest of the kit under a style that casts. Opting
  /// *out* is the statement worth making explicit.
  static const CoreCastMotion defaultCastMotion = .defaultMotion;

  /// Default for [dashedBorder] — solid border unless the user opts in.
  static const bool defaultDashedBorder = false;

  /// Default dash segment length — the shared [CoreDashedBorder]
  /// baseline, rendered identically by the Flutter dash painter and the
  /// Web SVG `stroke-dasharray` overlay.
  static const double defaultDashLength = CoreDashedBorder.dashLength;

  /// Default gap between dash segments — see [defaultDashLength].
  static const double defaultDashSpacing = CoreDashedBorder.dashGap;

  /// Default for [disableHoverEffect] — hover visuals on by default.
  static const bool defaultDisableHoverEffect = false;

  /// Default nested [CoreGapStyle] slot — `CoreGapStyle(size: 8)` —
  /// for the gap between leading icon / label / trailing icon inside
  /// the content wrapper. Both resolvers prefer the size row's own
  /// `iconLabelGapStyle` in [defaultsBySize] — the ladder lives there,
  /// one value per size, and is not restated here so the two cannot
  /// drift; this flat default is the fallback when callers construct a
  /// [CoreButtonStyle] outside the size-default flow. The whole nested
  /// [CoreGapStyle] slot is forwarded to the `Gap` widget that
  /// separates the slots. Per-instance override flows through
  /// [iconLabelGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultIconLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default for [circleBorderRadius] — pill radius for
  /// `CoreButtonShape.circle`. The shape enum lives on the widget; this
  /// default is the value the resolver uses to paint the circle when the
  /// per-instance [circleBorderRadius] override is unset.
  static const CoreBorderRadius defaultCircleBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default for [iconShapePadding] — zero padding for
  /// `CoreButtonShape.square` / `CoreButtonShape.circle` so both shapes
  /// collapse to a tight icon container when the per-instance
  /// [iconShapePadding] override is unset.
  static const CoreEdgeInsets defaultIconShapePadding = .zero;

  /// Default focus-outline style — fully filled slot the resolver
  /// uses as the base before merging the per-instance
  /// [focusOutlineStyle] override on top. Single slot pairs 1:1 with
  /// the instance field above.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        align: CoreFocusOutlineStyle.defaultAlign,
        borderColor: CoreFocusOutlineStyle.defaultBorderColor,
        borderWidth: CoreFocusOutlineStyle.defaultBorderWidth,
        offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
      );

  // ═══════════════════════════════════════════════════
  // 3. Defaults — size-keyed
  // ═══════════════════════════════════════════════════

  /// Per-size default chrome — single source of truth shared by
  /// Flutter and Web.
  ///
  /// The map value is `CoreButtonStyle` itself so the flat slot
  /// fields stay 1:1 with the per-size defaults — no separate
  /// typedef record holder (contract.md "defaultsBySize 값은
  /// CoreXxxStyle 자체"). Both resolvers read
  /// `CoreButtonStyle.defaultsBySize[size]!` and consume the entries
  /// as `CoreButtonStyle` slots.
  ///
  /// Flutter reads the `double` / `CoreEdgeInsets` / `CoreIconStyle`
  /// fields directly (logical px); Web converts spacing to inline
  /// CSS via `rem` and emits `text-<token>` Tailwind classes for
  /// typography — both platforms read the same entries.
  static const Map<CoreComponentSize, CoreButtonStyle> defaultsBySize = {
    // Heights reference `CoreControlSize` directly — the semantic
    // row-alignment contract (the control row ladder). The glyph beside a
    // label is 12 · 14 · 16 · 18 · 20 · 24 and the glyph of a square or
    // circle button (`iconShapeIconStyle`, the button with no label to
    // sit beside) is 14 · 16 · 18 · 20 · 24 · 28. Horizontal padding is
    // 8 · 12 · 16 · 20 · 24 · 28 and the icon↔label gap is 4 · 6 · 6 · 6 ·
    // 8 · 8 — exported to Figma as `button/padding-x-*` / `button/icon-*` /
    // `button/icon-shape-*` / `button/gap-*`. Vertical padding is the one
    // cadence value the ladder leaves alone; what bounds it is the label's
    // line box fitting the height (the `xs` and `sm` entries).
    //
    // `borderRadius` is the control height × 0.25 on every row — 6 · 8 ·
    // 10 · 12 · 14 · 16, each a `CoreRadius` rung (디자이너 결정
    // 2026-10-08). One ratio rather than one value: a fixed corner makes
    // the small sizes read rounder than the large ones (r/h 0.33 at `xs`
    // against 0.125 at `xl2`), and a ladder whose steps do not track the
    // height jumps the ratio between rungs. The ratio itself is pinned by
    // a Core test against `CoreControlSize`. A variant that states its
    // own `CoreButtonVariantStyle.radius` wins over the row —
    // `borderRadiusForSize` is the one place that precedence lives, and
    // both resolvers call it.
    CoreComponentSize.xs: CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      height: CoreControlSize.heightXs,
      // Vertical `space2`, not `space4` — the same arithmetic as the `sm`
      // entry below, one rung down. The label is `labelSmall`, 12px on
      // the label line of 1.4, so a 16.8px line box, and `heightXs` is
      // 24. At `space4` the content needs 4 + 16.8 + 4 = 24.8, and
      // Flutter, which applies the height token as a minimum, grows the
      // button past the 24 its row promises. At `space2` it needs 20.8.
      // Web centres the label in a fixed `h-size24` box either way.
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space8,
        vertical: CoreSpace.space2,
      ),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
      // `labelSmall` (12): above the 10px floor a label is read at, and a
      // step under `sm`'s `labelMedium` (13) so the ladder does not repeat
      // its first rung. It fits the 24 row on the `space2` padding above.
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size12),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size12),
      iconShapeIconStyle: CoreIconStyle(size: CoreIconSize.size14),
    ),
    CoreComponentSize.sm: CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      height: CoreControlSize.heightSm,
      // Vertical `space4`, and the three numbers on this entry are the
      // check every rung has to pass. The label is `labelMedium` — 13px
      // on the label line of 1.4, so an 18.2px line box — and
      // `heightSm` is 32; at `space4` the content box is 32 − 8 = 24 and
      // the line fits with 5.8 to spare. Flutter applies the height
      // token as a MINIMUM, so a padding that leaves the content box
      // shorter than the line box grows the button past the TextField
      // beside it, which `CoreControlSize` exists to promise. `xs` above
      // is the rung where the check binds.
      //
      // Padding is the lever because the other two are not available:
      // the height is the shared control contract, and tightening the
      // label's line-height is what `widget/render-only.md` forbids
      // ("label 텍스트의 line-height 를 override 하지 않는다") since the
      // token default is what keeps the two platforms agreeing.
      //
      // Web renders the same height whatever the padding — its button is
      // a fixed `h-size32` flex box with `items-center`, so the label is
      // centred in the same 32px. Keeping the content box at least the
      // line box is what keeps Flutter on Web's number.
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space4,
      ),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size14),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size14),
      iconShapeIconStyle: CoreIconStyle(size: CoreIconSize.size16),
    ),
    CoreComponentSize.md: CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      height: CoreControlSize.heightMd,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space16,
        vertical: CoreSpace.space8,
      ),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      iconShapeIconStyle: CoreIconStyle(size: CoreIconSize.size18),
    ),
    CoreComponentSize.lg: CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      height: CoreControlSize.heightLg,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space20,
        vertical: CoreSpace.space10,
      ),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      // `labelXl2` (16). The label ladder is 12 / 13 / 14 / 16 / 16 / 16
      // — the 13 · 14 · 16 the design's buttons are drawn at, with `xs`
      // one step under `sm`, and flat above `lg`: a control taller than
      // 48 grows its padding and icon, not its label. Fits with slack —
      // 16 × 1.4 = 22.4px in a 48 − 2×10 = 28px content box.
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXl2),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size18),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size18),
      iconShapeIconStyle: CoreIconStyle(size: CoreIconSize.size20),
    ),
    CoreComponentSize.xl: CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      height: CoreControlSize.heightXl,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space24,
        vertical: CoreSpace.space12,
      ),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXl2),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size20),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size20),
      iconShapeIconStyle: CoreIconStyle(size: CoreIconSize.size24),
    ),
    // xl2 — height (64), icon (24), padding-x (28), gap (8) and radius
    // (16) are all rungs of their ladders; typography stays flat at the xl
    // tier (judgment call, unregulated).
    CoreComponentSize.xl2: CoreButtonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      height: CoreControlSize.heightXl2,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space28,
        vertical: CoreSpace.space14,
      ),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXl2),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size24),
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size24),
      iconShapeIconStyle: CoreIconStyle(size: CoreIconSize.size28),
    ),
  };

  /// The design-system corner radius for a `size` × `variant` cell —
  /// [variantRadius] (the variant row's own [CoreButtonVariantStyle.radius])
  /// when non-null, else the size row's [borderRadius]: the control height
  /// of [size] × 0.25 (see [defaultsBySize]).
  ///
  /// One function rather than a `??` chain in each resolver so the
  /// variant-beats-size precedence cannot drift between the Flutter and
  /// Web resolvers; they pass the variant value in (rather than the enum)
  /// so the read of that override field is visible where the resolver
  /// guard looks for it. Both parameters are required: a corner asked for
  /// without its size has no answer, and a resolver that forgot to pass
  /// one should not compile.
  static CoreBorderRadius borderRadiusForSize({
    required CoreComponentSize size,
    required double? variantRadius,
  }) {
    if (variantRadius != null) return CoreBorderRadius.all(variantRadius);
    return defaultsBySize[size]!.borderRadius!;
  }

  /// The corner for a `variant` without a size — [variantRadius] when
  /// non-null, else the size-independent [defaultBorderRadius] (8).
  ///
  /// Retired with [defaultBorderRadius] as one unit, and answering what it
  /// always answered through the deprecation window, so a caller keeps its
  /// value until it moves to [borderRadiusForSize].
  @Deprecated(
    'Takes the size now: call borderRadiusForSize(size:, variantRadius:) '
    'instead (since 0.156) — the control corner is the control height of '
    'the size × 0.25, so a corner without a size has no answer.',
  )
  static CoreBorderRadius borderRadiusFor({required double? variantRadius}) {
    if (variantRadius != null) return CoreBorderRadius.all(variantRadius);
    return defaultBorderRadius;
  }

  /// The design-system content padding for a `size` × `variant` cell —
  /// the size ladder's insets, with the inline (start/end) pair replaced
  /// by [paddingInline] (the variant row's
  /// [CoreButtonVariantStyle.paddingInline]) when the variant states
  /// one. `plain` states `0`: an inline affordance sits flush with the
  /// text around it, and the size ladder's inline padding would push it off
  /// that baseline (2026-09-08 §5 "plain padding-inline 0"). The block
  /// (top/bottom) pair is always the size's — the row height contract is
  /// not the variant's to bend.
  static CoreEdgeInsets paddingFor({
    required CoreComponentSize size,
    required double? paddingInline,
  }) {
    final sizePadding = defaultsBySize[size]!.padding!;
    if (paddingInline == null) return sizePadding;
    return sizePadding.copyWith(left: paddingInline, right: paddingInline);
  }

  /// The size a button's glyphs draw at for a `size` cell — the one place
  /// the order of the sources lives, so the Flutter and Web resolvers
  /// cannot read it in a different one.
  ///
  /// A button with a label ([iconShaped] `false`) reads the size row's
  /// [leadingIconStyle]; a `square` / `circle` button ([iconShaped]
  /// `true`) has no label to sit beside and reads the row's
  /// [iconShapeIconStyle], a step larger. In either, what the caller
  /// stated wins over the row: [iconShapeOverride] (only for an
  /// [iconShaped] button), then [leadingOverride], then [trailingOverride].
  /// A caller that sizes a shaped button's glyph through the slot style
  /// therefore keeps that size.
  static double iconSizeFor({
    required CoreComponentSize size,
    required bool iconShaped,
    required CoreIconStyle? iconShapeOverride,
    required CoreIconStyle? leadingOverride,
    required CoreIconStyle? trailingOverride,
  }) {
    final row = defaultsBySize[size]!;
    return (iconShaped ? iconShapeOverride?.size : null) ??
        leadingOverride?.size ??
        trailingOverride?.size ??
        (iconShaped ? row.iconShapeIconStyle! : row.leadingIconStyle!).size!;
  }

  /// The label's text style for a `size` × `variant` cell — the size row's
  /// role, the variant's weight on top of it, and whatever the theme or
  /// the instance states last. The one place that order lives; both
  /// resolvers call it, so the Flutter and Web labels cannot come out
  /// with different weights.
  ///
  /// The variant's statement ([variantLabelStyle], the variant row's
  /// [CoreButtonVariantStyle.labelStyle]) contributes its
  /// [CoreTextStyle.fontWeight] and nothing else: the variant row states
  /// how heavy its label is, and the size row's role owns the rest of the
  /// label (size, line box, tracking), so a size, a line box or a colour
  /// stated on the variant's slot is not read here.
  ///
  /// The weight is the part of the order that needs a rule:
  /// [CoreTextStyle.merge] keeps the earlier `fontWeight` when the later
  /// style states a role without one, so a composer that states only a role
  /// (`Calendar` draws its day cells as a `body` role) would still wear the
  /// variant's 600 on top of it. A composer that states a role token or a
  /// weight has said what its label is, so the variant's weight steps
  /// aside; one that states neither (a colour, a size) leaves the weight to
  /// the variant.
  static CoreTextStyle labelStyleFor({
    required CoreComponentSize size,
    required CoreTextStyle? variantLabelStyle,
    required CoreTextStyle? labelStyle,
  }) {
    final role = defaultsBySize[size]!.labelStyle!;
    final variantWeight = variantLabelStyle?.fontWeight;
    final composerStatesLabel =
        labelStyle != null &&
        (labelStyle.token != null || labelStyle.fontWeight != null);
    final base = variantWeight == null || composerStatesLabel
        ? role
        : role.copyWith(fontWeight: variantWeight);
    return base.merge(labelStyle);
  }

  // ═══════════════════════════════════════════════════
  // 4. Defaults — variant-keyed
  // ═══════════════════════════════════════════════════

  /// Per-variant default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  ///
  /// Variants whose `backgroundColor` / `hoverBackgroundColor` /
  /// `disabledBackgroundColor` are `CoreColor.transparent` represent the
  /// no-fill case — Web omits the Tailwind class, Flutter resolves to a
  /// fully-transparent `Color`.
  static const Map<CoreButtonVariant, CoreButtonVariantStyle>
  defaultsByVariant = {
    // A button answers hover and pressed in one of two ways, and a
    // variant states one and never both.
    //
    // **Filled** (`primary`, `destructive`): swap the CONTAINER — hover to
    // the `*Hover` / `errorStrong` step, pressed to the `*Pressed` step —
    // the opaque token-swap model (Button · Menu redesign 2026-09-08 §3 /
    // §5: "filled variants use container colour swap"). The steps are the
    // Figma `color/primary-hover` … `error-pressed` variables measured per
    // mode (`CoreSemanticMapping`), so this file does not know the
    // direction the walk takes — only that it is a different opaque
    // colour.
    //
    // **Tonal or unfilled** (`secondary`, `tonal`, `outline`, `ghost`): keep
    // the resting look and lay the variant's own foreground over it at the
    // `stateLayer` ramp's weights.
    //
    // Stating both is a defect, not a belt-and-braces: a wash over an
    // already-swapped fill would darken twice, and on Web the
    // `color-mix()` rule would win over the swapped class by specificity
    // and hide it. `stateLayer` is therefore left unset on the swappers
    // on purpose.
    //
    // **Focus is neither.** A focused button wears its resting look plus
    // the focus ring, on every variant that does not fold focus into hover
    // (`menu`, `menubar`). The ring is the focus indicator; a wash that
    // adds 8% of the label colour does not clear the 3:1 change WCAG 2.4.13
    // asks of one, so it is not drawn as a second, weaker one.
    //
    // **No variant states a label weight.** Every label is the size row's
    // label role (`labelSmall` … `labelXl2`, medium), so a button's label is
    // drawn at the same weight as every other label of its size — and the
    // canvas keeps the role's text style on it, which a variant weight laid
    // over the role would detach. [CoreButtonVariantStyle.labelStyle] stays
    // as the seat for a variant that needs one.
    //
    // **Disabled label and icon are `disabledContent` on every variant** —
    // not `onSurfaceVariant`, which is the enabled secondary-text colour
    // and so told a disabled control apart from an enabled quiet one by
    // nothing but its fill.
    CoreButtonVariant.primary: CoreButtonVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
      foregroundColor: CoreColor.token(CoreColors.onPrimary),
      hoverBackgroundColor: CoreColor.token(CoreColors.primaryHover),
      pressedBackgroundColor: CoreColor.token(CoreColors.primaryPressed),
      disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
    ),
    // A pale fill, not a second dark one: with primary and secondary both
    // on a dark neutral step the two measured 1.02 : 1 (light) and 1.00 : 1
    // (dark) against each other, and most places that reach for secondary
    // are a "cancel" that has to read as the quieter of the pair.
    //
    // The fill does not change on hover or pressed. The variant is an
    // unfilled-weight control in how it responds — it lays its own
    // foreground over itself at the `subtle` ramp's hover and pressed
    // weights, exactly as `outline` does — so `hoverBackgroundColor` is the
    // resting fill and the `*Hover` / `*Pressed` secondary scheme slots stay
    // in the scheme but are read by no Button.
    CoreButtonVariant.secondary: CoreButtonVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.secondaryContainer),
      foregroundColor: CoreColor.token(CoreColors.onSecondaryContainer),
      hoverBackgroundColor: CoreColor.token(CoreColors.secondaryContainer),
      stateLayer: CoreStateLayer.subtle,
      disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
    ),
    // `secondary`'s structure with the brand container pair in place of the
    // neutral one: a pale `primaryContainer` fill and an `onPrimaryContainer`
    // label — one step quieter than `primary`, one step more branded than
    // `secondary` (the supporting action inside a card). Like `secondary`
    // the fill does not change on hover or pressed; the label colour is laid
    // over it at the `subtle` ramp's weights (3% / 12%, the Figma
    // `Variant=tonal` state layer), focus is the resting look plus the ring,
    // and disabled is the shared `disabledContainer` / `disabledContent`
    // pair. No stroke in any state — the fill is the boundary.
    CoreButtonVariant.tonal: CoreButtonVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.primaryContainer),
      foregroundColor: CoreColor.token(CoreColors.onPrimaryContainer),
      hoverBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
      stateLayer: CoreStateLayer.subtle,
      disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
    ),
    // Tinted at rest, filled under the pointer: `errorContainer` /
    // `onErrorContainer` at rest (focus and selected are the resting look),
    // `error` / `onError` on hover, `errorPressed` / `onError` on press. The
    // resting tint keeps a destructive action from being the loudest button
    // on the screen; the solid `error` fill appears only while the pointer
    // engages it.
    //
    // Each state is a distinct pre-authored colour, not an alpha wash
    // (`CoUI_Button_State_Layer_Decision.md` §5/§9): `error` / `onError`
    // share the family with only a few slots, so a computed tint toward the
    // page is where contrast actually fails. `onErrorContainer` on
    // `errorContainer` and `onError` on `error` / `errorPressed` are pairs
    // `tool/check_contrast.dart` audits in all four modes, so the 4.5 : 1
    // floor is measured on every build rather than restated here.
    //
    // No stroke in any state, disabled included: a boundary the fill
    // already supplies is a second, fainter one. The label changes colour
    // with the fill, so hover and pressed both state `onError`: a keyboard
    // press is `:active` without `:hover` on the Web, and a pressed label
    // left to the hover fallback would there keep the resting
    // `onErrorContainer` on the `errorPressed` fill. The icon colours fall
    // through to the foreground.
    CoreButtonVariant.destructive: CoreButtonVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.errorContainer),
      foregroundColor: CoreColor.token(CoreColors.onErrorContainer),
      hoverBackgroundColor: CoreColor.token(CoreColors.error),
      hoverForegroundColor: CoreColor.token(CoreColors.onError),
      pressedBackgroundColor: CoreColor.token(CoreColors.errorPressed),
      pressedForegroundColor: CoreColor.token(CoreColors.onError),
      disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
    ),
    // rest is solid `surface`, not a translucent `surfaceContainer` wash —
    // the boundary is entirely the stroke below; the fill only needs to
    // opt the button out of the page's own colour, and a translucent fill
    // reads as a *second*, fainter boundary next to the real one. Hover/
    // pressed leave that fill untouched too and rely on the
    // `foregroundColor`-tinted state-layer overlay (`stateLayer`) — the
    // same wash `secondary` and `ghost` use.
    CoreButtonVariant.outline: CoreButtonVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
      foregroundColor: CoreColor.token(CoreColors.onSurface),
      hoverBackgroundColor: CoreColor.token(CoreColors.surface),
      stateLayer: CoreStateLayer.subtle,
      disabledBackgroundColor: CoreColor.token(CoreColors.outline, opacity: 0),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
      // Border properties reference a *border* alias, never a surface one.
      // These used to point at `surfaceContainer` — the same slot the fill
      // uses — so on any page whose background is itself `surfaceContainer`
      // the fill, the border and the page all collapsed to one colour and the
      // button lost its shape entirely (measured 1.004:1 in a consumer app).
      //
      // `outlineVariant`, the pale boundary (designer decision 2026-10-23,
      // the published Figma `Variant=outline` set): the label inside already
      // says "this is a button", so the stroke only has to mark where the
      // control ends, not carry the affordance. Every enabled state — rest,
      // hover, focus, pressed, selected — wears the same stroke; disabled
      // keeps `disabledOutline`. This trades the WCAG 1.4.11 3:1 the
      // `outline` slot cleared for a quieter edge: the label, not the
      // stroke, is the part a reader has to find.
      borderColor: CoreColor.token(CoreColors.outlineVariant),
      hoverBorderColor: CoreColor.token(CoreColors.outlineVariant),
      disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
      borderWidth: CoreStrokeWidth.stroke1,
    ),
    // rest fill is transparent, but hover/pressed still go through the
    // same `stateLayer` overlay `secondary`/`outline` use above — NOT a
    // plain translucent `hoverBackgroundColor` CoreColor.
    // `color-mix()`/`Color.alphaBlend` both weight a fully-transparent
    // base correctly (its 0 alpha contributes nothing, so the composited
    // result is exactly `onSurface` at the overlay's own opacity — the
    // intended page-composited translucent look), so reusing the shared
    // mechanism is both correct and not a special case.
    //
    // A plain `CoreColor.token(onSurface, opacity: 0.03)` in
    // `hoverBackgroundColor` was tried first and looked identical in the
    // Flutter build check, but silently painted nothing on Web: Tailwind's
    // opacity-modifier class (`hover:bg-on-surface/3`) only generates for
    // percentages on Tailwind's own default opacity scale (0/5/10/20/25/
    // 30/40/50/60/70/75/80/90/95/100) — 3 and 12 are not on it, so the
    // class silently never gets JIT-compiled (no error, no class, no
    // paint). Every opacity value used anywhere else in this file before
    // this happened to land on that scale, so the gap was never hit.
    // `stateLayer` never touches Tailwind's class scale at all (its value is
    // interpolated straight into a scoped `color-mix()` rule), so it has no
    // such ceiling.
    CoreButtonVariant.ghost: CoreButtonVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer, opacity: 0),
      foregroundColor: CoreColor.token(CoreColors.onSurface),
      hoverBackgroundColor: CoreColor.token(
        CoreColors.surfaceContainer,
        opacity: 0,
      ),
      stateLayer: CoreStateLayer.subtle,
      disabledBackgroundColor: CoreColor.token(
        CoreColors.surfaceContainer,
        opacity: 0,
      ),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
    ),
    // rest reads `onSurfaceVariant` at full opacity — not `onSurface` diluted
    // to 70% alpha. Same B1→opaque-token direction as `destructive` above:
    // the muted look comes from a distinct, pre-authored token, not from
    // compositing toward whatever page sits behind the (fill-less) button.
    // pressed has no dedicated slot because Figma's pressed instance repeats
    // hover's own label colour verbatim (`onSurface`) — the existing
    // `pressedForegroundColor ?? hoverForegroundColor` fallback already
    // lands there.
    //
    // Disabled fill stays transparent — an opaque `disabledContainer` pill
    // on a chrome-less control is the defect (#4553). Hover (`onSurface`) is
    // the enabled-only signal; focus is the resting look plus the ring.
    CoreButtonVariant.plain: CoreButtonVariantStyle(
      backgroundColor: .transparent,
      foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
      hoverBackgroundColor: .transparent,
      disabledBackgroundColor: .transparent,
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
      hoverForegroundColor: CoreColor.token(CoreColors.onSurface),
      // Flush with the surrounding text — see `paddingFor`.
      paddingInline: CoreSpace.space0,
    ),
    // Menu-item affordance (dropdown / context / menubar rows). The
    // highlight is the neutral `surfaceContainerHighest` fill with the
    // foreground left at `onSurface` — the conventional subtle menu
    // highlight, matching the standalone `Menu`'s `defaultHoverColor`
    // (a filled `tertiary`/`onTertiary` swap reads as an accent, not a
    // menu hover, and diverged from `Menu`).
    CoreButtonVariant.menu: CoreButtonVariantStyle(
      // Resting fill is the hover colour at zero alpha (not the shared
      // `transparent` = transparent *black* sentinel) so the hover
      // `AnimatedContainer` lerps alpha 0 → 1 within the same grey hue
      // instead of passing through a dark semi-transparent black on the
      // way (the "darkens then lightens" hover flicker). Same fix the
      // Popover shadow uses; also keeps the CSS `:hover` transition on Web
      // out of the `transparent`-keyword black-interpolation trap.
      backgroundColor: CoreColor.token(
        CoreColors.surfaceContainerHighest,
        opacity: 0,
        fallbacks: [CoreColors.surfaceContainerHigh],
      ),
      foregroundColor: CoreColor.token(CoreColors.onSurface),
      hoverBackgroundColor: CoreColor.token(
        CoreColors.surfaceContainerHighest,
        fallbacks: [CoreColors.surfaceContainerHigh],
      ),
      disabledBackgroundColor: .transparent,
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
      iconColor: CoreColor.token(CoreColors.onSurface),
      hoverForegroundColor: CoreColor.token(CoreColors.onSurface),
      hoverIconColor: CoreColor.token(CoreColors.onSurface),
      // Selected = the "current / active" menu item (e.g. the open
      // navigation entry). A `primary` fill with `onPrimary` text — the
      // single source for `Menu`'s active row, which composes
      // `Button(variant: menu, selected: item.active)`.
      selectedBackgroundColor: CoreColor.token(CoreColors.primary),
      selectedForegroundColor: CoreColor.token(CoreColors.onPrimary),
      focusedBackgroundColor: CoreColor.token(
        CoreColors.surfaceContainerHighest,
        fallbacks: [CoreColors.surfaceContainerHigh],
      ),
      useSelectedState: true,
      useFocusedAsHover: true,
    ),
    CoreButtonVariant.menubar: CoreButtonVariantStyle(
      // Resting fill is the hover colour at zero alpha (see `menu` above)
      // so the hover transition lerps alpha within the grey hue instead of
      // through a dark semi-transparent black (the hover flicker).
      backgroundColor: CoreColor.token(
        CoreColors.surfaceContainerHighest,
        opacity: 0,
        fallbacks: [CoreColors.surfaceContainerHigh],
      ),
      foregroundColor: CoreColor.token(CoreColors.onSurface),
      hoverBackgroundColor: CoreColor.token(
        CoreColors.surfaceContainerHighest,
        fallbacks: [CoreColors.surfaceContainerHigh],
      ), // Open-state highlight — a top-level menubar / navigation trigger
      disabledBackgroundColor: .transparent,
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
      iconColor: CoreColor.token(CoreColors.onSurface),
      hoverForegroundColor: CoreColor.token(CoreColors.onSurface),
      hoverIconColor: CoreColor.token(CoreColors.onSurface),
      // Open-state highlight — a top-level menubar trigger stays
      // highlighted while its menu is open (not just on hover). The
      // consumer forces `WidgetState.selected` (Flutter `statesController`
      // / Web `aria-selected`). The fill is one step softer than the hover
      // fill, so an open trigger reads as settled rather than pointed at.
      selectedBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
      focusedBackgroundColor: CoreColor.token(
        CoreColors.surfaceContainerHighest,
        fallbacks: [CoreColors.surfaceContainerHigh],
      ),
      useSelectedState: true,
      useFocusedAsHover: true,
    ),
    CoreButtonVariant.fixed: CoreButtonVariantStyle(
      backgroundColor: .transparent,
      foregroundColor: CoreColor.token(CoreColors.onSurface),
      hoverBackgroundColor: .transparent,
      disabledBackgroundColor: .transparent,
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
    ),
  };

  // ═══════════════════════════════════════════════════
  // 5. Props — chrome (colour / border / radius)
  // ═══════════════════════════════════════════════════

  /// Background fill colour override.
  final CoreColor? backgroundColor;

  /// Foreground (label / icon) colour override. A colour set in
  /// [leadingIconStyle] / [trailingIconStyle] wins over it for that icon.
  final CoreColor? foregroundColor;

  /// Border stroke colour override.
  final CoreColor? borderColor;

  /// Hover background fill colour override. `null` → the variant's
  /// `hoverBackgroundColor`. Mirrors [backgroundColor] for the hovered state
  /// so the hover colour can be set per button, not only per variant.
  final CoreColor? hoverBackgroundColor;

  /// Hover foreground (label / icon) colour override. `null` → the
  /// variant's `hoverForegroundColor` (else idle foreground).
  final CoreColor? hoverForegroundColor;

  /// Hover border stroke colour override. `null` → the variant's
  /// `hoverBorderColor` (else idle border colour).
  ///
  /// Hover **icon** colour is intentionally not a flat field here — icon
  /// chrome flows through the [leadingIconStyle] / [trailingIconStyle]
  /// (`CoreIconStyle`) slots, and the hovered icon falls through to
  /// [hoverForegroundColor] (mirrors how the idle icon follows
  /// [foregroundColor]).
  final CoreColor? hoverBorderColor;

  /// Border stroke width override (logical px, pre-scaling).
  final double? borderWidth;

  /// Border radius override for the rectangle and square shapes. `null` →
  /// the variant's own [CoreButtonVariantStyle.radius], else the size
  /// row's corner (the control height × 0.25) — [borderRadiusForSize].
  final CoreBorderRadius? borderRadius;

  /// Drop-shadow / elevation override. `null` → no shadow (buttons are
  /// flat by default); a non-null layer list paints an elevation behind
  /// the surface — used by composing components such as `Fab` that need
  /// a floating elevation on an otherwise plain button surface.
  ///
  /// **No `defaultBoxShadow`, deliberately.** Absence *is* the flat
  /// surface. Flutter hands the null straight to
  /// `BoxDecoration.boxShadow`, where null means paint nothing, and Web
  /// writes `box-shadow` only inside `if (merged.boxShadow != null)`.
  /// A non-null default freezes both branches the same way: every
  /// button in the kit would carry an elevation, and `Fab` would lose
  /// the one thing that distinguishes it from the plain surface it
  /// composes.
  final List<CoreShadowLayer>? boxShadow;

  /// What this button's cast does when the button is engaged.
  ///
  /// Sits beside [boxShadow] rather than on the widget because it is a
  /// statement about the surface, not about which button this is — the
  /// same reasoning that puts `CoreCardStyle.elevation` here. `variant`
  /// and `size` say what the control *is*; this says how its surface
  /// behaves, which is chrome.
  ///
  /// Null takes [defaultCastMotion].
  final CoreCastMotion? castMotion;

  /// Whether to render a dashed border instead of a solid one.
  final bool? dashedBorder;

  /// Dashed border stroke colour override. Falls back to
  /// [borderColor] when null.
  final CoreColor? dashedBorderColor;

  /// Dash segment length when [dashedBorder] is true (logical px).
  /// `null` → [defaultDashLength].
  final double? dashLength;

  /// Gap between dash segments (logical px). `null` → [defaultDashSpacing].
  final double? dashSpacing;

  // ═══════════════════════════════════════════════════
  // 6. Props — dimensions (size / padding / gap)
  // ═══════════════════════════════════════════════════

  /// Fixed height override (logical px).
  final double? height;

  /// Fixed width override (logical px).
  ///
  /// **No `defaultWidth`, deliberately.** `null` is the "hug content"
  /// signal rather than a value nobody got round to choosing: Flutter
  /// wraps the button in a `SizedBox(width:)` only when the effective
  /// width is non-null (`expanded` is what supplies `double.infinity`
  /// there), and Web writes `width` only inside
  /// `if (merged.width != null)`. Any default pins every button to one
  /// fixed width and leaves `expanded` as the only route back to
  /// content-sized.
  final double? width;

  /// Minimum width constraint (logical px).
  ///
  /// **No `defaultMinWidth`, deliberately — and `0` is not a value to
  /// lift into one.** Flutter's `?? 0` is `BoxConstraints`' spelling of
  /// "no minimum" (that field cannot be null); Web omits the
  /// declaration. Those two agree, but `min-width: 0` does *not* agree
  /// with either: the root is `inline-flex`, so as a flex item it takes
  /// `min-width: auto` — the automatic content-based minimum — and
  /// emitting `0rem` in its place would let a button be squeezed
  /// narrower than its own label inside a tight flex row.
  final double? minWidth;

  /// Maximum width constraint (logical px).
  ///
  /// **No `defaultMaxWidth`, deliberately — and `double.infinity` is not
  /// a value to lift into one.** It is Flutter's spelling of "no cap"
  /// (`BoxConstraints.maxWidth` cannot be null) and it has no Web
  /// spelling at all: the base className clamps the inline-flex box with
  /// `max-width: 100%`, and the inline emit inside
  /// `if (merged.maxWidth != null)` *replaces* that parent-relative
  /// clamp with a fixed rem. A default would cap every button at an
  /// absolute width and remove the clamp that lets it shrink into a
  /// narrow pane.
  final double? maxWidth;

  /// Padding override.
  ///
  /// May be directional ([CoreEdgeInsets.directional]): a composing
  /// component whose two horizontal insets differ because of what sits at
  /// the end of the label (a disclosure chevron) states them as start / end,
  /// and the button resolves them against the reading direction.
  final CoreEdgeInsets? padding;

  /// Gap between the leading / trailing icon and the label, passed to the
  /// `Gap` between them as is. `null` takes the size's gap from
  /// [defaultsBySize], then falls back to [defaultIconLabelGapStyle].
  final CoreGapStyle? iconLabelGapStyle;

  /// Border radius override for `CoreButtonShape.circle`. `null` defers
  /// to [defaultCircleBorderRadius] (pill). The shape itself is set on the
  /// widget; this field only changes the corners drawn for the circle
  /// shape.
  final CoreBorderRadius? circleBorderRadius;

  /// Padding override for `CoreButtonShape.square` /
  /// `CoreButtonShape.circle`. `null` defers to [defaultIconShapePadding]
  /// (zero — tight icon container). The shape itself is set on the
  /// widget; this field only changes the padding used for the square /
  /// circle shapes.
  final CoreEdgeInsets? iconShapePadding;

  // ═══════════════════════════════════════════════════
  // 7. Props — behaviour (boolean / Duration / enum)
  // ═══════════════════════════════════════════════════

  /// How long the button's look (colours, border, corners, padding) takes
  /// to change between states (hover / focus / pressed). `null` defers to
  /// [defaultAnimationDuration].
  final Duration? animationDuration;

  /// The engage-squash pair's shared clock — how long the shadow takes
  /// to hide and the control takes to travel into the space it vacated.
  /// `null` defers to [defaultCastHideDuration]. Reduced-motion collapses
  /// this to zero on both platforms (`core/design-tokens.md`'s
  /// transition tier) — state (the hide, the travel) is unaffected.
  final Duration? castHideDuration;

  /// Scale the button shrinks to while pressed. `null` defers to
  /// [defaultPressedScale]; `1.0` turns the shrink off. Rides the
  /// [castHideDuration] clock on both platforms, so the press reads as
  /// one gesture with the engage pair. The rest render never wears it.
  final double? pressedScale;

  /// Whether the hover visual effect is suppressed. `null` defers to
  /// [defaultDisableHoverEffect].
  final bool? disableHoverEffect;

  /// State-layer ramp laid over the resting fill on hover and pressed —
  /// the resting label colour at the ramp's weights. `null` defers to the
  /// variant's own ramp ([CoreButtonVariantStyle.stateLayer]), which the
  /// filled variants leave unset because they swap the container instead.
  ///
  /// The wash is tinted with the colour the label actually rests in, so a
  /// caller that recolours the label ([foregroundColor]) gets a wash of
  /// the same colour. That is what lets a `plain` button sitting on a
  /// coloured surface (a banner or toast action, whose label is pinned to
  /// the surface's `on-*` colour) show hover at all: with the label pinned
  /// there is no colour change left to show, and the wash stays visible
  /// whatever the surface is.
  final CoreStateLayer? stateLayer;

  // ═══════════════════════════════════════════════════
  // 8. Props — nested style slots
  // ═══════════════════════════════════════════════════

  /// Focus ring override ([CoreFocusOutlineStyle]) — ring colour, width,
  /// offset and the colour of the band in the offset. `null` (or any field
  /// left unset in it) defers to [defaultFocusOutlineStyle].
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Label text style override (a `CoreTextStyle`), so any of font size,
  /// weight or colour can be changed without touching the rest of the
  /// button's look.
  final CoreTextStyle? labelStyle;

  /// Leading icon style override (a `CoreIconStyle`) — set its size, its
  /// colour, or both.
  final CoreIconStyle? leadingIconStyle;

  /// Trailing icon style override (a `CoreIconStyle`).
  final CoreIconStyle? trailingIconStyle;

  /// The glyph of a `CoreButtonShape.square` / `CoreButtonShape.circle`
  /// button — one with no label to sit beside, a step larger than the
  /// [leadingIconStyle] of the same size. Read in place of the size row's
  /// [leadingIconStyle] when the shape is not `rectangle`; what the
  /// instance states here outranks a slot statement ([iconSizeFor] holds
  /// the order).
  final CoreIconStyle? iconShapeIconStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested styles
  /// ([labelStyle], [leadingIconStyle], [trailingIconStyle],
  /// [iconShapeIconStyle]) are merged recursively rather than replaced
  /// wholesale so a partial override only affects the fields it specifies.
  @override
  CoreButtonStyle merge(CoreButtonStyle? other) {
    if (other == null) return this;
    return CoreButtonStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      hoverBackgroundColor: other.hoverBackgroundColor ?? hoverBackgroundColor,
      hoverForegroundColor: other.hoverForegroundColor ?? hoverForegroundColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      boxShadow: other.boxShadow ?? boxShadow,
      castMotion: other.castMotion ?? castMotion,
      dashedBorder: other.dashedBorder ?? dashedBorder,
      dashedBorderColor: other.dashedBorderColor ?? dashedBorderColor,
      dashLength: other.dashLength ?? dashLength,
      dashSpacing: other.dashSpacing ?? dashSpacing,
      height: other.height ?? height,
      width: other.width ?? width,
      minWidth: other.minWidth ?? minWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      padding: other.padding ?? padding,
      iconLabelGapStyle: _mergeGap(
        iconLabelGapStyle,
        other.iconLabelGapStyle,
      ),
      circleBorderRadius: other.circleBorderRadius ?? circleBorderRadius,
      iconShapePadding: other.iconShapePadding ?? iconShapePadding,
      animationDuration: other.animationDuration ?? animationDuration,
      castHideDuration: other.castHideDuration ?? castHideDuration,
      pressedScale: other.pressedScale ?? pressedScale,
      disableHoverEffect: other.disableHoverEffect ?? disableHoverEffect,
      stateLayer: other.stateLayer ?? stateLayer,
      focusOutlineStyle: _mergeFocusOutline(
        focusOutlineStyle,
        other.focusOutlineStyle,
      ),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      leadingIconStyle: _mergeIcon(leadingIconStyle, other.leadingIconStyle),
      trailingIconStyle: _mergeIcon(trailingIconStyle, other.trailingIconStyle),
      iconShapeIconStyle: _mergeIcon(
        iconShapeIconStyle,
        other.iconShapeIconStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreButtonStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    CoreColor? borderColor,
    CoreColor? hoverBackgroundColor,
    CoreColor? hoverForegroundColor,
    CoreColor? hoverBorderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    List<CoreShadowLayer>? boxShadow,
    CoreCastMotion? castMotion,
    bool? dashedBorder,
    CoreColor? dashedBorderColor,
    double? dashLength,
    double? dashSpacing,
    double? height,
    double? width,
    double? minWidth,
    double? maxWidth,
    CoreEdgeInsets? padding,
    CoreGapStyle? iconLabelGapStyle,
    CoreBorderRadius? circleBorderRadius,
    CoreEdgeInsets? iconShapePadding,
    Duration? animationDuration,
    Duration? castHideDuration,
    double? pressedScale,
    bool? disableHoverEffect,
    CoreStateLayer? stateLayer,
    CoreFocusOutlineStyle? focusOutlineStyle,
    CoreTextStyle? labelStyle,
    CoreIconStyle? leadingIconStyle,
    CoreIconStyle? trailingIconStyle,
    CoreIconStyle? iconShapeIconStyle,
  }) {
    return CoreButtonStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      borderColor: borderColor ?? this.borderColor,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      hoverForegroundColor: hoverForegroundColor ?? this.hoverForegroundColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      castMotion: castMotion ?? this.castMotion,
      dashedBorder: dashedBorder ?? this.dashedBorder,
      dashedBorderColor: dashedBorderColor ?? this.dashedBorderColor,
      dashLength: dashLength ?? this.dashLength,
      dashSpacing: dashSpacing ?? this.dashSpacing,
      height: height ?? this.height,
      width: width ?? this.width,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      padding: padding ?? this.padding,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
      circleBorderRadius: circleBorderRadius ?? this.circleBorderRadius,
      iconShapePadding: iconShapePadding ?? this.iconShapePadding,
      animationDuration: animationDuration ?? this.animationDuration,
      castHideDuration: castHideDuration ?? this.castHideDuration,
      pressedScale: pressedScale ?? this.pressedScale,
      disableHoverEffect: disableHoverEffect ?? this.disableHoverEffect,
      stateLayer: stateLayer ?? this.stateLayer,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      leadingIconStyle: leadingIconStyle ?? this.leadingIconStyle,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
      iconShapeIconStyle: iconShapeIconStyle ?? this.iconShapeIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreButtonStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderColor == other.borderColor &&
          hoverBackgroundColor == other.hoverBackgroundColor &&
          hoverForegroundColor == other.hoverForegroundColor &&
          hoverBorderColor == other.hoverBorderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          _shadowListEq(boxShadow, other.boxShadow) &&
          castMotion == other.castMotion &&
          dashedBorder == other.dashedBorder &&
          dashedBorderColor == other.dashedBorderColor &&
          dashLength == other.dashLength &&
          dashSpacing == other.dashSpacing &&
          height == other.height &&
          width == other.width &&
          minWidth == other.minWidth &&
          maxWidth == other.maxWidth &&
          padding == other.padding &&
          iconLabelGapStyle == other.iconLabelGapStyle &&
          circleBorderRadius == other.circleBorderRadius &&
          iconShapePadding == other.iconShapePadding &&
          animationDuration == other.animationDuration &&
          castHideDuration == other.castHideDuration &&
          pressedScale == other.pressedScale &&
          disableHoverEffect == other.disableHoverEffect &&
          stateLayer == other.stateLayer &&
          focusOutlineStyle == other.focusOutlineStyle &&
          labelStyle == other.labelStyle &&
          leadingIconStyle == other.leadingIconStyle &&
          trailingIconStyle == other.trailingIconStyle &&
          iconShapeIconStyle == other.iconShapeIconStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    foregroundColor,
    borderColor,
    hoverBackgroundColor,
    hoverForegroundColor,
    hoverBorderColor,
    borderWidth,
    borderRadius,
    if (boxShadow != null) Object.hashAll(boxShadow!),
    castMotion,
    dashedBorder,
    dashedBorderColor,
    dashLength,
    dashSpacing,
    height,
    width,
    minWidth,
    maxWidth,
    padding,
    iconLabelGapStyle,
    circleBorderRadius,
    iconShapePadding,
    animationDuration,
    castHideDuration,
    pressedScale,
    disableHoverEffect,
    stateLayer,
    focusOutlineStyle,
    labelStyle,
    leadingIconStyle,
    trailingIconStyle,
    iconShapeIconStyle,
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

  static CoreFocusOutlineStyle? _mergeFocusOutline(
    CoreFocusOutlineStyle? base,
    CoreFocusOutlineStyle? other,
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

  static bool _shadowListEq(
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

/// Complete visual style definition for a [CoreButtonVariant].
///
/// Each variant defines colours for 3 states: normal, hovered,
/// disabled — plus optional border / icon / selected / focused
/// overrides. All values are platform-neutral
/// ([CoreColor]); the consuming renderer converts at use-site
/// (Flutter via `scheme.resolve(...).toValue()`; Web via
/// `'bg-${color}'` / `var(--coui-*)`).
///
/// "No-fill" variants (plain / menu / menubar / fixed) use
/// [CoreColor.transparent]; Web omits the Tailwind background class
/// on those.
@immutable
class CoreButtonVariantStyle {
  /// Creates a variant style.
  const CoreButtonVariantStyle({
    // Normal
    required this.backgroundColor,
    required this.foregroundColor,
    // Hovered
    required this.hoverBackgroundColor,
    // Disabled
    required this.disabledBackgroundColor,
    required this.disabledForegroundColor,
    this.borderColor,
    this.iconColor,
    this.hoverForegroundColor,
    this.hoverBorderColor,
    this.hoverIconColor,
    this.disabledBorderColor,
    this.disabledIconColor,
    // Pressed (opt-in — `null` falls through to the hover treatment,
    // see `pressedBackgroundColor`'s doc). Only `destructive` sets these
    // today (`CoUI_Button_State_Layer_Decision.md` §9's B2 opaque
    // token-swap model); every other variant is byte-identical to
    // before this axis existed.
    this.pressedBackgroundColor,
    this.pressedForegroundColor,
    this.pressedBorderColor,
    this.pressedIconColor,
    this.stateLayer,
    // Selected (e.g. card selected state)
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.selectedBorderColor,
    // Focused (e.g. menu focused state)
    this.focusedBackgroundColor,
    // Layout overrides
    this.radius,
    this.paddingInline,
    this.borderWidth = 0,
    this.labelStyle,
    this.useSelectedState = false,
    this.useFocusedAsHover = false,
    this.focusOutlineStyle,
  });

  // === Normal ===

  /// Background colour in the resting state.
  final CoreColor backgroundColor;

  /// Label / icon colour in the resting state.
  final CoreColor foregroundColor;

  /// Optional border colour in the resting state.
  final CoreColor? borderColor;

  /// Optional icon-only colour override; falls back to [foregroundColor].
  final CoreColor? iconColor;

  // === Hovered ===

  /// Background colour when hovered.
  final CoreColor hoverBackgroundColor;

  /// Optional foreground colour override when hovered.
  final CoreColor? hoverForegroundColor;

  /// Optional border colour override when hovered.
  final CoreColor? hoverBorderColor;

  /// Optional icon-only colour override when hovered.
  final CoreColor? hoverIconColor;

  // === Pressed ===
  //
  // Distinct from hover — a real third state most variants do not
  // populate. `null` on any field here falls through to that field's
  // hover treatment (`buildDecoration`/`buildTextStyle`/`buildIconTheme`
  // read `vs.pressedX ?? <hover value>`), so a variant that never sets
  // these paints `WidgetState.pressed` exactly as `WidgetState.hovered`
  // — unchanged from before this axis existed. `destructive` is the one
  // variant that populates the set today (opaque `errorStrong` fill —
  // `CoUI_Button_State_Layer_Decision.md` §9), because it is the one
  // whose contrast headroom is narrow enough that a third authored step
  // matters; every other variant's fill has enough headroom that
  // reusing hover for pressed is not a defect.

  /// Background colour when pressed. `null` → the hover background.
  final CoreColor? pressedBackgroundColor;

  /// Foreground (label / icon) colour when pressed. `null` → the hover
  /// foreground.
  final CoreColor? pressedForegroundColor;

  /// Border colour when pressed. `null` → the hover border.
  final CoreColor? pressedBorderColor;

  /// Icon-only colour override when pressed. `null` → the hover icon
  /// colour (else the pressed/hover foreground).
  final CoreColor? pressedIconColor;

  // === State layer ===
  //
  // A second hover/pressed model, distinct from the plain [hoverBackgroundColor]
  // swap above. Variants with an OPAQUE resting fill (`primary` / `secondary`
  // / `outline`) do not change that fill on hover/pressed at all — instead
  // Figma composites a translucent [foregroundColor]-tinted wash on top of
  // it (3% hover, 12% pressed). A plain translucent `hoverBackgroundColor`
  // cannot express this: `background-color` with alpha blends against
  // whatever sits BEHIND the button (the page), not against the button's
  // own prior fill, so it would reintroduce exactly the page-dependent
  // contrast risk `CoUI_Button_State_Layer_Decision.md` flags for B1. The
  // resolver instead composites [foregroundColor] over the *resolved*
  // background at build/paint time (Flutter: `Color.alphaBlend`; Web: a
  // scoped `color-mix()` rule, since Web has no build-time RGB to blend
  // against) — both platforms land on the same opaque result regardless of
  // what page the button sits on. Variants whose resting fill is already
  // fully transparent (`ghost`) don't need this: a plain translucent
  // `hoverBackgroundColor`/`pressedBackgroundColor` already composites
  // against the page correctly there, because the page showing through IS
  // the intended rest appearance.
  //
  // `null` on either leaves [hoverBackgroundColor]/[pressedBackgroundColor]
  // as the plain (non-composited) value — unchanged for every variant that
  // doesn't opt in.

  /// How strongly this variant lays its own [foregroundColor] over itself
  /// while hovered, focused or pressed. `null` → no overlay.
  ///
  /// Two ramps, and which one a variant takes is decided by what it is
  /// filled with rather than by what it is called: [CoreStateLayer.strong]
  /// over a dark or saturated fill, [CoreStateLayer.subtle] over an
  /// unfilled one. The same alpha moves a light surface further than a
  /// dark one, so matching numbers would make the filled controls look
  /// unresponsive beside the unfilled ones.
  ///
  /// This is a visual aid, not the accessible focus indicator. The 3:1
  /// non-text contrast that focus owes (WCAG 1.4.11) is the focus ring's
  /// job — `focusOutlineStyle` — and stays so whether or not this is set.
  /// Raising the focus weight is never a substitute for a ring, and a ring
  /// is never a reason to leave this null.
  ///
  /// `destructive` states none on purpose: its hover is a different
  /// colour, not a heavier one, and no overlay makes a white panel into a
  /// red one. See `docs/decision-log-state-layer-opacity.md`.
  ///
  /// This field replaced three independent `double?` opacity fields
  /// (`hoverStateLayerOpacity` / `focusStateLayerOpacity` /
  /// `pressedStateLayerOpacity`) in #4505. That footer was the fifth of
  /// five squashed into a single commit and dropped by the release
  /// tooling (only the first footer is read). The restatement in #4616
  /// was itself squash-merged with four sibling footers and lost the
  /// same way (`ea3efc985`) — this is the second restatement, on its
  /// own commit. The old fields' null-falls-through-to-hover behaviour
  /// is gone: a ramp states all three or none.
  final CoreStateLayer? stateLayer;

  // === Disabled ===

  /// Background colour when disabled.
  final CoreColor disabledBackgroundColor;

  /// Foreground colour when disabled.
  final CoreColor disabledForegroundColor;

  /// Optional border colour when disabled.
  final CoreColor? disabledBorderColor;

  /// Optional icon-only colour when disabled.
  final CoreColor? disabledIconColor;

  // === Selected ===

  /// Optional background colour for the selected state. Only honoured
  /// when [useSelectedState] is `true`.
  final CoreColor? selectedBackgroundColor;

  /// Optional foreground (label / icon) colour for the selected state —
  /// the contrasting text colour on top of [selectedBackgroundColor] (e.g.
  /// `onPrimary` over a `primary` selected fill). Only honoured when
  /// [useSelectedState] is `true`; falls back to [foregroundColor] when unset.
  final CoreColor? selectedForegroundColor;

  /// Optional border colour for the selected state.
  final CoreColor? selectedBorderColor;

  // === Focused ===

  /// Optional background colour for the focused state. Only honoured
  /// when [useFocusedAsHover] is `true`.
  final CoreColor? focusedBackgroundColor;

  // === Layout ===

  /// Border radius (logical px) this variant insists on regardless of
  /// size — `null` (every variant today) takes the size row's corner, the
  /// control height × 0.25. Read through
  /// [CoreButtonStyle.borderRadiusForSize], never directly, so the
  /// variant-beats-size precedence is decided once.
  final double? radius;

  /// Inline (start/end) padding this variant insists on regardless of
  /// size — `null` follows the size ladder; `plain` states `0` so the
  /// affordance sits flush with the text around it. The block
  /// pair is never the variant's. Read through
  /// [CoreButtonStyle.paddingFor].
  final double? paddingInline;

  /// Border stroke width (logical px). Defaults to 0 — filled
  /// variants have no border. Outlined variants set this to 1 px
  /// (`CoreStrokeWidth.stroke1`) so the resolver doesn't need to
  /// infer the width from `borderColor != null`.
  final double borderWidth;

  /// What this variant states about how its label is drawn — its weight
  /// (`CoreTextStyle(fontWeight: …)`). `null` leaves the size row's role
  /// weight (medium, 500) as it is.
  ///
  /// This is the variant row's own statement, not the button-wide
  /// [CoreButtonStyle.labelStyle] (the theme / instance slot that rides last
  /// on the label): [CoreButtonStyle.labelStyleFor] lays this slot's
  /// [CoreTextStyle.fontWeight] over the size row's role and reads nothing
  /// else from it.
  ///
  /// Stated here, on the variant, rather than on the size rows: the size
  /// rows are shared by every variant, and a weight written there would
  /// reach the variants that must stay at the role's 500 — the two menu
  /// rows (`menu` · `menubar`, which `Menubar` · `NavigationMenu` · `Fab`
  /// compose) and `fixed` (which wraps a card's own content). Read through
  /// [CoreButtonStyle.labelStyleFor], never directly, so the order of
  /// role → variant weight → the composer's own label style is decided
  /// once.
  final CoreTextStyle? labelStyle;

  /// Whether to also react to selected state (card).
  final bool useSelectedState;

  /// Whether focused state triggers hover style (menu).
  final bool useFocusedAsHover;

  /// Variant-level focus-ring override. `null` fields defer to
  /// [CoreButtonStyle.defaultFocusOutlineStyle]; a per-instance
  /// `CoreButtonStyle.focusOutlineStyle` merges on top of this in the
  /// resolver, so the precedence is design-system default → variant
  /// default → per-instance override (mirrors every other variant-keyed
  /// chrome field on this class).
  ///
  /// Only `destructive` sets this today — its ring is `error`-coloured
  /// at a variant-specific 1.5px, not the shared `primary`/2px default
  /// every other variant paints (`CoUI_Button_State_Layer_Decision.md`
  /// §9, verified against the live Figma ring node).
  final CoreFocusOutlineStyle? focusOutlineStyle;
}
