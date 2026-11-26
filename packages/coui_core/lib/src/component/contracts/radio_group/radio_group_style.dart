/// Per-instance style for `RadioGroup`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/radio_group/radio_group_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/size.dart' show CoreSize;
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_size.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Per-size dimensional token bundle for `RadioGroup`.
///
/// All values are platform-neutral logical pixels — Flutter consumes
/// them directly, Web converts via the Tailwind adapters
/// (`tailwindSpace` / `tailwindStroke`) defined in
/// `coui_web/lib/src/util/core_to_css.dart`.
/// Immutable style describing how a `RadioGroup` (and the radio
/// indicators within) should render.
///
/// `CoreRadioGroupStyle` carries chrome / dimensional overrides
/// for the radio indicator itself as flat fields, plus nested
/// `CoreIconStyle` / `CoreTextStyle` references for the indicator
/// dot and item label slots — Epic #1302's "atomic-style nesting"
/// rule.
///
/// **Semantic enums (`variant`, `size`, `orientation`) live on the
/// widget, not on this style** (Epic #1302 원칙 6/7). They identify
/// the radio group instance and are passed as widget parameters.
///
/// Variant-independent / size-keyed defaults live as `static const`
/// here (Epic #1415 Phase 6f, Epic #1696 Phase 1) — Flutter and Web
/// resolvers reference the same `CoreRadioGroupStyle.defaultX` /
/// `defaultsBySize[size]` so the two platforms cannot silently diverge.
///
/// ```text
/// design system default for variant / size
///   → CoreRadioGroupTheme.style                       // 프로젝트 공통
///   → CoreRadioGroupTheme.variantStyles[variant]      // variant 별
///   → parent component slot override
///   → widget.radioGroupStyle                          // 인스턴스별
/// ```
@immutable
class CoreRadioGroupStyle implements CoreStyle<CoreRadioGroupStyle> {
  /// Creates a [CoreRadioGroupStyle].
  const CoreRadioGroupStyle({
    this.indicatorBackgroundColor,
    this.indicatorActiveColor,
    this.indicatorBorderColor,
    this.indicatorBorderWidth,
    this.selectedIndicatorBorderWidth,
    this.indicatorSize,
    this.indicatorBorderRadius,
    this.innerDotSize,
    this.indicatorLabelGapStyle,
    this.itemSpacing,
    this.colorTransitionDuration,
    this.dotTransitionDuration,
    this.indicatorDotStyle,
    this.labelStyle,
    this.descriptionStyle,
    this.labelDescriptionGapStyle,
    this.stateLayer,
    this.stateLayerColor,
    this.stateLayerSpread,
    this.tilePadding,
    this.tileSelectedPadding,
    this.tileBorderRadius,
    this.tileBorderWidth,
    this.tileSelectedBorderWidth,
    this.tileBackgroundColor,
    this.tileSelectedBackgroundColor,
    this.tileBorderColor,
    this.tileSelectedBorderColor,
  });

  // ─── Design-system defaults ────────────────────────────────────

  /// Default label slot text style — the single source for the label's
  /// typography role (`CoreTextStyles.bodySmall`) + colour (`onSurface`),
  /// matched 1:1 with the [labelStyle] nested slot. Consumers read the
  /// colour via `defaultLabelStyle.color`; the per-size `fontSize` step
  /// sits on [defaultsBySize] and the resolvers merge it on top.
  ///
  /// Token-backed (`CoreTextStyle.token`) so the role stays a typography
  /// token: Flutter materialises it via `.toValue(theme:)`, Web routes it
  /// through `emitTypography` (role `text-body-small` class + overlay
  /// inline) — both stay dark-mode / accessibility-scale reactive instead
  /// of freezing the `CoreTypography.coui` snapshot.
  // `bodySmall` (400 / 150%), not `labelLarge` (500 / 140%): the canvas
  // states the selection-control label as regular-weight prose beside the
  // control, the same weight Checkbox and Toggle carry. Button and Chip keep
  // 500 — a control's own label and a label *for* a control are two roles.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default description slot text style — the supporting line under the
  /// label, matched 1:1 with the [descriptionStyle] nested slot. Owns the
  /// quieter foreground the two texts are told apart by; the role is stated
  /// per size in [defaultsBySize] (one step under the label), so this role
  /// is only the floor a size row that states none would fall to.
  ///
  /// Disabled reads the variant's `disabledForegroundColor` instead, the
  /// same fold the label takes, so the row dims as one block.
  // `onSurfaceVariant`, not the quieter `onSurfaceSubtle`: subtle measures
  // 3.4–3.7 : 1 on the card's selected `primaryContainer` face in CoUI, under
  // the 4.5 floor body text needs; the variant clears it (5.0–5.6 : 1).
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default gap between the label and the description beneath it — the
  /// content column's own spacing, distinct from the size row's
  /// `indicatorLabelGapStyle`, which separates the row's slots. Two axes,
  /// so two fields: this one is vertical. Checkbox's value, so a radio and
  /// a checkbox with a description stack their two lines alike.
  static const CoreGapStyle defaultLabelDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  // ─── Card tile defaults (variant `card`) ──────────────────────

  /// Default stroke width of an unselected tile.
  static const double defaultTileBorderWidth = CoreStrokeWidth.stroke1;

  /// Default stroke width of the selected tile — one rung heavier than the
  /// resting [defaultTileBorderWidth], so the chosen tile is told apart by
  /// its edge as well as its face.
  ///
  /// By default the heavier stroke moves nothing. The tile's content sits at
  /// `tilePadding` plus the **resting** width in both states, and its outer
  /// box stays the same: the extra width is drawn inward, over the padding.
  /// Flutter draws the real border and takes the difference off the padding
  /// (in step with the border's own transition); Web keeps the resting width
  /// in flow and paints the difference as an inset `box-shadow` in the
  /// border's colour, which never takes part in layout. A selected width
  /// stated under the resting one draws at the resting one.
  /// An explicit [tileSelectedPadding] opts out of the layout compensation.
  static const double defaultTileSelectedBorderWidth = CoreStrokeWidth.stroke2;

  /// Default face of an unselected tile — the page's own surface, so a
  /// resting tile reads as a bordered region of the page rather than a
  /// raised block.
  static const CoreColor defaultTileBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default face of the selected tile — the selection colour's container,
  /// the same family as the border it wears, so the chosen tile is tinted
  /// rather than merely lifted.
  static const CoreColor defaultTileSelectedBackgroundColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  /// Default border of an unselected tile. A hairline tone: the tile's
  /// boundary is not the control's boundary — the indicator's ring inside it
  /// is, and that ring carries the non-text contrast floor.
  static const CoreColor defaultTileBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default border of the selected tile — the selection colour, the same
  /// one the indicator's selected ring wears.
  static const CoreColor defaultTileSelectedBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default ramp for the halo laid around the indicator while the row is
  /// hovered or pressed.
  ///
  /// `standard` (8 / 8 / 16 %) — the ramp the selection controls share;
  /// the canvas paints hover at 8 % and pressed at 16 %. The focus weight
  /// is stated by the type but drawn by neither platform nor the canvas:
  /// a focused radio shows the `FocusOutline` ring alone, so the ramp's
  /// middle rung never reaches a pixel here.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.standard;

  /// Default ink of the halo — the surface's own foreground, laid over
  /// whatever is behind the indicator at the ramp's weight.
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default distance the halo reaches past the indicator on every side
  /// (logical px, pre-scaling). The halo is a circle of
  /// `indicatorSize + 2 × spread`; at 12–24 px an 8 % wash confined to the
  /// box's own interior is invisible, so the layer stands outside it.
  static const double defaultStateLayerSpread = CoreSpace.space4;

  /// Default colour transition duration for border/background.
  /// Web emits a CSS millisecond value; Flutter uses the [Duration]
  /// directly.
  static const Duration defaultColorTransitionDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  /// Default dot scale transition duration. Drives the
  /// `transform-scale` of the inner dot in/out animation.
  static const Duration defaultDotTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default inner-dot slot — deliberately empty. The dot carries no
  /// slot-level size or colour of its own: its size comes from the
  /// size-keyed [defaultsBySize] entry (`innerDotSize`) and its colour
  /// from the resolved active fill, so both are derived rather than
  /// authored here. This names the empty merge base both resolvers
  /// already used inline, so the base is one `default*` field instead of
  /// two `const CoreIconStyle()` literals at the use sites.
  static const CoreIconStyle defaultIndicatorDotStyle = CoreIconStyle();

  /// Default corner radius for the selection ring — a full circle. Both
  /// platform resolvers compose the ring's `OutlinedContainer` /
  /// element-chrome around this single source instead of each hardcoding
  /// `CoreRadius.radius9999` at the use site.
  static const CoreBorderRadius defaultIndicatorBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Per-variant default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  static const Map<CoreRadioGroupVariant, CoreRadioGroupVariantStyle>
  defaultsByVariant = {
    CoreRadioGroupVariant.defaultVariant: CoreRadioGroupVariantStyle(
      activeColor: CoreColor.token(CoreColors.primary),
      // `outline`: the unselected ring is the control's only boundary, so
      // it has to clear the 3:1 non-text floor against the surface
      // (`outlineVariant` does not). Same token Checkbox rests on.
      borderColor: CoreColor.token(CoreColors.outline),
      // No fill of its own — the ring sits on whatever surface hosts the
      // row. The canvas states none, and a tinted disc under a hairline
      // read as a second, dimmer control on every surface but `surface`.
      uncheckedBackground: CoreColor.transparent,
      // The disabled trio — container / outline / content — instead of
      // folding all three onto `surfaceContainer`, which would put fill,
      // stroke and any restated dot on one colour. With no dot drawn by
      // default the ring is the selection mark: a disabled selected ring
      // reads in `disabledContent` at the selected width, an unselected one
      // rests on `disabledOutline` at the resting width.
      disabledActiveColor: CoreColor.token(CoreColors.disabledContent),
      disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
      disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
    ),
    // The card's indicator is the default row's indicator — the tile around
    // it adds its own face and border (the `tile*` fields) and changes none
    // of the ring's colours. A disabled tile keeps its face (resting or
    // selected) and its width, and reads its border from `disabledBorderColor`
    // and its text from `disabledForegroundColor` below — the dimmed text and
    // edge carry the disabled state, the face still says which tile is chosen.
    CoreRadioGroupVariant.card: CoreRadioGroupVariantStyle(
      activeColor: CoreColor.token(CoreColors.primary),
      borderColor: CoreColor.token(CoreColors.outline),
      uncheckedBackground: CoreColor.transparent,
      disabledActiveColor: CoreColor.token(CoreColors.disabledContent),
      disabledBorderColor: CoreColor.token(CoreColors.disabledOutline),
      disabledBackgroundColor: CoreColor.token(CoreColors.disabledContainer),
      disabledForegroundColor: CoreColor.token(CoreColors.disabledContent),
    ),
  };

  /// Per-size dimensional defaults. Single source of truth shared by
  /// Flutter and Web — Flutter reads `radioSize` etc. directly,
  /// Web converts each `double` via `.tailwindSpace` / `.tailwindStroke`.
  // Indicator sizes follow CoUI_Size_Token_Specification §3-4
  // (Checkbox · Radio, v1.1 2026-08-07) — 12/14/16/18/20/24 with md=16
  // as the default, byte-identical to Checkbox's ladder (the spec
  // regulates the two together). The ladder lives in the primitive
  // scale's optical band (<24px, 2px interval).
  //
  // The ring carries the selection, not a dot. A resting ring is a hairline
  // boundary (`stroke1`) and a selected ring is `(size − hole) / 2` thick:
  // 3 / 4 / 4 / 5 / 5 / 6 leaves a hole of 6 / 6 / 8 / 8 / 10 / 12 from `xs`
  // through `xl2`. `innerDotSize` is 0 on every row — the dot is not drawn
  // by default; an app that wants a ring with a dot in its hole states
  // `innerDotSize` and `selectedIndicatorBorderWidth`. The resting stroke is
  // `stroke1` at every size — the same line Checkbox draws its unchecked box
  // with, so the two controls read at one weight side by side in a form.
  //
  // `indicatorLabelGapStyle` is the row's gap to the label: 6/8/8/8/10/12.
  // The two smallest rows sit 2 px wider than Checkbox's because the
  // focus ring reaches 4 px past the box (`FocusOutline.align`) and a gap
  // under that put the ring across the first letter.
  //
  // `labelStyle` carries only this size's `fontSize` — the role and the
  // colour come from [defaultLabelStyle] and the resolvers merge these on
  // top, the same shape Checkbox and Chip use. The ladder is Button's
  // (12/13/14/16/16/16), so a radio and the button beside it read at one
  // size.
  //
  // `descriptionStyle` sits one step under the label — Checkbox's
  // 11/12/13/14/14/14 — but stated by role, so its tracking and line box come
  // with it: body-xs 12 · body-xs 12 · body-small 13 · body-medium 14 from
  // `lg` up. The body scale has no 11, so `xs` shares `sm`'s 12 rather than
  // overlaying a size the scale does not draw.
  static const Map<CoreComponentSize, CoreRadioGroupStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreRadioGroupStyle(
      indicatorBorderWidth: CoreStrokeWidth.stroke1,
      selectedIndicatorBorderWidth: CoreStrokeWidth.stroke3,
      indicatorSize: CoreSize.size12,
      innerDotSize: CoreSpace.space0,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space6),
      itemSpacing: CoreSpace.space6,
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s12),
      descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
    ),
    CoreComponentSize.sm: CoreRadioGroupStyle(
      indicatorBorderWidth: CoreStrokeWidth.stroke1,
      selectedIndicatorBorderWidth: CoreStrokeWidth.stroke4,
      indicatorSize: CoreSize.size14,
      innerDotSize: CoreSpace.space0,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      itemSpacing: CoreSpace.space8,
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s13),
      descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
    ),
    CoreComponentSize.md: CoreRadioGroupStyle(
      indicatorBorderWidth: CoreStrokeWidth.stroke1,
      selectedIndicatorBorderWidth: CoreStrokeWidth.stroke4,
      indicatorSize: CoreSize.size16,
      innerDotSize: CoreSpace.space0,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      itemSpacing: CoreSpace.space8,
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s14),
      descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
    ),
    CoreComponentSize.lg: CoreRadioGroupStyle(
      indicatorBorderWidth: CoreStrokeWidth.stroke1,
      selectedIndicatorBorderWidth: CoreStrokeWidth.stroke5,
      indicatorSize: CoreSize.size18,
      innerDotSize: CoreSpace.space0,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      itemSpacing: CoreSpace.space10,
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s16),
      descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
    ),
    CoreComponentSize.xl: CoreRadioGroupStyle(
      indicatorBorderWidth: CoreStrokeWidth.stroke1,
      selectedIndicatorBorderWidth: CoreStrokeWidth.stroke5,
      indicatorSize: CoreSize.size20,
      innerDotSize: CoreSpace.space0,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space10),
      itemSpacing: CoreSpace.space12,
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s16),
      descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
    ),
    CoreComponentSize.xl2: CoreRadioGroupStyle(
      indicatorBorderWidth: CoreStrokeWidth.stroke1,
      selectedIndicatorBorderWidth: CoreStrokeWidth.stroke6,
      indicatorSize: CoreSize.size24,
      innerDotSize: CoreSpace.space0,
      indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
      itemSpacing: CoreSpace.space14,
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s16),
      descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
    ),
  };

  /// Per-size overlay for the `card` variant, laid over [defaultsBySize] by
  /// [sizeDefaultsFor]. Each row restates what a tile changes about the
  /// option — the indicator, the gaps, the text roles — and adds the tile's
  /// own padding and corner.
  ///
  /// Four rows, spread over six sizes: `xs` · `sm` · `md` carry the compact
  /// tile, `lg` the roomy one, and `xl` · `xl2` the two title tiles. A tile is
  /// read as a block rather than as a control in a line, so it does not need
  /// six distinct steps; the sizes under `md` would put a 12 px ring inside a
  /// 40 px tile.
  ///
  /// - compact (`xs`–`md`): padding 10 · 12, corner 10 (the 40 px control
  ///   rung's ratio), indicator → text 8, tile → tile 8, title label-large
  ///   (14 / 500), description body-xs (12), title → description 4.
  /// - roomy (`lg`): padding 12 · 14, corner 12 (`panel`), indicator → text
  ///   12, tile → tile 12, title label-xl (15 / 500), description
  ///   body-small (13), title → description 4.
  /// - `xl`: padding 16 all round, corner 16, title title-small (16 / 600 /
  ///   140), description body-small (13), title → description 2 — the heavier
  ///   title's 140 % line box carries the air the gap gave up.
  /// - `xl2`: one rung up every ladder `xl` moved on — padding 20, corner 20
  ///   (the corner still equal to the padding), title title-medium (18 / 600),
  ///   description body-medium (14), title → description 2.
  ///
  /// Every row carries the `lg` indicator (18, resting ring 1, selected
  /// ring 5) and the `lg` gaps from `lg` up (indicator → text 12, tile → tile
  /// 12), so no larger size steps under a smaller one.
  ///
  /// A flat size-keyed table, not a `Map<variant, Map<size, …>>`: the Figma
  /// exporter reads any `…BySize` map as a size table and cannot walk a
  /// nested one. `static final` because the roomy title states its weight
  /// over a role through `copyWith`, which is not a constant expression.
  static final Map<CoreComponentSize, CoreRadioGroupStyle> cardDefaultsBySize =
      {
        CoreComponentSize.xs: const CoreRadioGroupStyle(
          indicatorBorderWidth: CoreStrokeWidth.stroke1,
          selectedIndicatorBorderWidth: CoreStrokeWidth.stroke5,
          indicatorSize: CoreSize.size18,
          indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
          itemSpacing: CoreSpace.space8,
          labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
          descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
          labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
          tilePadding: CoreEdgeInsets.symmetric(
            vertical: CoreSpace.space10,
            horizontal: CoreSpace.space12,
          ),
          tileBorderRadius: CoreBorderRadius.all(CoreRadius.radius10),
        ),
        CoreComponentSize.sm: const CoreRadioGroupStyle(
          indicatorBorderWidth: CoreStrokeWidth.stroke1,
          selectedIndicatorBorderWidth: CoreStrokeWidth.stroke5,
          indicatorSize: CoreSize.size18,
          indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
          itemSpacing: CoreSpace.space8,
          labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
          descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
          labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
          tilePadding: CoreEdgeInsets.symmetric(
            vertical: CoreSpace.space10,
            horizontal: CoreSpace.space12,
          ),
          tileBorderRadius: CoreBorderRadius.all(CoreRadius.radius10),
        ),
        CoreComponentSize.md: const CoreRadioGroupStyle(
          indicatorBorderWidth: CoreStrokeWidth.stroke1,
          selectedIndicatorBorderWidth: CoreStrokeWidth.stroke5,
          indicatorSize: CoreSize.size18,
          indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
          itemSpacing: CoreSpace.space8,
          labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
          descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyXs),
          labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
          tilePadding: CoreEdgeInsets.symmetric(
            vertical: CoreSpace.space10,
            horizontal: CoreSpace.space12,
          ),
          tileBorderRadius: CoreBorderRadius.all(CoreRadius.radius10),
        ),
        CoreComponentSize.lg: const CoreRadioGroupStyle(
          indicatorBorderWidth: CoreStrokeWidth.stroke1,
          selectedIndicatorBorderWidth: CoreStrokeWidth.stroke5,
          indicatorSize: CoreSize.size18,
          indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
          itemSpacing: CoreSpace.space12,
          labelStyle: CoreTextStyle.token(CoreTextStyles.labelXl),
          descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
          labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
          tilePadding: CoreEdgeInsets.symmetric(
            vertical: CoreSpace.space12,
            horizontal: CoreSpace.space14,
          ),
          tileBorderRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
        ),
        CoreComponentSize.xl: const CoreRadioGroupStyle(
          indicatorBorderWidth: CoreStrokeWidth.stroke1,
          selectedIndicatorBorderWidth: CoreStrokeWidth.stroke5,
          indicatorSize: CoreSize.size18,
          indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
          itemSpacing: CoreSpace.space12,
          labelStyle: CoreTextStyle.token(CoreTextStyles.titleSmall),
          descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
          labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space2),
          tilePadding: CoreEdgeInsets.all(CoreSpace.space16),
          tileBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
        CoreComponentSize.xl2: const CoreRadioGroupStyle(
          indicatorBorderWidth: CoreStrokeWidth.stroke1,
          selectedIndicatorBorderWidth: CoreStrokeWidth.stroke5,
          indicatorSize: CoreSize.size18,
          indicatorLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
          itemSpacing: CoreSpace.space12,
          labelStyle: CoreTextStyle.token(CoreTextStyles.titleMedium),
          descriptionStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
          labelDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space2),
          tilePadding: CoreEdgeInsets.all(CoreSpace.space20),
          tileBorderRadius: CoreBorderRadius.all(CoreRadius.radius20),
        ),
      };

  /// The size layer both resolvers read beneath the theme and widget
  /// styles: [defaultsBySize] for [size], with [cardDefaultsBySize] laid
  /// over it when [variant] is [CoreRadioGroupVariant.card].
  ///
  /// The two text slots are *replaced* by the card row rather than merged
  /// into the size row. [CoreTextStyle.merge] lets a later role win but keeps
  /// an earlier `fontSize`, and the size rows state their label as a bare
  /// `fontSize` — merging would put the card's title role under the size
  /// row's 16 at `lg` and the tile would draw its title at the row's size
  /// instead of the role's. Kept here, not in either resolver, so the two
  /// platforms cannot lay the layers in different orders.
  static CoreRadioGroupStyle sizeDefaultsFor(
    CoreRadioGroupVariant variant,
    CoreComponentSize size,
  ) {
    final row = defaultsBySize[size]!;
    if (variant != CoreRadioGroupVariant.card) return row;
    final card = cardDefaultsBySize[size]!;
    return row
        .merge(card)
        .copyWith(
          labelStyle: card.labelStyle,
          descriptionStyle: card.descriptionStyle,
        );
  }

  // ── Indicator chrome (flat) ──────────────────

  /// Indicator background fill colour override (idle / unselected).
  final CoreColor? indicatorBackgroundColor;

  /// Indicator background fill colour when selected.
  final CoreColor? indicatorActiveColor;

  /// Indicator border stroke colour override.
  final CoreColor? indicatorBorderColor;

  /// Indicator border stroke width override (logical px, pre-scaling) for
  /// the **resting** ring — unselected, and disabled-unselected. The selected
  /// ring (disabled or not) reads [selectedIndicatorBorderWidth], so
  /// restating only this field changes the resting ring and leaves the
  /// selected one on its size row.
  final double? indicatorBorderWidth;

  /// Selected ring stroke width override (logical px, pre-scaling). The
  /// selection is carried by this ring — thicker than the resting one,
  /// with the hole left open — not by a dot. A disabled selected ring keeps
  /// this width (in the disabled-content colour). `null` defers to the
  /// size-keyed [defaultsBySize] entry, and a size whose entry states none
  /// draws the selected ring at the resting [indicatorBorderWidth].
  ///
  /// The ring is drawn inside the indicator box, so the hole's diameter is
  /// `indicatorSize − 2 × selectedIndicatorBorderWidth`. A ring with a dot
  /// in its hole is stated with `innerDotSize` and this field set to the
  /// resting width.
  final double? selectedIndicatorBorderWidth;

  /// Indicator size (width = height) override (logical px).
  final double? indicatorSize;

  /// Selection ring corner radius override. Falls back to
  /// [defaultIndicatorBorderRadius] (a full circle) when null.
  final CoreBorderRadius? indicatorBorderRadius;

  /// Inner dot size override (logical px) — applied when the item is
  /// selected. Falls back to [defaultsBySize] when null, which states `0`:
  /// no dot is drawn by default, because the selected ring carries the
  /// selection ([selectedIndicatorBorderWidth]).
  final double? innerDotSize;

  /// Style of the `Gap` between the indicator and the item's label /
  /// prefix / suffix slot, in pre-scaling units (the `Gap` applies scaling
  /// itself). `null` defers to the size-keyed [defaultsBySize] entry.
  final CoreGapStyle? indicatorLabelGapStyle;

  /// Spacing between sibling radio items (logical px, pre-scaling) —
  /// `Wrap.spacing` / `Wrap.runSpacing` in a horizontal group,
  /// `Column.spacing` in a vertical one. Falls back to the size-keyed
  /// [defaultsBySize] entry when null.
  ///
  /// Both are native paint-API arguments that consume raw doubles, so this
  /// slot stays scalar (`double?`) rather than the nested [CoreGapStyle]
  /// shape used for `Gap` slots.
  final double? itemSpacing;

  /// Indicator border / background colour transition duration override.
  /// Falls back to [defaultColorTransitionDuration] when null.
  final Duration? colorTransitionDuration;

  /// Inner dot scale transition duration override. Falls back to
  /// [defaultDotTransitionDuration] when null.
  final Duration? dotTransitionDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Inner dot style (size / colour) when the item is selected. The dot is
  /// drawn as an icon, so this is a `CoreIconStyle`. `null` defers to
  /// [defaultIndicatorDotStyle]; whatever size or colour that leaves unset
  /// comes from [defaultsBySize] and the active fill colour.
  final CoreIconStyle? indicatorDotStyle;

  /// Item label text style override. Text colour + typography role
  /// are both carried inside this slot; the per-size `fontSize` step
  /// comes from [defaultsBySize] underneath it.
  final CoreTextStyle? labelStyle;

  /// Description text style override — the supporting line under the
  /// label. Merges over the size row's role (`defaultsBySize`) and
  /// [defaultDescriptionStyle]'s foreground, so a caller that states only a
  /// weight keeps both. Disabled reads the variant's disabled foreground.
  final CoreTextStyle? descriptionStyle;

  /// Style of the vertical gap between the label and the description below
  /// it. `null` defers to the size layer (the card rows set one), then to
  /// [defaultLabelDescriptionGapStyle].
  final CoreGapStyle? labelDescriptionGapStyle;

  // ── State layer (hover / pressed halo) ───────────

  /// Ramp laid around the indicator while the row is hovered or pressed.
  /// Defaults to [defaultStateLayer]; the `focus` weight is not painted
  /// (see the default's doc).
  final CoreStateLayer? stateLayer;

  /// Ink of the halo. Defaults to [defaultStateLayerColor].
  final CoreColor? stateLayerColor;

  /// How far the halo reaches past the indicator on each side (logical
  /// px, pre-scaling). Defaults to [defaultStateLayerSpread].
  ///
  /// The `card` variant draws no halo — its state layer covers the whole
  /// tile, clipped to the tile's corner — so this reaches nothing there.
  final double? stateLayerSpread;

  // ── Card tile (variant `card`) ───────────────────

  /// Inset between the tile's border and its content (logical px,
  /// pre-scaling). `null` defers to [cardDefaultsBySize]. Read only by the
  /// `card` variant.
  final CoreEdgeInsets? tilePadding;

  /// Padding inside the selected card's border, before scaling. `null` uses
  /// [tilePadding] minus the extra selected stroke, so the content stays
  /// where it sits at rest and the card keeps its outer size. Ignored by
  /// the plain variant.
  ///
  /// An explicit value opts into independent selected-state layout,
  /// including disabled selected cards. There is deliberately no default: a
  /// fixed value would disable the border-width compensation and alter the
  /// existing selected card size and position.
  final CoreEdgeInsets? tileSelectedPadding;

  /// Tile corner. `null` defers to [cardDefaultsBySize]. The focus ring
  /// around a focused tile follows this corner. Read only by the `card`
  /// variant.
  final CoreBorderRadius? tileBorderRadius;

  /// Stroke width of an unselected tile (logical px, pre-scaling). `null`
  /// defers to [defaultTileBorderWidth]. It is also the width the tile's
  /// content is inset by in both states unless [tileSelectedPadding] is set.
  /// Read only by the `card` variant.
  final double? tileBorderWidth;

  /// Stroke width of the selected tile (logical px, pre-scaling), disabled
  /// or not. `null` defers to [defaultTileSelectedBorderWidth]. The extra
  /// over [tileBorderWidth] is drawn inward and moves neither the content nor
  /// the tile's box unless [tileSelectedPadding] is set (see the default's
  /// doc). Read only by the `card` variant.
  final double? tileSelectedBorderWidth;

  /// Face of an unselected tile, disabled or not. `null` defers to
  /// [defaultTileBackgroundColor].
  final CoreColor? tileBackgroundColor;

  /// Face of the selected tile, disabled or not. `null` defers to
  /// [defaultTileSelectedBackgroundColor].
  final CoreColor? tileSelectedBackgroundColor;

  /// Border of an unselected tile. `null` defers to
  /// [defaultTileBorderColor]. A disabled tile reads the variant's
  /// `disabledBorderColor` instead, selected or not.
  final CoreColor? tileBorderColor;

  /// Border of the selected tile. `null` defers to
  /// [defaultTileSelectedBorderColor]. A disabled selected tile reads the
  /// variant's `disabledBorderColor` instead.
  final CoreColor? tileSelectedBorderColor;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively so partial overrides only touch the fields
  /// they specify.
  @override
  CoreRadioGroupStyle merge(CoreRadioGroupStyle? other) {
    if (other == null) return this;
    return CoreRadioGroupStyle(
      indicatorBackgroundColor:
          other.indicatorBackgroundColor ?? indicatorBackgroundColor,
      indicatorActiveColor: other.indicatorActiveColor ?? indicatorActiveColor,
      indicatorBorderColor: other.indicatorBorderColor ?? indicatorBorderColor,
      indicatorBorderWidth: other.indicatorBorderWidth ?? indicatorBorderWidth,
      selectedIndicatorBorderWidth:
          other.selectedIndicatorBorderWidth ?? selectedIndicatorBorderWidth,
      indicatorSize: other.indicatorSize ?? indicatorSize,
      indicatorBorderRadius:
          other.indicatorBorderRadius ?? indicatorBorderRadius,
      innerDotSize: other.innerDotSize ?? innerDotSize,
      indicatorLabelGapStyle: _mergeGap(
        indicatorLabelGapStyle,
        other.indicatorLabelGapStyle,
      ),
      itemSpacing: other.itemSpacing ?? itemSpacing,
      colorTransitionDuration:
          other.colorTransitionDuration ?? colorTransitionDuration,
      dotTransitionDuration:
          other.dotTransitionDuration ?? dotTransitionDuration,
      indicatorDotStyle: _mergeIcon(
        indicatorDotStyle,
        other.indicatorDotStyle,
      ),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      labelDescriptionGapStyle: _mergeGap(
        labelDescriptionGapStyle,
        other.labelDescriptionGapStyle,
      ),
      stateLayer: other.stateLayer ?? stateLayer,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      stateLayerSpread: other.stateLayerSpread ?? stateLayerSpread,
      tilePadding: other.tilePadding ?? tilePadding,
      tileSelectedPadding: other.tileSelectedPadding ?? tileSelectedPadding,
      tileBorderRadius: other.tileBorderRadius ?? tileBorderRadius,
      tileBorderWidth: other.tileBorderWidth ?? tileBorderWidth,
      tileSelectedBorderWidth:
          other.tileSelectedBorderWidth ?? tileSelectedBorderWidth,
      tileBackgroundColor: other.tileBackgroundColor ?? tileBackgroundColor,
      tileSelectedBackgroundColor:
          other.tileSelectedBackgroundColor ?? tileSelectedBackgroundColor,
      tileBorderColor: other.tileBorderColor ?? tileBorderColor,
      tileSelectedBorderColor:
          other.tileSelectedBorderColor ?? tileSelectedBorderColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreRadioGroupStyle copyWith({
    CoreColor? indicatorBackgroundColor,
    CoreColor? indicatorActiveColor,
    CoreColor? indicatorBorderColor,
    double? indicatorBorderWidth,
    double? selectedIndicatorBorderWidth,
    double? indicatorSize,
    CoreBorderRadius? indicatorBorderRadius,
    double? innerDotSize,
    CoreGapStyle? indicatorLabelGapStyle,
    double? itemSpacing,
    Duration? colorTransitionDuration,
    Duration? dotTransitionDuration,
    CoreIconStyle? indicatorDotStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? descriptionStyle,
    CoreGapStyle? labelDescriptionGapStyle,
    CoreStateLayer? stateLayer,
    CoreColor? stateLayerColor,
    double? stateLayerSpread,
    CoreEdgeInsets? tilePadding,
    CoreEdgeInsets? tileSelectedPadding,
    CoreBorderRadius? tileBorderRadius,
    double? tileBorderWidth,
    double? tileSelectedBorderWidth,
    CoreColor? tileBackgroundColor,
    CoreColor? tileSelectedBackgroundColor,
    CoreColor? tileBorderColor,
    CoreColor? tileSelectedBorderColor,
  }) {
    return CoreRadioGroupStyle(
      indicatorBackgroundColor:
          indicatorBackgroundColor ?? this.indicatorBackgroundColor,
      indicatorActiveColor: indicatorActiveColor ?? this.indicatorActiveColor,
      indicatorBorderColor: indicatorBorderColor ?? this.indicatorBorderColor,
      indicatorBorderWidth: indicatorBorderWidth ?? this.indicatorBorderWidth,
      selectedIndicatorBorderWidth:
          selectedIndicatorBorderWidth ?? this.selectedIndicatorBorderWidth,
      indicatorSize: indicatorSize ?? this.indicatorSize,
      indicatorBorderRadius:
          indicatorBorderRadius ?? this.indicatorBorderRadius,
      innerDotSize: innerDotSize ?? this.innerDotSize,
      indicatorLabelGapStyle:
          indicatorLabelGapStyle ?? this.indicatorLabelGapStyle,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      colorTransitionDuration:
          colorTransitionDuration ?? this.colorTransitionDuration,
      dotTransitionDuration:
          dotTransitionDuration ?? this.dotTransitionDuration,
      indicatorDotStyle: indicatorDotStyle ?? this.indicatorDotStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      labelDescriptionGapStyle:
          labelDescriptionGapStyle ?? this.labelDescriptionGapStyle,
      stateLayer: stateLayer ?? this.stateLayer,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      stateLayerSpread: stateLayerSpread ?? this.stateLayerSpread,
      tilePadding: tilePadding ?? this.tilePadding,
      tileSelectedPadding: tileSelectedPadding ?? this.tileSelectedPadding,
      tileBorderRadius: tileBorderRadius ?? this.tileBorderRadius,
      tileBorderWidth: tileBorderWidth ?? this.tileBorderWidth,
      tileSelectedBorderWidth:
          tileSelectedBorderWidth ?? this.tileSelectedBorderWidth,
      tileBackgroundColor: tileBackgroundColor ?? this.tileBackgroundColor,
      tileSelectedBackgroundColor:
          tileSelectedBackgroundColor ?? this.tileSelectedBackgroundColor,
      tileBorderColor: tileBorderColor ?? this.tileBorderColor,
      tileSelectedBorderColor:
          tileSelectedBorderColor ?? this.tileSelectedBorderColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRadioGroupStyle &&
          runtimeType == other.runtimeType &&
          indicatorBackgroundColor == other.indicatorBackgroundColor &&
          indicatorActiveColor == other.indicatorActiveColor &&
          indicatorBorderColor == other.indicatorBorderColor &&
          indicatorBorderWidth == other.indicatorBorderWidth &&
          selectedIndicatorBorderWidth == other.selectedIndicatorBorderWidth &&
          indicatorSize == other.indicatorSize &&
          indicatorBorderRadius == other.indicatorBorderRadius &&
          innerDotSize == other.innerDotSize &&
          indicatorLabelGapStyle == other.indicatorLabelGapStyle &&
          itemSpacing == other.itemSpacing &&
          colorTransitionDuration == other.colorTransitionDuration &&
          dotTransitionDuration == other.dotTransitionDuration &&
          indicatorDotStyle == other.indicatorDotStyle &&
          labelStyle == other.labelStyle &&
          descriptionStyle == other.descriptionStyle &&
          labelDescriptionGapStyle == other.labelDescriptionGapStyle &&
          stateLayer == other.stateLayer &&
          stateLayerColor == other.stateLayerColor &&
          stateLayerSpread == other.stateLayerSpread &&
          tilePadding == other.tilePadding &&
          tileSelectedPadding == other.tileSelectedPadding &&
          tileBorderRadius == other.tileBorderRadius &&
          tileBorderWidth == other.tileBorderWidth &&
          tileSelectedBorderWidth == other.tileSelectedBorderWidth &&
          tileBackgroundColor == other.tileBackgroundColor &&
          tileSelectedBackgroundColor == other.tileSelectedBackgroundColor &&
          tileBorderColor == other.tileBorderColor &&
          tileSelectedBorderColor == other.tileSelectedBorderColor;

  @override
  int get hashCode => Object.hashAll([
    indicatorBackgroundColor,
    indicatorActiveColor,
    indicatorBorderColor,
    indicatorBorderWidth,
    selectedIndicatorBorderWidth,
    indicatorSize,
    indicatorBorderRadius,
    innerDotSize,
    indicatorLabelGapStyle,
    itemSpacing,
    colorTransitionDuration,
    dotTransitionDuration,
    indicatorDotStyle,
    labelStyle,
    descriptionStyle,
    labelDescriptionGapStyle,
    stateLayer,
    stateLayerColor,
    stateLayerSpread,
    tilePadding,
    tileSelectedPadding,
    tileBorderRadius,
    tileBorderWidth,
    tileSelectedBorderWidth,
    tileBackgroundColor,
    tileSelectedBackgroundColor,
    tileBorderColor,
    tileSelectedBorderColor,
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

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Visual style definition for a [CoreRadioGroupVariant].
///
/// Defines colours for: active (selected) indicator, unchecked border /
/// background, and disabled states. All values are platform-neutral
/// ([CoreColor]); the consuming renderer converts at use-site (Flutter
/// via `scheme.resolve(...).toValue()`; Web via `'bg-${color}'` /
/// `var(--coui-*)`).
@immutable
class CoreRadioGroupVariantStyle {
  /// Creates a radio group variant style.
  const CoreRadioGroupVariantStyle({
    required this.activeColor,
    required this.borderColor,
    required this.uncheckedBackground,
    required this.disabledActiveColor,
    required this.disabledBorderColor,
    required this.disabledBackgroundColor,
    required this.disabledForegroundColor,
  });

  // === Selected ===

  /// Active indicator colour when selected.
  final CoreColor activeColor;

  // === Unchecked ===

  /// Border colour when unchecked.
  final CoreColor borderColor;

  /// Background colour when unchecked.
  final CoreColor uncheckedBackground;

  // === Disabled ===

  /// Active indicator colour when disabled + selected — the colour of the
  /// selected ring (and of a dot, when one is restated).
  final CoreColor disabledActiveColor;

  /// Ring colour when disabled + unselected. A disabled selected ring wears
  /// [disabledActiveColor] instead.
  final CoreColor disabledBorderColor;

  /// Background colour when disabled.
  final CoreColor disabledBackgroundColor;

  /// Foreground (label text) colour when disabled.
  final CoreColor disabledForegroundColor;
}
