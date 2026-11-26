/// Per-instance style for `Dock`.
library;

import 'dart:math' as math;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/dock/core_dock_size.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/surface/liquid_morph_spring.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Dock` should render.
///
/// `CoreDockStyle` carries chrome flat fields (background / border
/// colours + active / inactive item colours), the dock bar's minimum
/// height, and nested style slots for the rendered item label text and
/// item icon.
///
/// ```text
/// design system default (CoreDockStyle.defaultX / defaultsBySize)
///   → CoreDockTheme.style                           // 프로젝트 공통
///   → parent component slot override
///   → widget.dockStyle                              // 인스턴스별
/// ```
@immutable
class CoreDockStyle implements CoreStyle<CoreDockStyle> {
  /// Creates a [CoreDockStyle].
  const CoreDockStyle({
    this.height,
    this.padding,
    this.barRadius,
    this.barMargin,
    this.itemIconLabelGapStyle,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.activeColor,
    this.inactiveColor,
    this.labelTextStyle,
    this.iconStyle,
    this.clickableStyle,
    this.activeLabelStyle,
    this.inactiveLabelStyle,
    this.indicatorColor,
    this.indicatorRadius,
    this.indicatorPadding,
    this.indicatorSpring,
    this.itemSpacing,
    this.itemWidth,
    this.boxShadow,
    this.shadowBaseColor,
  });

  // ── Dimensional defaults (variant-independent) ──

  /// The bar's padding before it became a per-size value.
  @Deprecated(
    'Read defaultsBySize[size].padding (since 0.190) — the bar is padded '
    'per size now, 6 above and below and 8 beside at xs and sm, 10 all '
    'round from md up, and neither resolver reads this.',
  )
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space8,
  );

  /// The bar's corners before they became a per-size value.
  @Deprecated(
    'Read defaultsBySize[size].barRadius (since 0.190) — the bar is rounded '
    'per size now, 10 at xs and sm and 16 from md up, and neither resolver '
    'reads this.',
  )
  static const CoreBorderRadius defaultBarRadius = CoreBorderRadius.zero;

  /// Default space outside the bar — none, so the bar sits flush.
  ///
  /// Zero is what keeps a docked bar against its edge; a non-zero
  /// [barMargin] is what detaches a floating one.
  ///
  /// Authoritative for Flutter only: the Web resolver omits the margin
  /// declaration while the override is absent, which renders the same zero.
  /// Editing this value floats the Flutter bar and leaves the Web one flush.
  static const CoreEdgeInsets defaultBarMargin = CoreEdgeInsets.zero;

  /// Default gap slot between an item's icon and label. Carries the
  /// design-system gap size; the per-instance [itemIconLabelGapStyle]
  /// merges on top so the resolved gap rides a single [CoreGapStyle]
  /// (Epic #1603 옵션 B nested-slot pattern). Shared by Flutter and
  /// Web resolvers.
  static const CoreGapStyle defaultItemIconLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Small (`sm`) dock icon size — not on the `CoreIconSize` ladder
  /// (`…18, 20, 24, 28, 32…` has no `22` step), so exposed as a named
  /// Style-level constant rather than a bare literal (#3471).
  ///
  /// Decision (kept, not moved to the nearest ladder step): the five
  /// `defaultsBySize` icon sizes read `20, 22, 24, 28, 32` — increments
  /// of `2, 2, 4, 4`, a deliberately smooth taper (small steps between
  /// the small sizes, larger steps between the large ones) against
  /// `height`'s own even `48, 56, 64, 72, 80` (+8 each step). Snapping to
  /// either neighbour collapses that taper into a flat step —
  /// `20, 20, 24, 28, 32` (xs and sm icons identical) or
  /// `20, 24, 24, 28, 32` (sm and md icons identical) — trading a
  /// deliberate-looking five-point curve for an arbitrary-looking
  /// four-point one, for no documented gain. The `CoreIconSize` ladder's
  /// own gaps (`18 → 20 → 24`, `+2` then `+4`) were sized for its own
  /// callers and have no claim on a five-step per-component progression
  /// tuned against this component's own `height` column. No visual
  /// change from this decision — the value is unchanged, only the
  /// rationale is now recorded.
  static const double smIconSize = 22;

  /// Default icon style — `CoreIconStyle()` with no overrides. The
  /// resolver injects the per-size icon size from [defaultsBySize].
  static const CoreIconStyle defaultIconStyle = CoreIconStyle();

  // ── Active indicator defaults ──

  /// Default fill of the plate behind the active item's icon — the
  /// high container tone, one step above the bar's own surface.
  static const CoreColor defaultIndicatorColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// The plate's corners before they became a per-size value.
  @Deprecated(
    'Read defaultsBySize[size].indicatorRadius (since 0.190) — the plate is '
    'rounded per size now, 8 at xs and sm and 10 from md up, and neither '
    'resolver reads this.',
  )
  static const CoreBorderRadius defaultIndicatorRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// How far the plate extended past the whole item before it moved to the
  /// icon and became a per-size value.
  @Deprecated(
    'Read defaultsBySize[size].indicatorPadding (since 0.190) — the plate '
    'now sits behind the icon row and overhangs it per size, and neither '
    'resolver reads this.',
  )
  static const CoreEdgeInsets defaultIndicatorPadding =
      CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space6,
      );

  /// The tempo the pill travels between items at.
  ///
  /// A morph spring rather than a duration, because the travel is the
  /// morph engine's: the pill leaving one item and arriving at another is
  /// two bodies briefly one shape with a neck between them, which is the
  /// same silhouette a panel makes leaving its trigger. `fast`, because a
  /// bar is small and the flight is short — `normal` reads as sluggish
  /// over sixty pixels.
  static const CoreMorphSpring defaultIndicatorSpring = CoreMorphSpring(
    speed: CoreMorphSpeed.fast,
  );

  /// Default nested [CoreClickableStyle] slot for the `Clickable` the
  /// widgets compose around a tappable (`onPressed != null`) dock
  /// item — an empty partial: dock items take the Clickable's own
  /// standard press / focus / cursor chrome as-is. Named so the
  /// resolver's `defaultClickableStyle.merge(merged.clickableStyle)`
  /// forward has a single-source default.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle();

  // ── Chrome colour defaults (single source — no `cs.<token>`) ──

  /// Default dock bar background colour. Routed through this named
  /// default so both resolvers source the surface token from one place
  /// (layer-mapping.md "모든 디자인 값은 Core Style 단일 출처") instead of
  /// reading `theme.colorScheme.surface` / `cs.surface` directly.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default colour of the line around the bar.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default shadow of the bar — the floating-panel rung below the popup's
  /// (`CoreShadow.md`): the bar rides above the content it navigates.
  static const List<CoreShadowLayer> defaultBoxShadow = CoreShadow.md;

  /// Default colour the [boxShadow] layers tint against — the palette's
  /// shadow slot, which the theme's brightness strengthens on dark.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default width of the line around the bar.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default colour of the **active** item's icon. The label states its own
  /// colour in [defaultActiveLabelStyle].
  static const CoreColor defaultActiveColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default colour of the **inactive** items' icons. The label states its
  /// own colour in [defaultInactiveLabelStyle].
  static const CoreColor defaultInactiveColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  // ── Per-state label typography defaults ──

  /// Default label text style for the **active** item — the 11px
  /// `labelXs` role in on-surface, with a `semiBold` weight overlay
  /// (token-backed; the weight rides on top of the role so the role class
  /// stays dark-mode / accessibility-scale reactive). The per-instance
  /// [labelTextStyle] merges on top.
  ///
  /// The label carries its own colour rather than following [activeColor]:
  /// the current item's icon is drawn in primary and its name in the body
  /// text colour, and the weight is what tells the current name apart.
  static final CoreTextStyle defaultActiveLabelStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelXs,
        color: CoreColor.token(CoreColors.onSurface),
      ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default label text style for **inactive** items — the 11px `labelXs`
  /// role in on-surface-variant with a `medium` weight overlay (see
  /// [defaultActiveLabelStyle]).
  static final CoreTextStyle defaultInactiveLabelStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelXs,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ).copyWith(fontWeight: CoreFontWeight.medium);

  // ── Per-size values off the spacing scale ──

  /// How far the active plate reaches past the icon row on each side at
  /// `xs` and `sm`, where the item is its icon alone.
  ///
  /// Not on the spacing scale (`…2, 4, 6…`): the plate is the icon's own
  /// geometry — a 20px icon on a 26px plate — and the designer stated 3
  /// rather than rounding it to a step.
  static const double compactIndicatorReach = 3;

  /// How far the active plate reaches above and below the icon from `md`
  /// up, where the item is a fixed-width cell and the plate already spans
  /// it. Off the spacing scale for the reason [compactIndicatorReach]
  /// gives: the plate is the icon's 24px glyph on a 34px plate.
  static const double indicatorReach = 5;

  // ═══════════════════════════════════════════════════
  // Defaults — size-keyed
  // ═══════════════════════════════════════════════════

  /// Per-size default chrome — single source of truth shared by
  /// Flutter and Web.
  ///
  /// `height` is the bar's minimum height at that size (see [height]); the
  /// icon size is the glyph's.
  ///
  /// The map value is `CoreDockStyle` itself so the flat slot fields
  /// stay 1:1 with the per-size defaults (contract.md "defaultsBySize
  /// 값은 CoreXxxStyle 자체"). Both resolvers read
  /// `CoreDockStyle.defaultsBySize[size]!` and consume the entries as
  /// `CoreDockStyle` slots.
  ///
  /// Two bands: `xs` and `sm` draw the icon alone, so the bar is tight
  /// around it (6 above and below, 8 beside, apps 6 apart, corners 10) and
  /// the plate reaches 3 past the icon on every side, corners 8. From `md`
  /// up each app is a fixed-width cell with its name under the icon, so the
  /// bar opens to 10 all round, the apps sit 4 apart, the corners are 16,
  /// and the plate spans the cell and reaches 5 above and below the icon,
  /// corners 10.
  static const Map<CoreDockSize, CoreDockStyle> defaultsBySize = {
    CoreDockSize.xs: CoreDockStyle(
      height: CoreSize.size48,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space8,
        vertical: CoreSpace.space6,
      ),
      barRadius: CoreBorderRadius.all(CoreRadius.radius10),
      itemSpacing: CoreSpace.space6,
      iconStyle: CoreIconStyle(size: CoreIconSize.size20),
      indicatorRadius: CoreBorderRadius.all(CoreRadius.radius8),
      indicatorPadding: CoreEdgeInsets.all(compactIndicatorReach),
    ),
    CoreDockSize.sm: CoreDockStyle(
      height: CoreSize.size56,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space8,
        vertical: CoreSpace.space6,
      ),
      barRadius: CoreBorderRadius.all(CoreRadius.radius10),
      itemSpacing: CoreSpace.space6,
      iconStyle: CoreIconStyle(size: smIconSize),
      indicatorRadius: CoreBorderRadius.all(CoreRadius.radius8),
      indicatorPadding: CoreEdgeInsets.all(compactIndicatorReach),
    ),
    CoreDockSize.md: CoreDockStyle(
      height: CoreSize.size64,
      padding: CoreEdgeInsets.all(CoreSpace.space10),
      barRadius: CoreBorderRadius.all(CoreRadius.radius16),
      itemSpacing: CoreSpace.space4,
      itemWidth: CoreSize.size48,
      iconStyle: CoreIconStyle(size: CoreIconSize.size24),
      indicatorRadius: CoreBorderRadius.all(CoreRadius.radius10),
      indicatorPadding: CoreEdgeInsets.symmetric(
        vertical: indicatorReach,
      ),
    ),
    CoreDockSize.lg: CoreDockStyle(
      height: CoreSize.size72,
      padding: CoreEdgeInsets.all(CoreSpace.space10),
      barRadius: CoreBorderRadius.all(CoreRadius.radius16),
      itemSpacing: CoreSpace.space4,
      itemWidth: CoreSize.size56,
      iconStyle: CoreIconStyle(size: CoreIconSize.size28),
      indicatorRadius: CoreBorderRadius.all(CoreRadius.radius10),
      indicatorPadding: CoreEdgeInsets.symmetric(
        vertical: indicatorReach,
      ),
    ),
    CoreDockSize.xl: CoreDockStyle(
      height: CoreSize.size80,
      padding: CoreEdgeInsets.all(CoreSpace.space10),
      barRadius: CoreBorderRadius.all(CoreRadius.radius16),
      itemSpacing: CoreSpace.space4,
      itemWidth: CoreSize.size64,
      iconStyle: CoreIconStyle(size: CoreIconSize.size32),
      indicatorRadius: CoreBorderRadius.all(CoreRadius.radius10),
      indicatorPadding: CoreEdgeInsets.symmetric(
        vertical: indicatorReach,
      ),
    ),
  };

  // ── Chrome (flat) ────────────────────────────

  /// Minimum height of the dock bar, border included (logical px,
  /// pre-scaling). When null, falls back to [defaultsBySize] for the active
  /// [CoreDockSize].
  ///
  /// A floor, not a fixed height. While the item row — and the pill around
  /// its active item, which is why [indicatorClearanceFor] is part of the
  /// measure — fits, the bar is exactly this tall; when the row needs more
  /// room (larger text, a taller caller icon, a larger label style) the bar
  /// grows with it, and the items stay centred in it either way.
  ///
  /// Why the bar grows instead of the content giving way: an OS text-size
  /// setting enlarges the label and leaves the icon and this value where
  /// they were, so a fixed height ends up clipping content the user asked to
  /// see larger (WCAG 1.4.4 asks for 200% text without loss of content or
  /// function). Clamping the label's scale or hiding it would give that
  /// content up to keep a number; growing the bar costs a few pixels.
  final double? height;

  /// Padding inside the bar's line. When null, falls back to the size's
  /// [defaultsBySize] entry.
  ///
  /// Above and below, the bar keeps whichever is larger of this and the
  /// room the active plate needs ([rowInsetFor]) — the plate overhangs the
  /// icon without taking layout room, so a padding smaller than its reach
  /// would let it hang out of the bar.
  final CoreEdgeInsets? padding;

  /// The bar's own corners. When null, falls back to the size's
  /// [defaultsBySize] entry — 10 at `xs` and `sm`, 16 from `md` up.
  ///
  /// Distinct from the plate's corners: this rounds the bar, which is what
  /// makes it read as one object rather than a strip with buttons in it.
  final CoreBorderRadius? barRadius;

  /// Space between neighbouring apps (logical px, pre-scaling). When null,
  /// falls back to the size's [defaultsBySize] entry — 6 at `xs` and `sm`,
  /// 4 from `md` up.
  ///
  /// The apps are packed with this between them and centred in the bar;
  /// the bar does not spread them apart.
  final double? itemSpacing;

  /// Fixed width of each app's cell (logical px, pre-scaling), or `null`
  /// for a cell as wide as its content. When null, falls back to the size's
  /// [defaultsBySize] entry — none at `xs` and `sm`, where the cell is its
  /// icon, and 48 · 56 · 64 from `md` up, where the cell carries a name.
  ///
  /// Fixed so the names under the icons do not make the cells uneven: a
  /// long name wraps inside its cell instead of widening it.
  final double? itemWidth;

  /// Space outside the bar. When null, falls back to [defaultBarMargin] —
  /// none, so the bar sits flush against the edge.
  ///
  /// What detaches the bar from the edge it would otherwise sit flush
  /// against. Padding cannot express this — padding moves the items and
  /// leaves the bar's own box where it was.
  final CoreEdgeInsets? barMargin;

  /// Dock bar background colour.
  final CoreColor? backgroundColor;

  /// Colour of the line around the bar.
  final CoreColor? borderColor;

  /// Width of the line around the bar. When null, falls back to
  /// [defaultBorderWidth].
  ///
  /// Drawn on all four edges: the bar is rounded, and a line on one edge
  /// of a rounded box has nowhere to end.
  final double? borderWidth;

  /// The bar's shadow. When null, falls back to [defaultBoxShadow]; an
  /// empty list draws none.
  ///
  /// Painted outside the bar only, so a translucent bar (under a surface
  /// style) never shows its own shadow through itself.
  final List<CoreShadowLayer>? boxShadow;

  /// Colour the [boxShadow] layers tint against. When null, falls back to
  /// [defaultShadowBaseColor].
  final CoreColor? shadowBaseColor;

  /// Colour of the active item's icon. The label's colour is in
  /// [activeLabelStyle].
  final CoreColor? activeColor;

  /// Colour of the inactive items' icons. The labels' colour is in
  /// [inactiveLabelStyle].
  final CoreColor? inactiveColor;

  // ── Slot Styles (nested) ─────────────────────

  /// Gap slot between an item's icon and label. Forwarded straight to
  /// `Gap(gapStyle: …)` (Flutter) and to the label's `margin-top`
  /// (Web). Merges on top of [defaultItemIconLabelGapStyle].
  final CoreGapStyle? itemIconLabelGapStyle;

  /// Item label text style override (applies to both active and inactive),
  /// laid over each state's own label style. `null` adds nothing — this
  /// field has no default of its own.
  ///
  /// **Deliberately has no `default*` — the label's baseline is already
  /// decided, under the per-state names.** [defaultActiveLabelStyle] and
  /// [defaultInactiveLabelStyle] carry the `labelXs` role plus the
  /// weight that distinguishes the two states, and this slot merges *over*
  /// whichever of them applies. A constant would land on both states, so
  /// every field it names would collapse the active/inactive distinction
  /// for that field — a default weight here erases the semiBold-vs-medium
  /// contrast that tells a dock user which item is current.
  ///
  /// On Web it would also change where the typography lives: the resolver
  /// passes this as the override argument of
  /// `emitTypography(merged.labelTextStyle, labelDefault)`, which emits
  /// the role on a `text-{role}` class and only an *explicit* overlay
  /// inline. Non-null means every dock item gets inline typography
  /// shadowing that class.
  final CoreTextStyle? labelTextStyle;

  /// Active-item label text style override. Merged on top of
  /// [defaultActiveLabelStyle]; [labelTextStyle] then layers on top of
  /// the result (applies to both states).
  final CoreTextStyle? activeLabelStyle;

  /// Inactive-item label text style override. Merged on top of
  /// [defaultInactiveLabelStyle]; [labelTextStyle] then layers on top of
  /// the result (applies to both states).
  final CoreTextStyle? inactiveLabelStyle;

  /// Item icon style override (size + colour).
  final CoreIconStyle? iconStyle;

  /// Style for the `Clickable` around each tappable dock item — press
  /// scale, focus ring, durations, disabled opacity. Laid over
  /// [defaultClickableStyle] and passed to the `Clickable` as is; it fills
  /// the remaining fields with its own defaults.
  final CoreClickableStyle? clickableStyle;

  // ── Active indicator ─────────────────────────

  /// Fill of the plate drawn behind the active item's icon. When null,
  /// falls back to [defaultIndicatorColor]. `CoreColor.transparent` turns
  /// the plate off.
  final CoreColor? indicatorColor;

  /// Corners of the active plate. When null, falls back to the size's
  /// [defaultsBySize] entry — 8 at `xs` and `sm`, 10 from `md` up.
  final CoreBorderRadius? indicatorRadius;

  /// How far the active plate reaches past the icon row on each side. When
  /// null, falls back to the size's [defaultsBySize] entry.
  ///
  /// The icon row is the icon's height and the cell's width — the icon's
  /// own width where the cell has no [itemWidth] — so the plate is larger
  /// than the icon and sits behind it, not behind the name under it.
  ///
  /// The plate takes no layout room of its own, so the bar keeps at least
  /// this much clear above and below the item row ([indicatorClearanceFor])
  /// — the room that lets the plate stay inside the bar.
  final CoreEdgeInsets? indicatorPadding;

  /// The tempo the plate travels between items at when the active item
  /// changes. When null, falls back to [defaultIndicatorSpring].
  ///
  /// The travel itself is the morph engine's — both platforms hand the
  /// departing and arriving pills to `morphShapeAt` and carve the same
  /// Core outline — so this is the only knob on it.
  final CoreMorphSpring? indicatorSpring;

  /// The room the bar keeps above or below its item row for a padding side
  /// of [padding] and a plate padded by [indicatorPadding] (logical px):
  /// the larger of the two, so the padding is what a bar states and the
  /// plate still never hangs out of it.
  ///
  /// Both platforms read this one answer and bend it through their own
  /// spacing axis.
  static double rowInsetFor(
    double padding,
    CoreEdgeInsets indicatorPadding,
  ) => math.max(padding, indicatorClearanceFor(indicatorPadding));

  /// Whether the per-item label renders for the given [size]. `xs` /
  /// `sm` hide labels to match legacy visual behaviour; `md` / `lg` /
  /// `xl` show them.
  static bool labelVisibleFor(CoreDockSize size) => size != .xs && size != .sm;

  /// The room the bar keeps clear above and below its item row for a pill
  /// padded by [indicatorPadding] (logical px, the same on both edges).
  ///
  /// The pill overhangs its item without taking layout room, so a bar that
  /// sized itself to the item row alone would let the active pill hang out of
  /// its top and bottom edge as soon as the label grew taller than the
  /// minimum [height] leaves room for. Keeping this much clear on both edges
  /// is what makes the bar grow to contain the pill.
  ///
  /// The larger of the two vertical paddings, on both edges: the bar stays
  /// centred on the items (as it is with no pill) however unequal the
  /// pill's own overhang is. Both platforms read this one answer and each
  /// bends it through its own spacing axis, so a density that moves the
  /// pill's overhang moves the room kept for it.
  static double indicatorClearanceFor(CoreEdgeInsets indicatorPadding) =>
      math.max(indicatorPadding.top, indicatorPadding.bottom);

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreDockStyle merge(CoreDockStyle? other) {
    if (other == null) return this;
    return CoreDockStyle(
      height: other.height ?? height,
      padding: other.padding ?? padding,
      barRadius: other.barRadius ?? barRadius,
      barMargin: other.barMargin ?? barMargin,
      itemIconLabelGapStyle: _mergeGap(
        itemIconLabelGapStyle,
        other.itemIconLabelGapStyle,
      ),
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      activeColor: other.activeColor ?? activeColor,
      inactiveColor: other.inactiveColor ?? inactiveColor,
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      clickableStyle: _mergeClickable(clickableStyle, other.clickableStyle),
      activeLabelStyle: _mergeText(activeLabelStyle, other.activeLabelStyle),
      inactiveLabelStyle: _mergeText(
        inactiveLabelStyle,
        other.inactiveLabelStyle,
      ),
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorRadius: other.indicatorRadius ?? indicatorRadius,
      indicatorPadding: other.indicatorPadding ?? indicatorPadding,
      indicatorSpring: other.indicatorSpring ?? indicatorSpring,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      itemWidth: other.itemWidth ?? itemWidth,
      boxShadow: other.boxShadow ?? boxShadow,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreDockStyle copyWith({
    double? height,
    CoreEdgeInsets? padding,
    CoreBorderRadius? barRadius,
    CoreEdgeInsets? barMargin,
    CoreGapStyle? itemIconLabelGapStyle,
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreColor? activeColor,
    CoreColor? inactiveColor,
    CoreTextStyle? labelTextStyle,
    CoreIconStyle? iconStyle,
    CoreClickableStyle? clickableStyle,
    CoreTextStyle? activeLabelStyle,
    CoreTextStyle? inactiveLabelStyle,
    CoreColor? indicatorColor,
    CoreBorderRadius? indicatorRadius,
    CoreEdgeInsets? indicatorPadding,
    CoreMorphSpring? indicatorSpring,
    double? itemSpacing,
    double? itemWidth,
    List<CoreShadowLayer>? boxShadow,
    CoreColor? shadowBaseColor,
  }) {
    return CoreDockStyle(
      height: height ?? this.height,
      padding: padding ?? this.padding,
      barRadius: barRadius ?? this.barRadius,
      barMargin: barMargin ?? this.barMargin,
      itemIconLabelGapStyle:
          itemIconLabelGapStyle ?? this.itemIconLabelGapStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      activeLabelStyle: activeLabelStyle ?? this.activeLabelStyle,
      inactiveLabelStyle: inactiveLabelStyle ?? this.inactiveLabelStyle,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorRadius: indicatorRadius ?? this.indicatorRadius,
      indicatorPadding: indicatorPadding ?? this.indicatorPadding,
      indicatorSpring: indicatorSpring ?? this.indicatorSpring,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      itemWidth: itemWidth ?? this.itemWidth,
      boxShadow: boxShadow ?? this.boxShadow,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDockStyle &&
          runtimeType == other.runtimeType &&
          height == other.height &&
          padding == other.padding &&
          barRadius == other.barRadius &&
          barMargin == other.barMargin &&
          itemIconLabelGapStyle == other.itemIconLabelGapStyle &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          activeColor == other.activeColor &&
          inactiveColor == other.inactiveColor &&
          labelTextStyle == other.labelTextStyle &&
          iconStyle == other.iconStyle &&
          clickableStyle == other.clickableStyle &&
          activeLabelStyle == other.activeLabelStyle &&
          inactiveLabelStyle == other.inactiveLabelStyle &&
          indicatorColor == other.indicatorColor &&
          indicatorRadius == other.indicatorRadius &&
          indicatorPadding == other.indicatorPadding &&
          indicatorSpring == other.indicatorSpring &&
          itemSpacing == other.itemSpacing &&
          itemWidth == other.itemWidth &&
          _listEq(boxShadow, other.boxShadow) &&
          shadowBaseColor == other.shadowBaseColor;

  @override
  int get hashCode => Object.hashAll([
    height,
    padding,
    barRadius,
    barMargin,
    itemIconLabelGapStyle,
    backgroundColor,
    borderColor,
    borderWidth,
    activeColor,
    inactiveColor,
    labelTextStyle,
    iconStyle,
    clickableStyle,
    activeLabelStyle,
    inactiveLabelStyle,
    indicatorColor,
    indicatorRadius,
    indicatorPadding,
    indicatorSpring,
    itemSpacing,
    itemWidth,
    if (boxShadow == null) null else Object.hashAll(boxShadow!),
    shadowBaseColor,
  ]);

  static bool _listEq(List<CoreShadowLayer>? a, List<CoreShadowLayer>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreClickableStyle? _mergeClickable(
    CoreClickableStyle? base,
    CoreClickableStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
