/// Per-instance style for `DescriptionCard`.
library;

import 'package:collection/collection.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_card_size.dart';
import 'package:coui_core/src/component/contracts/description_card/core_description_card_variant.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_align.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `DescriptionCard` should render.
///
/// `CoreDescriptionCardStyle` carries:
/// - the card panel chrome (bg / border / radius / padding / shadow /
///   divider colour),
/// - per-size dimensional gaps (`rowSpacing` double + `columnGapStyle`
///   / `iconLabelGapStyle` / `labelValueGapStyle` / `titleContentGapStyle`
///   / `rowLeadingGapStyle` nested `CoreGapStyle` slots) that previously
///   lived in `CoreDescriptionCardSizeTokens`,
/// - the per-row default text slot styles (label / value / title), each
///   exposed as a nested `CoreTextStyle` for full typographic
///   control (fontSize / fontWeight / letterSpacing / color),
/// - the emphasised text slot styles applied to `isEmphasized: true`
///   rows ([emphasizedLabelTextStyle] / [emphasizedValueTextStyle]).
///
/// Single resolve chain (Epic #1302 / Epic #1370 phase 5 / #1696
/// Phase 3 Tokens 폐기):
///
/// ```text
/// design system default (CoreDescriptionCardStyle.defaultsBySize[size])
///   → theme.descriptionCard.style
///   → parent component slot override
///   → widget.descriptionCardStyle
///   → per-row labelTextStyle / valueTextStyle
/// ```
///
/// Semantic enums (`variant`, `size`, `layout`, `alignment`,
/// `valueOverflow`, `rowWeight`, `emptyValueBehavior`) and boolean
/// toggles (`showDivider`, `showRowDividers`,
/// `showBottomActionDivider`) stay on the widget / contract — only
/// chrome / dimensional / nested-slot overrides belong here
/// (Epic #1302 원칙 6/7).
@immutable
class CoreDescriptionCardStyle implements CoreStyle<CoreDescriptionCardStyle> {
  /// Creates a [CoreDescriptionCardStyle].
  const CoreDescriptionCardStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.boxShadow,
    this.shadowBaseColor,
    this.dividerColor,
    this.titleColor,
    this.rowSpacing,
    this.rowPadding,
    this.columnGapStyle,
    this.iconLabelGapStyle,
    this.labelValueGapStyle,
    this.titleContentGapStyle,
    this.rowLeadingGapStyle,
    this.labelTextStyle,
    this.valueTextStyle,
    this.titleTextStyle,
    this.titleLeadingIconStyle,
    this.valueTextAlign,
    this.disabledContentOpacity,
    this.emphasizedLabelTextStyle,
    this.emphasizedValueTextStyle,
    this.clickableStyle,
  });

  // ─── Design-system defaults (Epic #1484 Phase 6g / #1696 Phase 3) ──
  // Variant-independent defaults live as static const on this class.
  // Variant-dependent chrome (background / border colour / border-width)
  // is supplied by [defaultsByVariant]. Per-size dimensional + typography
  // defaults flow through [defaultsBySize]. Both Flutter and Web read
  // from the same constants so chrome stays in sync across platforms.

  /// Default title slot text colour.
  static const CoreColor defaultTitleColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default inline gap-style between row leading icon and label.
  /// The vertical-layout `rowLeadingBlock` forwards this slot straight
  /// to `Gap(gapStyle: …)` (Epic #1659 — nested `CoreGapStyle` slot
  /// instead of a flat double).
  static const CoreGapStyle defaultRowLeadingGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
    crossAxisExtent: 0,
  );

  /// Default divider line colour (title / inter-row / bottom-action
  /// separators inside the card). Matches `Divider`'s own shared
  /// default (#4815 디자이너 결정 #1) rather than the card's outer
  /// border token — the divider is a thinner, quieter separator than
  /// the card edge.
  static const CoreColor defaultDividerColor = CoreColor.token(
    CoreColors.outlineVariant,
    fallbacks: [CoreColors.outline],
  );

  /// Default shadow base colour used as the foundation of any
  /// elevation shadow stack.
  /// The shadow tint. Stated by the palette rather than chosen here — a
  /// component has no way to know whether the page it lands on is light or
  /// dark. The palette states one colour and the theme's brightness sets
  /// how strongly it is drawn (`CoreShadow.darkStrength`), so the cast
  /// reads in either.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// The `md` row's corner. The corner moves with the size, so the default
  /// both resolvers read is `defaultsBySize[size].borderRadius`.
  @Deprecated(
    'Read defaultsBySize[size].borderRadius (since 0.190) — the corner '
    'now steps with the card size (xs 12 · sm 14 · md and up 16), so '
    'one constant no longer states it.',
  )
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// `Clickable` when the card (or a row) is tappable — a partial that
  /// pins `pressedScale: 1.0`. The card and a full-width row are wide
  /// blocks, so the press-shrink scale feedback that suits small boxed
  /// controls would visibly squash the whole surface. Everything else
  /// stays null and resolves inside the Clickable's own resolver via
  /// `defaultClickableStyle.merge(merged.clickableStyle)`.
  ///
  /// `disabledOpacity` is full strength: a disabled card dims its content
  /// itself ([disabledContentOpacity]) and keeps its background and
  /// border, so the `Clickable` around it must not dim the whole card a
  /// second time.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Default [disabledContentOpacity] — the design system's disabled
  /// share.
  static const double defaultDisabledContentOpacity = CoreOpacity.disabled;

  /// Weight laid over the per-size title role
  /// (`defaultsBySize[size].titleTextStyle`) before the caller's
  /// [titleTextStyle] — the title
  /// is SemiBold on every rung while its size, line height and tracking
  /// stay the role's. Only `fontWeight` is stated, so the role still
  /// decides everything else.
  static const CoreTextStyle defaultTitleTextStyle = CoreTextStyle(
    fontWeight: CoreFontWeight.semiBold,
  );

  /// Default horizontal alignment of a row's value text in the
  /// horizontal layouts — the value column reads flush against the
  /// card's trailing edge. The vertical layout stacks the value under
  /// its label and keeps it at the start.
  static const CoreTextAlign defaultValueTextAlign = CoreTextAlign.end;

  /// Per-variant default styles. Single source of truth shared by
  /// Flutter and Web — each platform resolves the [CoreColor] via its
  /// own extension (`.toValue()` / `scheme.resolve(...)`).
  static const Map<CoreDescriptionCardVariant, CoreDescriptionCardVariantStyle>
  defaultsByVariant = {
    CoreDescriptionCardVariant.filled: CoreDescriptionCardVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      borderWidth: 0,
    ),
    CoreDescriptionCardVariant.outlined: CoreDescriptionCardVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
      borderWidth: CoreStrokeWidth.stroke1,
      borderColor: CoreColor.token(CoreColors.outlineVariant),
    ),
    // ghost — null background = transparent (Web `bg-transparent`,
    // Flutter `Colors.transparent`). Single source of truth at the
    // variant-style layer; renderers map null to their transparent
    // primitive.
    // ghost also drops the left / right inset: with no fill or border
    // there is no box edge to inset from, so the content lines up with
    // whatever the card sits in.
    CoreDescriptionCardVariant.ghost: CoreDescriptionCardVariantStyle(
      backgroundColor: null,
      borderWidth: 0,
      padsHorizontally: false,
    ),
  };

  /// Per-size default chrome (dimensional padding / gaps + typography
  /// roles) — single source of truth shared by Flutter and Web.
  ///
  /// The map value is `CoreDescriptionCardStyle` itself so the flat
  /// slot fields stay 1:1 with the per-size defaults — no separate
  /// typedef record holder (contract.md "defaultsBySize 값은
  /// CoreXxxStyle 자체").
  ///
  /// Internally stitches `_dimensionalDefaultsBySize` (const-friendly
  /// padding / gap slots) and `_typographyDefaultsBySize` (typography
  /// role refs) via `merge` so that:
  ///
  /// - Flutter consumes the `CoreEdgeInsets` / `double` / `CoreTextStyle`
  ///   values directly (logical px / typography role lookup via
  ///   `resolveTypographyRole`).
  /// - Web consumes the same values via the common adapters in
  ///   `core_to_css.dart`: `tailwindSpace` for gap classes,
  ///   `tailwindTypographyRole` for typography role keys
  ///   (`'label-small'` …).
  static final Map<CoreDescriptionCardSize, CoreDescriptionCardStyle>
  defaultsBySize = {
    for (final size in CoreDescriptionCardSize.values)
      size: _dimensionalDefaultsBySize[size]!.merge(
        _typographyDefaultsBySize[size],
      ),
  };

  // ── Panel chrome (flat) ──────────────────────

  /// Card background fill colour.
  final CoreColor? backgroundColor;

  /// Card border stroke colour.
  final CoreColor? borderColor;

  /// Card border stroke width (logical px, pre-scaling).
  final double? borderWidth;

  /// Card corner override. Defaults come from [defaultsBySize] — 12 at xs,
  /// 14 at sm, 16 from md up.
  final CoreBorderRadius? borderRadius;

  /// Card content padding override.
  final CoreEdgeInsets? padding;

  /// Card box shadow override.
  ///
  /// Deliberately without a `default*`: absence is what keeps the card
  /// flat. Both resolvers gate the shadow on this being set — Web emits
  /// no `box-shadow` property at all, Flutter hands `BoxDecoration` a
  /// null `boxShadow` — so a default lifts every description card off the
  /// page, and even an empty stack is not a no-op (it emits
  /// `box-shadow: none` on every card instead of emitting nothing). The
  /// elevation this card would cast if it were raised
  /// is a per-instance decision; only its tint is design-system-owned,
  /// which is why [shadowBaseColor] has a default and this does not.
  final List<CoreShadowLayer>? boxShadow;

  /// Shadow base colour override — foundation of the elevation shadow
  /// stack. Defaults to [defaultShadowBaseColor] when unset.
  final CoreColor? shadowBaseColor;

  /// Divider line colour (title / inter-row / bottom-action
  /// separators inside the card).
  final CoreColor? dividerColor;

  /// Title slot text colour override. Defaults to [defaultTitleColor]
  /// when unset.
  final CoreColor? titleColor;

  // ── Per-size dimensional ─────────────────────

  /// Vertical spacing between rows (logical px). Drives the
  /// `Column`-spacing-equivalent main-axis distance between consecutive
  /// rows. Stays a flat double — the rows wrapper consumes this scalar
  /// either via `gap-${tailwindSpace}` (Web) or `Gap` (Flutter).
  final double? rowSpacing;

  /// Inset around each row's content. The default is vertical only —
  /// rows sit edge to edge and the divider under each row (but the last)
  /// lands at the bottom of this inset. Defaults come from
  /// [defaultsBySize].
  final CoreEdgeInsets? rowPadding;

  /// Horizontal gap between label and value in horizontal layouts, passed
  /// to `Gap(gapStyle: …)` on both platforms.
  final CoreGapStyle? columnGapStyle;

  /// Gap between a leading or trailing icon and the text next to it, in
  /// the title and in each row, passed to `Gap(gapStyle: …)`. A
  /// vertical-layout row's leading icon takes [rowLeadingGapStyle] instead.
  final CoreGapStyle? iconLabelGapStyle;

  /// Gap between label and value in the vertical layout, passed to
  /// `Gap(gapStyle: …)` on both platforms.
  final CoreGapStyle? labelValueGapStyle;

  /// Vertical spacing around the title divider and the bottom-action
  /// separator, passed to `Gap(gapStyle: …)`. Defaults come from
  /// [defaultsBySize].
  final CoreGapStyle? titleContentGapStyle;

  /// Gap between a row's leading icon and its label in the vertical
  /// layout, passed to `Gap(gapStyle: …)`. Defaults to
  /// [defaultRowLeadingGapStyle] when unset.
  final CoreGapStyle? rowLeadingGapStyle;

  // ── Slot Styles (nested) ─────────────────────

  /// Default label text slot style (per-row, before emphasis).
  /// Exposes the full typographic surface (fontSize / fontWeight
  /// / letterSpacing / color).
  final CoreTextStyle? labelTextStyle;

  /// Default value text slot style (per-row, before emphasis).
  final CoreTextStyle? valueTextStyle;

  /// Title text slot style. Laid over the per-size role and
  /// [defaultTitleTextStyle] (SemiBold).
  final CoreTextStyle? titleTextStyle;

  /// Size and colour an icon handed to `titleLeading` draws at — an
  /// `Icon` there without its own size or colour takes these. Defaults
  /// come from [defaultsBySize] (16 at xs · sm, 18 at md, 20 at lg · xl,
  /// `onSurfaceVariant`).
  ///
  /// Both widgets hand it to that slot as the ambient icon theme.
  final CoreIconStyle? titleLeadingIconStyle;

  /// Horizontal alignment of a row's value text in the horizontal
  /// layouts. Defaults to [defaultValueTextAlign] (end).
  final CoreTextAlign? valueTextAlign;

  /// Opacity of the card's content — the title, the rows and the bottom
  /// action region, with their icons and dividers — while the card is
  /// disabled (`enabled: false` on a card with a tap target). The
  /// background and border stay at full strength. Defaults to
  /// [defaultDisabledContentOpacity].
  final double? disabledContentOpacity;

  /// Emphasised label text slot style (applied to rows with
  /// `isEmphasized: true`).
  ///
  /// Deliberately without a `default*`: emphasis is carried by the row's
  /// *value* (see [emphasizedValueTextStyle]), and an emphasised row's
  /// label deliberately keeps the same style as every other label so the
  /// two columns still scan as columns. This slot exists for the caller
  /// who wants the label to move too; a default would restyle the label
  /// of every emphasised row in the kit.
  final CoreTextStyle? emphasizedLabelTextStyle;

  /// Emphasised value text slot style (applied to rows with
  /// `isEmphasized: true`).
  ///
  /// Deliberately without a `default*`: the emphasis weight is applied by
  /// both resolvers as an auto-bold that fires only when neither this
  /// slot nor the row's own `valueTextStyle` states a `fontWeight`, and
  /// only when the row has a value (an empty-value placeholder stays
  /// unemphasised). A default carrying a weight would suppress that
  /// branch and bold unconditionally — including the placeholders it
  /// currently skips — and a default without one would be a value that
  /// changes nothing. The condition cannot be expressed as a field
  /// default because it reads the row, not the style.
  final CoreTextStyle? emphasizedValueTextStyle;

  /// Style for the `Clickable` used when the card or a row is tappable —
  /// press scale, durations, focus ring, disabled opacity. Laid over
  /// [defaultClickableStyle] and passed to the `Clickable` as is; the
  /// `Clickable` fills in the remaining defaults.
  final CoreClickableStyle? clickableStyle;

  // ── Private size-default holders ───────────────
  //
  // `defaultsBySize` (public) stitches these two maps via `merge`.
  // Split into two because `CoreTypography.coui.X` is an instance-field
  // read which Dart forbids in constant expressions even though `coui`
  // itself is `static const`. Dimensional values stay `static const`
  // for compile-time evaluation; typography refs are `static final` so
  // each entry references the same singleton `CoreTextStyle` instance
  // (`identical(...)` reverse lookup in
  // `core_to_css.dart#tailwindTypographyRole` continues to work).
  //
  // Decision (reader-coverage judgment call): stay private. The public
  // `defaultsBySize` above is already the complete, merged, AST-readable
  // dispatch table an external walker needs — these two maps are pure
  // implementation split (a `static const`/`static final` split forced by
  // the `CoreTypography.coui.X` constant-expression restriction noted
  // above), not additional coverage. Promoting them to public would add
  // two more surface entries with no new information the merged table
  // doesn't already carry, and a naive external walker would double-count
  // each field (once per private map, once in the public merge). An
  // AST-based reader can still see them if it ever needs the
  // pre-merge split (private members are visible to `parseString`).

  static const Map<CoreDescriptionCardSize, CoreDescriptionCardStyle>
  _dimensionalDefaultsBySize = {
    CoreDescriptionCardSize.xs: CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      padding: CoreEdgeInsets.all(CoreSpace.space12),
      rowSpacing: CoreSpace.space0,
      rowPadding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space6),
      columnGapStyle: CoreGapStyle(size: CoreSpace.space6),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelValueGapStyle: CoreGapStyle(size: CoreSpace.space2),
      titleContentGapStyle: CoreGapStyle(size: CoreSpace.space8),
      titleLeadingIconStyle: CoreIconStyle(
        size: CoreIconSize.size16,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
    CoreDescriptionCardSize.sm: CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
      padding: CoreEdgeInsets.all(CoreSpace.space14),
      rowSpacing: CoreSpace.space0,
      rowPadding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space6),
      columnGapStyle: CoreGapStyle(size: CoreSpace.space8),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelValueGapStyle: CoreGapStyle(size: CoreSpace.space2),
      titleContentGapStyle: CoreGapStyle(size: CoreSpace.space8),
      titleLeadingIconStyle: CoreIconStyle(
        size: CoreIconSize.size16,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
    CoreDescriptionCardSize.md: CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      padding: CoreEdgeInsets.all(CoreSpace.space16),
      rowSpacing: CoreSpace.space0,
      rowPadding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space8),
      columnGapStyle: CoreGapStyle(size: CoreSpace.space12),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelValueGapStyle: CoreGapStyle(size: CoreSpace.space4),
      titleContentGapStyle: CoreGapStyle(size: CoreSpace.space10),
      titleLeadingIconStyle: CoreIconStyle(
        size: CoreIconSize.size18,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
    CoreDescriptionCardSize.lg: CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      padding: CoreEdgeInsets.all(CoreSpace.space18),
      rowSpacing: CoreSpace.space0,
      rowPadding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space8),
      columnGapStyle: CoreGapStyle(size: CoreSpace.space16),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelValueGapStyle: CoreGapStyle(size: CoreSpace.space6),
      titleContentGapStyle: CoreGapStyle(size: CoreSpace.space10),
      titleLeadingIconStyle: CoreIconStyle(
        size: CoreIconSize.size20,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
    CoreDescriptionCardSize.xl: CoreDescriptionCardStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      padding: CoreEdgeInsets.all(CoreSpace.space20),
      rowSpacing: CoreSpace.space0,
      rowPadding: CoreEdgeInsets.symmetric(vertical: CoreSpace.space10),
      columnGapStyle: CoreGapStyle(size: CoreSpace.space20),
      iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space8),
      labelValueGapStyle: CoreGapStyle(size: CoreSpace.space8),
      titleContentGapStyle: CoreGapStyle(size: CoreSpace.space12),
      titleLeadingIconStyle: CoreIconStyle(
        size: CoreIconSize.size20,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
  };

  static final Map<CoreDescriptionCardSize, CoreDescriptionCardStyle>
  _typographyDefaultsBySize = {
    CoreDescriptionCardSize.xs: CoreDescriptionCardStyle(
      labelTextStyle: CoreTypography.coui.bodyXs,
      valueTextStyle: CoreTypography.coui.labelSmall,
      titleTextStyle: CoreTypography.coui.labelMedium,
    ),
    CoreDescriptionCardSize.sm: CoreDescriptionCardStyle(
      labelTextStyle: CoreTypography.coui.bodySmall,
      valueTextStyle: CoreTypography.coui.labelMedium,
      titleTextStyle: CoreTypography.coui.labelLarge,
    ),
    CoreDescriptionCardSize.md: CoreDescriptionCardStyle(
      labelTextStyle: CoreTypography.coui.bodyMedium,
      valueTextStyle: CoreTypography.coui.labelLarge,
      titleTextStyle: CoreTypography.coui.labelXl,
    ),
    CoreDescriptionCardSize.lg: CoreDescriptionCardStyle(
      labelTextStyle: CoreTypography.coui.bodyLarge,
      valueTextStyle: CoreTypography.coui.labelXl,
      titleTextStyle: CoreTypography.coui.labelXl2,
    ),
    CoreDescriptionCardSize.xl: CoreDescriptionCardStyle(
      labelTextStyle: CoreTypography.coui.bodyLarge,
      valueTextStyle: CoreTypography.coui.labelXl2,
      titleTextStyle: CoreTypography.coui.titleLarge,
    ),
  };

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested text styles are
  /// merged recursively.
  @override
  CoreDescriptionCardStyle merge(CoreDescriptionCardStyle? other) {
    if (other == null) return this;
    return CoreDescriptionCardStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      boxShadow: other.boxShadow ?? boxShadow,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
      dividerColor: other.dividerColor ?? dividerColor,
      titleColor: other.titleColor ?? titleColor,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      rowPadding: other.rowPadding ?? rowPadding,
      columnGapStyle: _mergeGap(columnGapStyle, other.columnGapStyle),
      iconLabelGapStyle: _mergeGap(iconLabelGapStyle, other.iconLabelGapStyle),
      labelValueGapStyle: _mergeGap(
        labelValueGapStyle,
        other.labelValueGapStyle,
      ),
      titleContentGapStyle: _mergeGap(
        titleContentGapStyle,
        other.titleContentGapStyle,
      ),
      rowLeadingGapStyle: _mergeGap(
        rowLeadingGapStyle,
        other.rowLeadingGapStyle,
      ),
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      valueTextStyle: _mergeText(valueTextStyle, other.valueTextStyle),
      titleTextStyle: _mergeText(titleTextStyle, other.titleTextStyle),
      titleLeadingIconStyle:
          titleLeadingIconStyle?.merge(other.titleLeadingIconStyle) ??
          other.titleLeadingIconStyle,
      valueTextAlign: other.valueTextAlign ?? valueTextAlign,
      disabledContentOpacity:
          other.disabledContentOpacity ?? disabledContentOpacity,
      emphasizedLabelTextStyle: _mergeText(
        emphasizedLabelTextStyle,
        other.emphasizedLabelTextStyle,
      ),
      emphasizedValueTextStyle: _mergeText(
        emphasizedValueTextStyle,
        other.emphasizedValueTextStyle,
      ),
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreDescriptionCardStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    List<CoreShadowLayer>? boxShadow,
    CoreColor? shadowBaseColor,
    CoreColor? dividerColor,
    CoreColor? titleColor,
    double? rowSpacing,
    CoreEdgeInsets? rowPadding,
    CoreGapStyle? columnGapStyle,
    CoreGapStyle? iconLabelGapStyle,
    CoreGapStyle? labelValueGapStyle,
    CoreGapStyle? titleContentGapStyle,
    CoreGapStyle? rowLeadingGapStyle,
    CoreTextStyle? labelTextStyle,
    CoreTextStyle? valueTextStyle,
    CoreTextStyle? titleTextStyle,
    CoreIconStyle? titleLeadingIconStyle,
    CoreTextAlign? valueTextAlign,
    double? disabledContentOpacity,
    CoreTextStyle? emphasizedLabelTextStyle,
    CoreTextStyle? emphasizedValueTextStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreDescriptionCardStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      boxShadow: boxShadow ?? this.boxShadow,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
      dividerColor: dividerColor ?? this.dividerColor,
      titleColor: titleColor ?? this.titleColor,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      rowPadding: rowPadding ?? this.rowPadding,
      columnGapStyle: columnGapStyle ?? this.columnGapStyle,
      iconLabelGapStyle: iconLabelGapStyle ?? this.iconLabelGapStyle,
      labelValueGapStyle: labelValueGapStyle ?? this.labelValueGapStyle,
      titleContentGapStyle: titleContentGapStyle ?? this.titleContentGapStyle,
      rowLeadingGapStyle: rowLeadingGapStyle ?? this.rowLeadingGapStyle,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      valueTextStyle: valueTextStyle ?? this.valueTextStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      titleLeadingIconStyle:
          titleLeadingIconStyle ?? this.titleLeadingIconStyle,
      valueTextAlign: valueTextAlign ?? this.valueTextAlign,
      disabledContentOpacity:
          disabledContentOpacity ?? this.disabledContentOpacity,
      emphasizedLabelTextStyle:
          emphasizedLabelTextStyle ?? this.emphasizedLabelTextStyle,
      emphasizedValueTextStyle:
          emphasizedValueTextStyle ?? this.emphasizedValueTextStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDescriptionCardStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          const ListEquality<CoreShadowLayer>().equals(
            boxShadow,
            other.boxShadow,
          ) &&
          shadowBaseColor == other.shadowBaseColor &&
          dividerColor == other.dividerColor &&
          titleColor == other.titleColor &&
          rowSpacing == other.rowSpacing &&
          rowPadding == other.rowPadding &&
          columnGapStyle == other.columnGapStyle &&
          iconLabelGapStyle == other.iconLabelGapStyle &&
          labelValueGapStyle == other.labelValueGapStyle &&
          titleContentGapStyle == other.titleContentGapStyle &&
          rowLeadingGapStyle == other.rowLeadingGapStyle &&
          labelTextStyle == other.labelTextStyle &&
          valueTextStyle == other.valueTextStyle &&
          titleTextStyle == other.titleTextStyle &&
          titleLeadingIconStyle == other.titleLeadingIconStyle &&
          valueTextAlign == other.valueTextAlign &&
          disabledContentOpacity == other.disabledContentOpacity &&
          emphasizedLabelTextStyle == other.emphasizedLabelTextStyle &&
          emphasizedValueTextStyle == other.emphasizedValueTextStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    boxShadow,
    shadowBaseColor,
    dividerColor,
    titleColor,
    rowSpacing,
    rowPadding,
    columnGapStyle,
    iconLabelGapStyle,
    labelValueGapStyle,
    titleContentGapStyle,
    rowLeadingGapStyle,
    labelTextStyle,
    valueTextStyle,
    titleTextStyle,
    titleLeadingIconStyle,
    valueTextAlign,
    disabledContentOpacity,
    emphasizedLabelTextStyle,
    emphasizedValueTextStyle,
    clickableStyle,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
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

/// Visual style definition for a [CoreDescriptionCardVariant].
///
/// Carries the variant-dependent chrome (background / border /
/// border-width). All values are platform-neutral ([CoreColor] /
/// `double`); the consuming renderer converts at use-site. `null`
/// `backgroundColor` denotes a transparent background.
@immutable
class CoreDescriptionCardVariantStyle {
  /// Creates a description card variant style.
  const CoreDescriptionCardVariantStyle({
    required this.backgroundColor,
    required this.borderWidth,
    this.borderColor,
    this.padsHorizontally = true,
  });

  /// Background colour. `null` denotes a transparent background.
  final CoreColor? backgroundColor;

  /// Border colour. `null` for variants without a visible border.
  final CoreColor? borderColor;

  /// Border width (logical px, pre-scaling).
  final double borderWidth;

  /// Whether the card keeps the size row's left / right padding. `false`
  /// zeroes both sides of the default padding (a caller `padding` still
  /// wins whole) — the `ghost` variant has no box edge to inset from.
  final bool padsHorizontally;

  /// The card padding this variant draws for a size row's [sizePadding]:
  /// the row as is, or with its left / right sides at `0` when
  /// [padsHorizontally] is `false`. Both platforms' resolvers call this so
  /// the rule lives in one place.
  CoreEdgeInsets paddingFor(CoreEdgeInsets sizePadding) => padsHorizontally
      ? sizePadding
      : sizePadding.copyWith(left: CoreSpace.space0, right: CoreSpace.space0);
}
