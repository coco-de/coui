/// Per-instance style for `TabPane`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/tabs/tab_pane_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `TabPane` should render.
///
/// `TabPane` is the boxed tab + integrated content-panel component
/// (the legacy `TabPane`), or — with [CoreTabPaneVariant.editorStrip] —
/// the strip-only IDE editor chrome. The style carries the content-area
/// chrome, the tab-bar dimensions, and the nested per-tab slots — the
/// content text style, the composed `Clickable`'s style, and the in-tab
/// spacer ([labelBadgeGapStyle]) that separates a boxed tab's label
/// from whatever the item hangs beside it — a `CoreTabItem.badge`,
/// a `leading` glyph, a `trailing` close affordance.
///
/// ```text
/// CoreTabPaneStyle.defaultX / defaultsByVariant   // design system default
///   → CoreTabPaneTheme.style                      // 프로젝트 공통
///   → CoreTabPaneTheme.variantStyles[variant]     // 프로젝트 variant 별
///   → widget.tabPaneStyle                         // 인스턴스별
/// ```
@immutable
class CoreTabPaneStyle implements CoreStyle<CoreTabPaneStyle> {
  /// Creates a [CoreTabPaneStyle].
  const CoreTabPaneStyle({
    this.backgroundColor,
    this.stripBackgroundColor,
    this.borderColor,
    this.tabBorderColor,
    this.borderRadius,
    this.borderWidth,
    this.barHeight,
    this.tabPadding,
    this.tabSpacing,
    this.tabSeparatorColor,
    this.tabSeparatorWidth,
    this.dragOpacity,
    this.contentTextStyle,
    this.activeContentColor,
    this.inactiveContentColor,
    this.clickableStyle,
    this.labelBadgeGapStyle,
    this.indicatorColor,
    this.indicatorWidth,
    this.indicatorBorderRadius,
    this.barPadding,
    this.closeButtonStyle,
    this.closeIconStyle,
    this.slotIconStyle,
  });

  // ── Design-system defaults (Epic #1415 Phase 6f + #1696 Phase 6) ──

  /// Default content panel / tab background colour.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default container / tab border colour.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default FOCUSED tab-label colour (`onSurface`) — the colour the
  /// label already inherited from the ambient text scope, now stated so
  /// the unfocused one can differ from it.
  static const CoreColor defaultActiveContentColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default UNFOCUSED tab-label colour (`onSurfaceVariant`) — the same
  /// choice the sibling `CoreTabsStyle` makes for its underline variant.
  ///
  /// A COLOUR pair, not an opacity: `core/theme-axis-composition.md` —
  /// under forced colours the palette is substituted but alpha survives,
  /// so a state carried by opacity collapses into looking active while a
  /// state carried by colour does not.
  static const CoreColor defaultInactiveContentColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default inter-tab rule colour — `transparent`, meaning NOT DRAWN.
  ///
  /// Drawn on each tab's INLINE-END edge (so it follows reading direction,
  /// `cross-platform/localization.md`) and on every tab regardless of
  /// focus, which is what separates adjacent tabs when [tabSpacing] is
  /// zero and the caller wants a rule between them. The [editorStrip]
  /// preset states `transparent`: its tabs sit flush with nothing between
  /// them.
  ///
  /// It sits on the per-tab WRAPPER, not the tab box: the tab box carries
  /// a corner radius, and neither Flutter (`BoxDecoration` asserts
  /// "borderRadius can only be given on borders with uniform colors") nor
  /// Figma (one stroke paint per node) can give a rounded box a per-side
  /// stroke COLOUR. The wrapper has no radius, so all three surfaces draw
  /// the same picture with their own idiom.
  static const CoreColor defaultTabSeparatorColor = CoreColor.transparent;

  /// Default inter-tab rule thickness (1 logical px). Only consulted when
  /// [tabSeparatorColor] is stated.
  static const double defaultTabSeparatorWidth = CoreStrokeWidth.stroke1;

  /// Default tab-strip band colour — `transparent`, so the strip paints
  /// nothing and the panel's top rule shows through it exactly as before
  /// this field existed.
  ///
  /// A band is what turns this into an editor strip: because an unfocused
  /// tab paints no fill of its own, giving the strip a colour makes every
  /// unfocused tab read as that colour with no second field — and an
  /// `inactiveTabBackgroundColor` would only let the two drift apart.
  ///
  /// The band is painted behind the whole strip, edge to edge. The bar's
  /// bottom line ([borderColor]) is drawn above it, so the line you see is
  /// the boundary of the band, not a panel edge.
  static const CoreColor defaultStripBackgroundColor = CoreColor.transparent;

  /// Default focused-tab border colour (`outline`) — read only when a tab
  /// outline is wanted: both variant rows state `transparent`, so a pane
  /// that states none draws no outline.
  ///
  /// Separate from [defaultBorderColor] because the two are painted in
  /// different places (the focused tab's three sides vs the panel's four),
  /// and an editor-style strip needs the panel's rule while the tab
  /// carries none. `core/layer-mapping.md`: 값은 같지만 다른 곳에서
  /// 쓰이는가 → 분리.
  static const CoreColor defaultTabBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default container corner radius (16 logical px).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default container / tab border thickness (1 logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default tab-bar height (32 logical px) — a strip that states none. The
  /// [editorStrip] preset states its own [barHeight] (36), the [boxed] one 44.
  ///
  /// The strip's own row, not a control row — a theme density leaves it
  /// where it is, on both platforms. The bar is navigation that hosts tabs
  /// (`Tabs` items take this height when they state none), and tabs keep
  /// their own ladder (`CoreTabsStyle.defaultsBySize`, which the density
  /// does not move either): a bar that took the control ladder would part
  /// from the tabs it holds, and the focused tab's arc is capped at this
  /// height. The control ladder is for form controls that line up in one
  /// row (`CoreControlSize`), which this strip does not.
  static const double defaultBarHeight = CoreSize.size32;

  /// Default tab chip padding — see [tabPadding] for what it wraps. The
  /// [editorStrip] preset states its own.
  static const CoreEdgeInsets defaultTabPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space8,
    vertical: CoreSpace.space2,
  );

  /// Default inter-tab spacing (8 logical px) — applied as a trailing
  /// gap between adjacent boxed tabs in the scrollable bar.
  static const double defaultTabSpacing = CoreSpace.space8;

  /// Default drag-feedback opacity (50%) — applied to the reorder
  /// drag preview when a boxed tab is being dragged to a new
  /// position.
  static const double defaultDragOpacity = CoreOpacity.opacity50;

  /// Default tab-label typography role (`bodyMedium`) — the boxed strip's;
  /// the [editorStrip] preset states `codeSm`. Colour is
  /// omitted and neither platform's `TabPane` adds one, so the label
  /// inherits the ambient text colour. (The sibling `CoreTabsStyle`
  /// *does* layer a colour on top via its active/inactive fields — this
  /// component has no such pair, and the sentence that claimed it does
  /// was carried over from there.)
  static const CoreTextStyle defaultContentTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// Default nested [CoreClickableStyle] slot for the composed boxed-tab
  /// `Clickable` — an empty partial: boxed tabs take the Clickable's own
  /// standard press / focus / cursor chrome as-is, matching `Tabs`.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle();

  /// Default nested [CoreGapStyle] slot for the in-tab spacer (6
  /// logical px) — the step `TabPane` states on its own, independent of
  /// `CoreTabsStyle.defaultLabelBadgeGapStyle`. Raw-forwarded to the `Gap`
  /// widget (which self-scales), and only rendered beside a slot the item
  /// actually carries.
  static const CoreGapStyle defaultLabelBadgeGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default selected-tab indicator colour — `transparent`, meaning NOT
  /// DRAWN. Both rows state `primary`: the [boxed] row draws the bar along
  /// the tab's bottom edge, the [editorStrip] row along its top edge.
  static const CoreColor defaultIndicatorColor = CoreColor.transparent;

  /// Default selected-tab indicator thickness (2 logical px). Only consulted
  /// when [indicatorColor] is stated.
  static const double defaultIndicatorWidth = CoreStrokeWidth.stroke2;

  /// Default selected-tab indicator corner radius — flat. The [boxed] row
  /// states the two corners away from the bar's bottom line.
  static const CoreBorderRadius defaultIndicatorBorderRadius =
      CoreBorderRadius.zero;

  /// Default tab-bar inset — none: the tabs start at the bar's edge. The
  /// [boxed] row states a start / end inset so the tabs sit inside the
  /// card's corners.
  static const CoreEdgeInsets defaultBarPadding = CoreEdgeInsets.zero;

  /// Default nested [CoreButtonStyle] slot for the close affordance — an
  /// empty partial: a tab's close × takes the `Button` ghost `sm` row as-is
  /// (32 px tall, as wide as the row's glyph plus its horizontal padding),
  /// which is the boxed strip's close box. The [editorStrip] row states
  /// [editorStripCloseButtonStyle] on top.
  static const CoreButtonStyle defaultCloseButtonStyle = CoreButtonStyle();

  /// Default nested [CoreIconStyle] slot for the close glyph — an empty
  /// partial: the glyph takes the `Icon` size and the colour its ghost
  /// button hands down (so it follows the button through hover and
  /// disabled). The [editorStrip] row states [editorStripCloseIconStyle],
  /// which fixes the colour instead.
  static const CoreIconStyle defaultCloseIconStyle = CoreIconStyle();

  /// Default nested [CoreIconStyle] slot for the glyphs a tab carries in its
  /// `leading` / `trailing` slots — 16 logical px, in both variants. The slots
  /// are caller widgets, so the size reaches a glyph as the ambient icon size
  /// (Flutter `IconTheme`, Web `font-size`); a glyph that states its own size
  /// keeps it. The close glyph is not one of them — it states
  /// [defaultCloseIconStyle] / [editorStripCloseIconStyle].
  static const CoreIconStyle defaultSlotIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// The close box the [editorStrip] row states — a 20×20 hit-area (`width`
  /// = `height` = [CoreSize.size20]) with a tight glyph (`padding` zero) and
  /// a 4-radius corner, beneath the 36 px chip. The tab chip then measures
  /// start 12 + label + 6 + 20 + end 8. Stated on the row, not on
  /// [defaultCloseButtonStyle], so the boxed strip's close × keeps its
  /// 32 px `Button` row.
  static const CoreButtonStyle editorStripCloseButtonStyle = CoreButtonStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    height: CoreSize.size20,
    width: CoreSize.size20,
    padding: CoreEdgeInsets.zero,
  );

  /// The close glyph the [editorStrip] row states — 12 logical px, sized
  /// to the 20 px close box, in `onSurfaceSubtle`.
  ///
  /// A glyph that states a colour keeps it in every button state: it does
  /// NOT follow its ghost button's foreground, so hover leaves it at
  /// `onSurfaceSubtle` (only the button's hover wash changes). A disabled
  /// tab does not dim it either: the close × is a sibling of the tab's
  /// select `Clickable` (so a click on it never selects), which means the
  /// tab's disabled state — and that `Clickable`'s disabled opacity — does
  /// not reach the ×; it stays an enabled button with this same colour.
  /// A glyph that states no colour (the boxed strip's
  /// [defaultCloseIconStyle]) follows the button instead.
  static const CoreIconStyle editorStripCloseIconStyle = CoreIconStyle(
    size: CoreIconSize.size12,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// The `Clickable` partial the [editorStrip] row states for its tabs —
  /// the focus ring drawn inside the tab's box.
  ///
  /// `CoreFocusOutlineStyle.align` is the distance from the box edge to the
  /// ring's OUTER edge, so `0` lays the ring flush inside the edge (its
  /// width runs inward) where the default (`ringOffset + ringWidth`) draws
  /// it 4 px outside. Only the geometry is stated; the ring's colour, width
  /// and the rest of the Clickable's chrome stay the system's.
  static const CoreClickableStyle editorStripClickableStyle =
      CoreClickableStyle(
        focusOutlineStyle: CoreFocusOutlineStyle(align: CoreSpace.space0),
      );

  /// Style preset for [CoreTabPaneVariant.editorStrip] — IDE editor chrome
  /// on existing fields: a 36 px strip ([barHeight]) with flush corners,
  /// zero inter-tab gap and no rule between tabs, a strip band one step
  /// below the page surface ([stripBackgroundColor]), a chip padded start
  /// 12 / end 8 around everything it holds ([tabPadding]), the tab label in
  /// `codeSm` ([contentTextStyle]) and no outer card.
  ///
  /// [borderWidth] / [borderColor] are the strip's bottom line here — drawn
  /// inside the strip's height at its bottom edge, under the chips, so the
  /// selected tab's face (which fills the whole strip height) covers it and
  /// the unselected tabs leave it visible. A `transparent` [borderColor]
  /// draws nothing; the preset states `outlineVariant`, so the line is on.
  ///
  /// [indicatorColor] / [indicatorWidth] mark the selected tab with a bar
  /// along the inside of its top edge — `primary`, [defaultIndicatorWidth]
  /// thick, the chip's full width. It is paint only: it takes no layout
  /// height, so the label sits at the same y on a selected and an unselected
  /// tab. The [boxed] row draws the same bar along the bottom edge.
  ///
  /// [closeButtonStyle] / [closeIconStyle] state the close affordance's box
  /// (20×20, [editorStripCloseButtonStyle]) and glyph (12,
  /// [editorStripCloseIconStyle]).
  ///
  /// [clickableStyle] moves a tab's keyboard focus ring INSIDE the tab's
  /// box ([editorStripClickableStyle]). The strip is a scroll container and
  /// each tab fills its whole height, so a ring drawn outside the box — the
  /// Clickable's default — falls outside the scrollport and is clipped top
  /// and bottom on both platforms. The ring's colour stays the system
  /// `focusRing`.
  ///
  /// Pair with `variant: .editorStrip` so the content panel is not
  /// rendered. Applying this style alone on a boxed pane still paints
  /// an empty content card — that empty-content hack is what the
  /// variant replaces.
  static const CoreTabPaneStyle editorStrip = CoreTabPaneStyle(
    barHeight: CoreSize.size36,
    tabPadding: CoreEdgeInsets.directional(
      start: CoreSpace.space12,
      end: CoreSpace.space8,
    ),
    contentTextStyle: CoreTextStyle.token(CoreTextStyles.codeSm),
    tabSpacing: 0,
    tabSeparatorColor: CoreColor.token(CoreColors.outlineVariant),
    stripBackgroundColor: CoreColor.token(CoreColors.surfaceContainerLow),
    backgroundColor: CoreColor.token(CoreColors.surface),
    borderRadius: CoreBorderRadius.zero,
    borderWidth: CoreStrokeWidth.stroke1,
    borderColor: CoreColor.token(CoreColors.outlineVariant),
    tabBorderColor: CoreColor.transparent,
    clickableStyle: editorStripClickableStyle,
    indicatorColor: CoreColor.token(CoreColors.primary),
    closeButtonStyle: editorStripCloseButtonStyle,
    closeIconStyle: editorStripCloseIconStyle,
  );

  /// Style preset for [CoreTabPaneVariant.boxed] — an underline tab strip
  /// inside one card: a 44 px bar ([barHeight]) inset 16 at each end
  /// ([barPadding]) with 20 between tabs ([tabSpacing]), each tab padded 2
  /// across and none down ([tabPadding]) with the label in `labelLarge`
  /// ([contentTextStyle]); the bar's bottom line and the card's edge are one
  /// `outlineVariant` hairline ([borderColor] / [borderWidth]) round a
  /// 12-radius card ([borderRadius]). The selected tab carries no face and
  /// no outline of its own ([tabBorderColor] `transparent`): it is marked by
  /// the [indicatorColor] bar along the bottom of its box, over the bar's
  /// line, the full width of the tab, its two top corners rounded
  /// ([indicatorBorderRadius]).
  ///
  /// No shadow: on-screen cards take their edge from the hairline; a shadow
  /// belongs to a floating panel only.
  static const CoreTabPaneStyle boxed = CoreTabPaneStyle(
    barHeight: CoreSize.size44,
    barPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16),
    tabPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space2),
    tabSpacing: CoreSpace.space20,
    contentTextStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    borderColor: CoreColor.token(CoreColors.outlineVariant),
    tabBorderColor: CoreColor.transparent,
    indicatorColor: CoreColor.token(CoreColors.primary),
    indicatorBorderRadius: CoreBorderRadius.only(
      topLeft: CoreRadius.radius2,
      topRight: CoreRadius.radius2,
    ),
  );

  /// Per-variant chrome — variant-dependent defaults. Single source of
  /// truth shared by Flutter and Web.
  ///
  /// [CoreTabPaneVariant.boxed] carries [boxed]; fields it leaves unstated
  /// take the field-level [defaultBackgroundColor] / … constants.
  /// [CoreTabPaneVariant.editorStrip] carries [editorStrip].
  static const Map<CoreTabPaneVariant, CoreTabPaneStyle> defaultsByVariant = {
    CoreTabPaneVariant.boxed: boxed,
    CoreTabPaneVariant.editorStrip: editorStrip,
  };

  // ── Fields ───────────────────────────────────

  /// Content panel / focused-tab background colour. `null` → token
  /// default.
  final CoreColor? backgroundColor;

  /// Inter-tab rule colour, on each tab's inline-end edge, drawn on every
  /// tab regardless of focus. `null` → token default (`transparent` = not
  /// drawn).
  final CoreColor? tabSeparatorColor;

  /// Inter-tab rule thickness (logical px). `null` → token default.
  final double? tabSeparatorWidth;

  /// Tab-strip band colour — painted behind the whole strip, edge to edge
  /// (the bar padding moves the tabs, not the band). `null` → token
  /// default (`transparent`).
  final CoreColor? stripBackgroundColor;

  /// Content-panel border colour. `null` → token default.
  ///
  /// On the [boxed] row this is the card's edge (the root carries it; the
  /// bar and the panel sit inside) and the colour of the bar's bottom line.
  ///
  /// On [CoreTabPaneVariant.editorStrip] there is no panel, and this is the
  /// colour of the strip's bottom line instead (thickness [borderWidth]);
  /// `transparent` draws no line.
  final CoreColor? borderColor;

  /// Focused-tab border colour (the tab's top / inline-start / inline-end
  /// stroke). `transparent` — what both variant rows state — means NO
  /// outline and no face: the focused tab is marked by the indicator bar
  /// alone. A stated colour draws the face and the three-sided outline.
  /// `null` → token default.
  ///
  /// Thickness is shared with [borderWidth].
  final CoreColor? tabBorderColor;

  /// Container corner radius. `null` → token default.
  final CoreBorderRadius? borderRadius;

  /// Container / tab border thickness (logical px). `null` → token
  /// default.
  ///
  /// On [CoreTabPaneVariant.editorStrip] this is the thickness of the
  /// strip's bottom line ([borderColor]). That line sits inside [barHeight],
  /// at the strip's bottom edge, beneath the chips — so it takes no layout
  /// height and the selected tab's face covers it.
  final double? borderWidth;

  /// Tab-bar height (logical px). `null` → token default.
  ///
  /// On [CoreTabPaneVariant.editorStrip] the tab chip fills this whole
  /// height (the focused face included) and the label is centred in it.
  final double? barHeight;

  /// Padding of each tab chip — it wraps everything the chip holds, the
  /// leading glyph through the badge, `trailing` and the close ×, so a
  /// trailing slot sits as far from the chip's end edge as the label
  /// does from its start. `null` → token default.
  final CoreEdgeInsets? tabPadding;

  /// Inter-tab spacing (logical px). `null` → token default.
  final double? tabSpacing;

  /// Reorder drag-preview opacity (0..1). `null` → token default
  /// ([defaultDragOpacity]).
  final double? dragOpacity;

  /// Focused tab-label colour. `null` → token default.
  ///
  /// Layered ON TOP of [contentTextStyle]'s role, the way the sibling
  /// `CoreTabsStyle` layers its own pair — the role stays one statement
  /// and only the colour varies by state.
  final CoreColor? activeContentColor;

  /// Unfocused tab-label colour. `null` → token default.
  final CoreColor? inactiveContentColor;

  /// Tab-label text style override. Despite the name this reaches the
  /// tab labels only — the panel body is a caller slot (`CoreTabItem
  /// .content`) that this component never types, on either platform.
  final CoreTextStyle? contentTextStyle;

  /// Nested style for the composed boxed-tab `Clickable` — carries any
  /// press / focus-ring / cursor chrome overrides for the tab
  /// affordance (the `Clickable` owns the keyboard focus ring). Merged
  /// on top of [defaultClickableStyle] and the variant row
  /// ([editorStripClickableStyle] on [CoreTabPaneVariant.editorStrip]) and
  /// raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle? clickableStyle;

  /// Nested [CoreGapStyle] slot for the spacer inside a boxed tab —
  /// between its label and its `CoreTabItem.badge`. `null` → token default
  /// ([defaultLabelBadgeGapStyle]). Merged on top of that default and
  /// raw-forwarded to the `Gap` widget the tab composes.
  /// Also the gap around `CoreTabItem.leading` / `.trailing`.
  ///
  /// One field, not three, because Figma auto-layout gives a frame ONE
  /// `itemSpacing` — three distinct 1-off gaps in one row would need a
  /// spacer-node restructure the badge composition also sits on, and a
  /// value the canvas cannot draw is a handle only two of the three
  /// surfaces have (`designer-judgment-playbook.md`).
  final CoreGapStyle? labelBadgeGapStyle;

  /// Selected-tab indicator colour — a bar along the inside of the selected
  /// tab's top edge. `null` → token default ([defaultIndicatorColor],
  /// `transparent` = not drawn). The [editorStrip] row states `primary`.
  ///
  /// Paint only: the bar takes no layout height. Thickness is
  /// [indicatorWidth].
  final CoreColor? indicatorColor;

  /// Selected-tab indicator thickness (logical px). `null` → token default
  /// ([defaultIndicatorWidth]). Only consulted when [indicatorColor] is
  /// stated non-transparent.
  final double? indicatorWidth;

  /// Corner radius of the selected-tab indicator bar. `null` → token default
  /// ([defaultIndicatorBorderRadius], flat). The [boxed] row states its two
  /// outer corners.
  final CoreBorderRadius? indicatorBorderRadius;

  /// Inset of the tabs inside the bar (logical px, pre-scaling), start / end.
  /// `null` → token default ([defaultBarPadding], none). The [boxed] row
  /// states 16 so the tabs clear the card's corners.
  final CoreEdgeInsets? barPadding;

  /// Nested [CoreButtonStyle] slot for a tab's close affordance (`CoreTabItem
  /// .onClose`). Recursively merged on top of [defaultCloseButtonStyle] and
  /// the variant row ([editorStripCloseButtonStyle] on
  /// [CoreTabPaneVariant.editorStrip]) and raw-forwarded to
  /// `Button(buttonStyle:)`.
  final CoreButtonStyle? closeButtonStyle;

  /// Nested [CoreIconStyle] slot for the close glyph. Recursively merged on
  /// top of [defaultCloseIconStyle] and the variant row
  /// ([editorStripCloseIconStyle]) and raw-forwarded to `Icon(iconStyle:)`.
  /// A stated `color` holds in every button state (hover, disabled
  /// included); with none stated the glyph follows its ghost button's
  /// foreground. The [editorStrip] row states `onSurfaceSubtle`.
  final CoreIconStyle? closeIconStyle;

  /// Nested [CoreIconStyle] slot for the glyphs in a tab's `leading` /
  /// `trailing` slots. Merged on top of [defaultSlotIconStyle]; only its
  /// `size` is read (the ambient icon size).
  final CoreIconStyle? slotIconStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreTabPaneStyle merge(CoreTabPaneStyle? other) {
    if (other == null) return this;
    return CoreTabPaneStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      stripBackgroundColor: other.stripBackgroundColor ?? stripBackgroundColor,
      borderColor: other.borderColor ?? borderColor,
      tabBorderColor: other.tabBorderColor ?? tabBorderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      barHeight: other.barHeight ?? barHeight,
      tabPadding: other.tabPadding ?? tabPadding,
      tabSpacing: other.tabSpacing ?? tabSpacing,
      tabSeparatorColor: other.tabSeparatorColor ?? tabSeparatorColor,
      tabSeparatorWidth: other.tabSeparatorWidth ?? tabSeparatorWidth,
      dragOpacity: other.dragOpacity ?? dragOpacity,
      contentTextStyle: _mergeText(contentTextStyle, other.contentTextStyle),
      activeContentColor: other.activeContentColor ?? activeContentColor,
      inactiveContentColor: other.inactiveContentColor ?? inactiveContentColor,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      labelBadgeGapStyle:
          labelBadgeGapStyle?.merge(other.labelBadgeGapStyle) ??
          other.labelBadgeGapStyle,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorWidth: other.indicatorWidth ?? indicatorWidth,
      indicatorBorderRadius:
          other.indicatorBorderRadius ?? indicatorBorderRadius,
      barPadding: other.barPadding ?? barPadding,
      closeButtonStyle: _mergeButton(closeButtonStyle, other.closeButtonStyle),
      closeIconStyle: _mergeIcon(closeIconStyle, other.closeIconStyle),
      slotIconStyle: _mergeIcon(slotIconStyle, other.slotIconStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTabPaneStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? stripBackgroundColor,
    CoreColor? borderColor,
    CoreColor? tabBorderColor,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    double? barHeight,
    CoreEdgeInsets? tabPadding,
    double? tabSpacing,
    CoreColor? tabSeparatorColor,
    double? tabSeparatorWidth,
    double? dragOpacity,
    CoreTextStyle? contentTextStyle,
    CoreColor? activeContentColor,
    CoreColor? inactiveContentColor,
    CoreClickableStyle? clickableStyle,
    CoreGapStyle? labelBadgeGapStyle,
    CoreColor? indicatorColor,
    double? indicatorWidth,
    CoreBorderRadius? indicatorBorderRadius,
    CoreEdgeInsets? barPadding,
    CoreButtonStyle? closeButtonStyle,
    CoreIconStyle? closeIconStyle,
    CoreIconStyle? slotIconStyle,
  }) {
    return CoreTabPaneStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      stripBackgroundColor: stripBackgroundColor ?? this.stripBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      tabBorderColor: tabBorderColor ?? this.tabBorderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      barHeight: barHeight ?? this.barHeight,
      tabPadding: tabPadding ?? this.tabPadding,
      tabSpacing: tabSpacing ?? this.tabSpacing,
      tabSeparatorColor: tabSeparatorColor ?? this.tabSeparatorColor,
      tabSeparatorWidth: tabSeparatorWidth ?? this.tabSeparatorWidth,
      dragOpacity: dragOpacity ?? this.dragOpacity,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
      activeContentColor: activeContentColor ?? this.activeContentColor,
      inactiveContentColor: inactiveContentColor ?? this.inactiveContentColor,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      labelBadgeGapStyle: labelBadgeGapStyle ?? this.labelBadgeGapStyle,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorWidth: indicatorWidth ?? this.indicatorWidth,
      indicatorBorderRadius:
          indicatorBorderRadius ?? this.indicatorBorderRadius,
      barPadding: barPadding ?? this.barPadding,
      closeButtonStyle: closeButtonStyle ?? this.closeButtonStyle,
      closeIconStyle: closeIconStyle ?? this.closeIconStyle,
      slotIconStyle: slotIconStyle ?? this.slotIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTabPaneStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          stripBackgroundColor == other.stripBackgroundColor &&
          borderColor == other.borderColor &&
          tabBorderColor == other.tabBorderColor &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          barHeight == other.barHeight &&
          tabPadding == other.tabPadding &&
          tabSpacing == other.tabSpacing &&
          tabSeparatorColor == other.tabSeparatorColor &&
          tabSeparatorWidth == other.tabSeparatorWidth &&
          dragOpacity == other.dragOpacity &&
          contentTextStyle == other.contentTextStyle &&
          activeContentColor == other.activeContentColor &&
          inactiveContentColor == other.inactiveContentColor &&
          clickableStyle == other.clickableStyle &&
          labelBadgeGapStyle == other.labelBadgeGapStyle &&
          indicatorColor == other.indicatorColor &&
          indicatorWidth == other.indicatorWidth &&
          indicatorBorderRadius == other.indicatorBorderRadius &&
          barPadding == other.barPadding &&
          closeButtonStyle == other.closeButtonStyle &&
          closeIconStyle == other.closeIconStyle &&
          slotIconStyle == other.slotIconStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    stripBackgroundColor,
    borderColor,
    tabBorderColor,
    borderRadius,
    borderWidth,
    barHeight,
    tabPadding,
    tabSpacing,
    tabSeparatorColor,
    tabSeparatorWidth,
    dragOpacity,
    contentTextStyle,
    activeContentColor,
    inactiveContentColor,
    clickableStyle,
    labelBadgeGapStyle,
    indicatorColor,
    indicatorWidth,
    indicatorBorderRadius,
    barPadding,
    closeButtonStyle,
    closeIconStyle,
    slotIconStyle,
  ]);

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(CoreIconStyle? base, CoreIconStyle? other) {
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
}
