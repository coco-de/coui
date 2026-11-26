/// Per-instance style for `NavigationBar`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/badge/badge_style.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/indicator/indicator_style.dart';
import 'package:coui_core/src/component/contracts/navigation_bar/navigation_bar_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/a11y_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/surface/surface_refraction.dart';
import 'package:coui_core/src/surface/surface_style_id.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `NavigationBar` should render.
///
/// Carries every chrome / dimensional override for the navigation
/// container and its items. Platform-neutral (Epic #1415 option D).
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CoreNavigationBarStyle implements CoreStyle<CoreNavigationBarStyle> {
  /// Creates a [CoreNavigationBarStyle].
  const CoreNavigationBarStyle({
    this.surfaceStyle,
    this.backgroundColor,
    this.padding,
    this.barRadius,
    this.barMargin,
    this.barBorderColor,
    this.barBorderWidth,
    this.itemSpacing,
    this.itemPadding,
    this.itemRadius,
    this.itemMinHeight,
    this.itemMaxWidth,
    this.iconOnlyItemMinHeight,
    this.iconOnlyItemMinWidth,
    this.touchTargetSize,
    this.labelSpacing,
    this.iconStyle,
    this.disabledIconStyle,
    this.badgeIndicatorStyle,
    this.selectedBackgroundColor,
    this.selectedLabelTextStyle,
    this.hoverBackgroundColor,
    this.stateLayer,
    this.stateLayerColor,
    this.labelTextStyle,
    this.disabledLabelTextStyle,
    this.disabledSelectedLabelTextStyle,
    this.sectionLabelTextStyle,
    this.sectionLabelPadding,
    this.dividerColor,
    this.dividerThickness,
    this.duration,
    this.clickableStyle,
    this.selectionMarkStyle,
    this.selectionMarkGapStyle,
    this.disabledSelectionMarkStyle,
    this.selectedIconStyle,
    this.hoverForegroundColor,
    @Deprecated(
      'No pill is drawn (since 0.184) — the selected destination paints its '
      'whole tile. Use selectedBackgroundColor.',
    )
    this.selectedIconAnchorColor,
    @Deprecated(
      'No pill is drawn (since 0.184) — the selected destination paints its '
      'whole tile. Use selectedIconStyle.',
    )
    this.selectedIconAnchorIconStyle,
    this.disabledSelectedBackgroundColor,
    @Deprecated(
      'No pill is drawn (since 0.184) — the selected destination paints its '
      'whole tile. Use disabledSelectedBackgroundColor.',
    )
    this.disabledSelectedIconAnchorColor,
    this.iconAnchorPadding,
    @Deprecated(
      'No pill is drawn (since 0.184) — the selected face takes the '
      "tile's itemRadius.",
    )
    this.iconAnchorRadius,
    this.notificationDotStyle,
    this.notificationDotIndicatorStyle,
    this.compactScale,
    this.compactDuration,
  });

  /// Floating horizontal glass chrome. Explicit style fields still win.
  static const glassBarStyle = CoreNavigationBarStyle(
    barRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    barMargin: CoreEdgeInsets.all(CoreSpace.space8),
    padding: CoreEdgeInsets.all(CoreSpace.space4),
    itemRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    // The focus ring starts from the item's corner, so a pill item takes a
    // pill ring (see [defaultClickableStyle]).
    clickableStyle: CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
    itemMinHeight: CoreSize.size48,
    // No cap. The capsule's moving lens measures every destination as an
    // equal share of the whole row, so a capped destination would leave the
    // lens sliding over empty capsule between the cells. The capsule keeps
    // its destinations spanning it; the bar cell's cap stays with the
    // docked bar.
    itemMaxWidth: double.infinity,
    selectedLabelTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.primary),
    ),
    selectedBackgroundColor: CoreColor.token(
      CoreColors.shadow,
      opacity: CoreOpacity.opacity20,
    ),
    // The dot takes the glass selection's primary, the colour the selected
    // label takes here — the two say the same thing.
    selectionMarkStyle: CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
    // The capsule floats over the content, so it can step back without the
    // content it follows being laid out again (see [defaultCompactScale]).
    compactScale: glassCompactScale,
  );

  /// Floating vertical glass chrome — the rail's counterpart of
  /// [glassBarStyle]. Explicit style fields still win.
  ///
  /// A capsule one control wide: 4 of padding around destinations 40 wide
  /// and 48 tall, 4 apart. Icon-only — the glass rail's default
  /// (`CoreNavigationLabelMode.defaultGlassRailMode`) — that is 48 across,
  /// and four destinations stand 212 tall, the size a platform that moves
  /// its tab bar to the side of the screen draws that bar at. The same lens
  /// the bar slides sideways travels down this column.
  ///
  /// The icon keeps a box of its own in a stacked destination
  /// ([iconAnchorPadding]); the opaque rail keeps 12 either side of the
  /// glyph there. So the box closes to 4 either side, which is what lets a
  /// 24 glyph and the item's own padding land on the 40-wide destination.
  ///
  /// The margin detaches the capsule, as the bar's does. Where the capsule
  /// sits — which side of the screen, how far from its edge — is the app
  /// shell's: a reserved side strip stays on the same physical side in a
  /// right-to-left locale, so no logical inset stated here could place it.
  static const glassRailStyle = CoreNavigationBarStyle(
    barRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    barMargin: CoreEdgeInsets.all(CoreSpace.space8),
    padding: CoreEdgeInsets.all(CoreSpace.space4),
    itemSpacing: CoreSpace.space4,
    itemRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    // The focus ring starts from the item's corner, so a pill item takes a
    // pill ring (see [defaultClickableStyle]).
    clickableStyle: CoreClickableStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
    itemMinHeight: CoreSize.size48,
    iconOnlyItemMinWidth: CoreSize.size40,
    iconAnchorPadding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space4,
      vertical: CoreSpace.space2,
    ),
    selectedLabelTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.primary),
    ),
    selectedBackgroundColor: CoreColor.token(
      CoreColors.shadow,
      opacity: CoreOpacity.opacity20,
    ),
    // The dot takes the glass selection's primary, as on the bar.
    selectionMarkStyle: CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// The floating glass chrome a container at [mode] takes under a glass
  /// material, or `null` for a mode that stays docked there.
  ///
  /// The bar and the rail detach into a capsule ([glassBarStyle] /
  /// [glassRailStyle]). The sidebar keeps its docked chrome and only takes
  /// the material: it is a panel of rows, not a strip of destinations a
  /// lens can travel.
  ///
  /// Both platform resolvers ask here rather than each naming the modes, so
  /// a mode cannot float on one platform and stay docked on the other.
  static CoreNavigationBarStyle? glassStyleFor(CoreNavigationBarMode mode) =>
      switch (mode) {
        CoreNavigationBarMode.bar => glassBarStyle,
        CoreNavigationBarMode.rail => glassRailStyle,
        CoreNavigationBarMode.sidebar => null,
      };

  /// Quiet resting pane: no magnification or coloured edge separation.
  static const glassRestingRefraction = CoreSurfaceRefraction(
    bezel: .12,
    strength: .08,
  );

  /// The temporary selection lens, sampling the icons beneath it.
  static const glassSelectionRefraction = CoreSurfaceRefraction(
    bezel: .12,
    strength: .16,
    dispersion: .30,
    lens: .12,
  );

  /// Surface style (material) override for the navigation bar. `null`
  /// inherits the theme's surface style; `defaultStyle` removes the glass.
  ///
  /// Deliberately no default: null inherits the active theme material axis;
  /// a fixed default would override that axis before the resolver sees it.
  final CoreSurfaceStyleId? surfaceStyle;

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default outer padding of the navigation container — the rail's.
  ///
  /// The bar and the sidebar each state their own in [defaultsByMode]; a
  /// mode cell left `null` falls through to this.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Default corners of the bar itself — square.
  ///
  /// A bar docked to an edge wants no corners; rounding is what a detached
  /// floating bar states through [barRadius] to read as one object. Both
  /// platforms take the square baseline from here rather than each spelling
  /// it in their own resolver.
  static const CoreBorderRadius defaultBarRadius = CoreBorderRadius.zero;

  /// Default space outside the bar — none.
  ///
  /// Flush against the edge it sits on. Detaching it is what [barMargin]
  /// states per instance.
  ///
  /// Authoritative for Flutter only, and that is not a gap this default
  /// can close. The Web resolver keys the bar's top hairline on the
  /// override being ABSENT (`if (merged.barMargin == null) 'border-t'`)
  /// and omits the margin declaration entirely when it is. A non-null
  /// default would make that test permanently false and strip the
  /// hairline from every docked bar — so seats (5)(6) of the
  /// 1:1:1:1:1:1 mapping do not route through Core here.
  ///
  /// Written down rather than left to be discovered: editing this value
  /// floats the Flutter bar and leaves the Web one flush. Closing it
  /// needs an explicit docked/floating discriminator, not a value.
  static const CoreEdgeInsets defaultBarMargin = CoreEdgeInsets.zero;

  /// Default colour of the bar's content-facing hairline — the edge that
  /// separates the bar from the content it navigates (top for a docked
  /// [CoreNavigationBarMode.bar], the trailing edge for the vertical
  /// modes). The line is what makes the bar read as chrome rather than
  /// as part of the page when the two share a close surface tone.
  ///
  /// `outlineSubtle`, the step under the body dividers — the bar's face
  /// already sets it apart, so the line only has to finish the edge (the
  /// same token as the Tabs underline track, designer's decision).
  static const CoreColor defaultBarBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Default thickness of the bar's content-facing hairline (logical px).
  ///
  /// On the horizontal bar the line lies over the top padding instead of
  /// adding to it, so the docked bar is `padding + item` tall (80) whether
  /// or not the line draws — a style that thins or drops the line must not
  /// move what sits above the bar. The vertical modes lay their trailing
  /// line out as a border.
  static const double defaultBarBorderWidth = CoreStrokeWidth.stroke1;

  /// Per-mode defaults — the density a layout mode draws its items at.
  ///
  /// A bottom bar on a phone and a sidebar on a desktop are the same
  /// component at two densities: the bar and the rail carry a glyph with a
  /// 12px caption under it in a 64-tall cell, the sidebar a row of 18px
  /// icon and 14px label 36 tall. The flat `default*` constants are the bar
  /// and rail values, so a mode cell left `null` falls through to them; the
  /// sidebar states its own. Moving a flat constant instead would move every
  /// app's bottom bar with it.
  ///
  /// Item spacing differs in all three. The horizontal bar packs
  /// destinations edge-to-edge — each one stretches to an equal share of the
  /// width, so the hover / selection fills tile the bar without slivers of
  /// background between them. The vertical modes keep an authored gap: their
  /// items hug their content, and adjacent fills touching top-to-bottom would
  /// read as one block.
  ///
  /// No mode states a selected face: how the selected destination is marked
  /// is the indicator's ([defaultsByIndicator]), which sits above this table.
  ///
  /// The bottom bar sits on `surface`, the page's own tone, rather than the
  /// `surfaceContainerLow` chrome tier the rail and the sidebar keep: docked
  /// under the content on a phone, its hairline is what separates it, and a
  /// second tone under the home indicator read as a slab. It pads
  /// `space8` above and below and `space12` at the sides; the device's
  /// bottom safe area is added to the bottom by each platform (see
  /// [padding]), so the inset is never a value in this table.
  ///
  /// Resolution order on both platforms, per field: the merged per-instance
  /// / theme style field, then this mode cell, then the flat default.
  static const Map<CoreNavigationBarMode, CoreNavigationBarModeStyle>
  defaultsByMode = {
    CoreNavigationBarMode.bar: CoreNavigationBarModeStyle(
      spacing: 0,
      padding: CoreEdgeInsets.symmetric(
        vertical: CoreSpace.space8,
        horizontal: CoreSpace.space12,
      ),
      itemMaxWidth: CoreSize.size96,
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
    CoreNavigationBarMode.rail: CoreNavigationBarModeStyle(
      spacing: CoreSpace.space8,
    ),
    CoreNavigationBarMode.sidebar: CoreNavigationBarModeStyle(
      spacing: CoreSpace.space2,
      padding: CoreEdgeInsets.symmetric(
        vertical: CoreSpace.space16,
        horizontal: CoreSpace.space12,
      ),
      itemMinHeight: CoreSize.size40,
      itemPadding: CoreEdgeInsets.symmetric(
        vertical: CoreSpace.space10,
        horizontal: CoreSpace.space12,
      ),
      iconStyle: CoreIconStyle(size: CoreIconSize.size20),
      labelSpacing: CoreSpace.space10,
      labelTextStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
    ),
  };

  /// Default inner padding of a navigation item.
  ///
  /// 4 at the sides and 6 above and below — a stacked destination's icon
  /// sits in its own 48-wide box ([defaultIconAnchorPadding]), so the item
  /// needs little room of its own around it.
  static const CoreEdgeInsets defaultItemPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space4,
    vertical: CoreSpace.space6,
  );

  /// Default corner radius of a navigation item.
  static const CoreBorderRadius defaultItemRadius = CoreBorderRadius.all(
    CoreRadius.radius10,
  );

  /// Default minimum height of a navigation item (logical px).
  ///
  /// The content stack (icon + label gap + one label line + padding)
  /// lands just under this; the floor rounds every item up to the same
  /// even height so the bar's own height is a stable
  /// `padding + item = 80` regardless of label ascent quirks.
  static const double defaultItemMinHeight = CoreSize.size64;

  /// Default maximum width of a navigation item (logical px) — no cap.
  ///
  /// A mode that states nothing lets its destinations take whatever their
  /// layout gives them; the rail's and the sidebar's are sized by their own
  /// column. The bar states its cap in [defaultsByMode]: without one, a bar
  /// as wide as a tablet spread four destinations about 200 apart, where a
  /// platform tab bar packs them in the middle. A phone's share is under
  /// the cap, so a phone draws the same bar either way.
  static const double defaultItemMaxWidth = double.infinity;

  /// Default minimum height of a stacked destination that hides its label
  /// (logical px) — 40, the painted height of an icon-only destination.
  ///
  /// With no caption under it the destination is the icon's box
  /// ([defaultIconAnchorPadding] around the glyph) and the item padding;
  /// holding it to the labelled destination's [defaultItemMinHeight] left
  /// a 64-tall tile whose hover and focus washes reached far past the
  /// glyph. The pointer target is a separate value ([defaultTouchTargetSize]):
  /// what accepts a tap stays 48 while what is painted shrinks.
  ///
  /// A caller or a material preset that states [itemMinHeight] keeps that
  /// height for icon-only destinations too (the glass bar's and the glass
  /// rail's 48) — this default only moves the destinations nobody sized.
  static const double defaultIconOnlyItemMinHeight = CoreSize.size40;

  /// Default minimum width of a stacked destination that hides its label
  /// (logical px) — 64, the painted width of an icon-only destination.
  ///
  /// A destination sharing a bar's width takes its share; a floor larger
  /// than the share yields to it on both platforms (Flutter's constraints
  /// clamp to the parent, Web's `min()` against the cell), so a crowded bar
  /// does not overflow.
  static const double defaultIconOnlyItemMinWidth = CoreSize.size64;

  /// Default smallest region, on either axis, that accepts a pointer around
  /// a stacked destination (logical px) — [CoreA11ySize.touchTarget] (48).
  ///
  /// Separate from what is painted: an icon-only destination draws 40 tall
  /// ([defaultIconOnlyItemMinHeight]) and accepts a tap 4 above and below
  /// it. Only hit testing grows — layout and paint keep the drawn size, so
  /// neighbours do not move.
  static const double defaultTouchTargetSize = CoreA11ySize.touchTarget;

  /// Default native flex `spacing` between an item's icon and its label
  /// — passed directly to `Row.spacing` / `Column.spacing` (Flutter) and
  /// the inner flex `gap` (Web). Not wrapped in `Gap` (logical px).
  static const double defaultLabelSpacing = CoreSpace.space4;

  /// Default navigation item icon style — 24-logical-px, `onSurfaceVariant`
  /// coloured. Per-instance override flows through [iconStyle] (merged
  /// on top of this default).
  ///
  /// State-independent by design: the icon reads the same tone whether
  /// the destination is selected, unselected or disabled. Selection is
  /// still signalled — by the label's colour + bold weight
  /// (`defaultSelectedLabelTextStyle`), not by the icon matching it.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size24,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default icon override for a disabled destination — the
  /// `disabledContent` tone, the same one its label takes.
  ///
  /// Layered over the resolved [iconStyle] (size from there, colour from
  /// here), so a disabled destination keeps its icon's size and stops
  /// reading as live. The icon is otherwise state-independent; disabled is
  /// the one state that is not a variation of the same affordance but its
  /// absence, and an icon left at the resting tone beside a dimmed label
  /// reads as half of the item still working.
  static const CoreIconStyle defaultDisabledIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.disabledContent),
  );

  /// Default nested [CoreIndicatorStyle] slot for the composed `Indicator`
  /// that lays a destination's `badge` over its icon in the bar and the
  /// rail — a partial carrying only the offset that diverges from the
  /// indicator's own default.
  ///
  /// The indicator anchors the badge's top-end corner at the icon's top-end
  /// corner. At the indicator's own offset of 0 a count badge (18 tall)
  /// would sit inside a 24px glyph and cover most of it; pulling it out by
  /// `space6` on both edges puts the badge over the glyph's top-end quarter,
  /// which is where a count reads as belonging to that glyph without hiding
  /// it. The sidebar does not compose the indicator — its badge sits at the
  /// row's trailing end.
  ///
  /// Written as the difference of two steps rather than a negated step so
  /// the canvas exporter, which folds arithmetic between tokens, carries
  /// the value to the builder.
  static const CoreIndicatorStyle defaultBadgeIndicatorStyle =
      CoreIndicatorStyle(offset: CoreSpace.space0 - CoreSpace.space6);

  /// Default background colour of the selected item — no fill.
  ///
  /// The floor under the indicator cells, which both state their own face
  /// ([defaultsByIndicator]). The transparent sentinel keeps the field a
  /// real single source a caller can still override with a fill.
  static const CoreColor defaultSelectedBackgroundColor = CoreColor.transparent;

  /// Default background colour applied to an item on hover — no fill.
  ///
  /// Hover is carried by [defaultStateLayer], laid over whatever the bar
  /// is already painted. The transparent sentinel keeps this field a real
  /// single source a caller can still override with a fill, exactly as
  /// [defaultSelectedBackgroundColor] does one slot up.
  ///
  /// Hover is not a token swap because a swap to a neighbouring surface
  /// tone does not move the same way in every colour mode: where that tone
  /// is the **page** colour, hovering a destination paints the page into
  /// the bar and the item reads as a hole punched through it rather than
  /// as a lift. A foreground overlay always moves away from the page.
  static const CoreColor defaultHoverBackgroundColor = CoreColor.transparent;

  /// How strongly a destination lays ink over the bar while hovered,
  /// focused or pressed — 3 / 8 / 8 %.
  ///
  /// This component's own ramp, not [CoreStateLayer.subtle]. Hover and
  /// focus are the subtle tier's (`CoreOpacity.hover` / `CoreOpacity.focus`);
  /// pressed stops at `opacity8` where the subtle tier goes on to 12.
  ///
  /// The unselected label sets the floor on the pressed fill. Its ink is
  /// `onSurfaceVariant` and the bar is `surfaceContainerLow` (the chrome
  /// tier); under an 8 % `onSurface` wash the label reads 5.785 : 1 in
  /// light, 6.333 : 1 in dark, 8.122 : 1 in high-contrast light and
  /// 10.287 : 1 in high-contrast dark — all over the 4.5 floor the
  /// perceptibility test holds every label to. 8 % is the weight this
  /// component keeps. Every state still differs from rest by at least 1.02.
  ///
  /// Accepted consequence: focus and pressed are now the same weight, so
  /// pressing a destination that already holds keyboard focus does not
  /// visibly change it. The ramp stays non-decreasing
  /// ([CoreStateLayer.isAscending]), which is the invariant the type
  /// states; a strict step is not one of them. Chip and TextField `plain`
  /// read [CoreStateLayer.subtle].
  static const CoreStateLayer defaultStateLayer = CoreStateLayer(
    hover: CoreOpacity.hover,
    focus: CoreOpacity.focus,
    pressed: CoreOpacity.opacity8,
  );

  /// The ink [defaultStateLayer] lays over the bar.
  ///
  /// `onSurface` — one ink for every destination, not each item's own
  /// foreground. Reading the item's own colour would make the SAME
  /// gesture land at two strengths: a selected destination carries
  /// `onSurface` and an unselected one `onSurfaceVariant`, so hovering
  /// along the bar would wash unevenly. One ink also costs the least
  /// against the old swap in light (Δ1.0626 of the swap's Δ1.0912, where
  /// the per-item ink reaches only Δ1.0442).
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Destination label typography role — `labelSmall` (12px). Shared by the
  /// selected / unselected / disabled per-state label slots, which only
  /// differ in their foreground colour. The label colour is driven per
  /// state by the destination wrapper (the label text inherits it), so
  /// this role reference carries no colour: both platforms emit the role
  /// from this single default (Flutter `.toValue(theme:)`, Web
  /// `emitTypography`) instead of hardcoding `theme.typography.labelSmall`
  /// / `context.typography.labelSmall`.
  ///
  /// This is the bar and rail default, where a destination is a glyph
  /// with a caption under it and the caption is 12px.
  static const CoreTextStyle destinationLabelRole = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
  );

  /// Default label text style for a selected item — `labelSmall`
  /// typography token carrying the selected foreground colour
  /// (`onSurface`). The text colour lives inside this nested
  /// [CoreTextStyle] slot default (sb8 — raw `selectedForegroundColor`
  /// field replaced by the slot).
  /// The heavier weight is the only thing here that is not a colour.
  ///
  /// The selected face is a light tile ([defaultsByIndicator]) that a hover
  /// wash comes close to, so the face alone does not tell selected from
  /// hovered; and a mode that forces the palette folds several semantic
  /// colours onto one system colour. Weight is not forced, so it survives
  /// both — bold, against the unselected medium (designer's decision: the
  /// selected and current state is told by weight, as Breadcrumb's is).
  ///
  /// Assistive technology was never the gap — the item already reports
  /// `aria-current` on the web and a selected semantics flag on Flutter.
  /// This is for the people looking at it.
  /// `final` rather than `const`: the weight is overlaid with `copyWith`,
  /// which a constant expression cannot invoke, and building it from raw
  /// fields instead would drop the role token the resolvers read.
  static final CoreTextStyle defaultSelectedLabelTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.onSurface),
      ).copyWith(fontWeight: CoreFontWeight.bold);

  /// Default label text style for an unselected item — `labelSmall`
  /// typography token carrying the unselected foreground colour
  /// (`onSurfaceVariant`). The text colour lives inside this nested
  /// [CoreTextStyle] slot default (sb8 — raw `foregroundColor` field
  /// replaced by the slot).
  ///
  /// `onSurfaceSubtle`, so the selected destination is the one that reads at
  /// a glance (the same quiet the unselected Tabs take). The designer
  /// accepted the cost: on the lifted grounds a hover or pressed wash makes,
  /// and on the rail's chrome tier, this tone sits under 4.5 : 1 — the
  /// contrast guard records those pairs as accepted exceptions rather than
  /// passing them silently.
  static const CoreTextStyle defaultLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default label text style for a disabled item — `labelSmall`
  /// typography token carrying the disabled foreground colour
  /// (`disabledContent`). The text colour lives inside this nested
  /// [CoreTextStyle] slot default.
  ///
  /// A disabled destination reads through this colour (and the matching
  /// [defaultDisabledIconStyle]) alone — the composed `Clickable`'s
  /// generic disabled fade is off ([defaultClickableStyle]), so the tone
  /// is not faded a second time.
  static const CoreTextStyle defaultDisabledLabelTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.disabledContent),
      );

  /// Default label text style for a destination that is selected AND
  /// disabled — the disabled tone (`disabledContent`) at the selected weight
  /// (bold).
  ///
  /// A disabled destination that is the current one keeps saying so, dimmed:
  /// the colour is the disabled one every disabled label takes, and the
  /// weight is the selected one, so the selection still reads where the
  /// colour no longer can (designer's decision). The mode cell's role and the
  /// instance's `disabledLabelTextStyle` are layered over this, then
  /// [disabledSelectedLabelTextStyle].
  ///
  /// `final` rather than `const` for the reason
  /// [defaultSelectedLabelTextStyle] is: the weight is a `copyWith` overlay on
  /// the role token.
  static final CoreTextStyle defaultDisabledSelectedLabelTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.disabledContent),
      ).copyWith(fontWeight: CoreFontWeight.bold);

  /// Non-selectable section header typography role — `labelSmall` (12px).
  ///
  /// A fixed role reference, not an override default: the role is always
  /// `labelSmall`; per-instance weight / colour / size tweaks flow through
  /// the [sectionLabelTextStyle] slot overlay rather than swapping the
  /// role token. [defaultSectionLabelTextStyle] names the same role, so
  /// merging this ahead of it is a no-op the resolvers keep only to read
  /// the role from the const that states it on its own.
  ///
  /// A section header sits above its destinations and reads as a caption:
  /// `labelSmall` is 12px, the same size as a bar or rail destination's
  /// caption, so the semibold weight in [defaultSectionLabelTextStyle] is
  /// the whole of what makes that caption a header. The role's canvas text
  /// style is `Label/Small` (12/140); because the header states a weight
  /// over the role, the canvas draws it from the role's variables rather
  /// than attaching that style.
  static const CoreTextStyle sectionLabelRole = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
  );

  /// Non-selectable section header default matching the
  /// [sectionLabelTextStyle] slot — the `labelSmall` role (same role
  /// [sectionLabelRole] names) carrying the semibold font weight (the
  /// header is visually heavier than the role's own 500) plus the
  /// section foreground colour (`onSurfaceSubtle`). Both platforms drive
  /// the header role / weight / colour from this one default; the
  /// per-instance [sectionLabelTextStyle] slot is overlaid on top of it.
  ///
  /// `onSurfaceSubtle`, not the `onSurfaceVariant` the destinations rest
  /// at: a header is metadata no state layer ever covers, so it can take
  /// the quieter of the two secondary tones and sit a step below the items
  /// it names. The destinations cannot — a hover or pressed wash lifts the
  /// ground under them, and the quieter tone falls under the text floor on
  /// it.
  ///
  /// `static final` (not `const`) because a token-backed style cannot
  /// also carry a raw `fontWeight` through `CoreTextStyle.token`, so the
  /// weight arrives as a `copyWith` overlay on the token receiver — the
  /// shape `core/style-contract.md` blesses for exactly this case, and
  /// the one that keeps the role token readable instead of splitting the
  /// role away from the weight it always ships with.
  static final CoreTextStyle defaultSectionLabelTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.labelSmall,
        color: CoreColor.token(CoreColors.onSurfaceSubtle),
      ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default inset around a non-selectable section header — 18 above,
  /// 6 below, 10 either side.
  ///
  /// Its own value rather than the item padding: a header opens a group,
  /// so it keeps more room above it than below — the space above separates
  /// the group from the one before, the tight space below binds the header
  /// to the items it names. Equal gaps above and below would run the
  /// groups together. The horizontal sides match the sidebar item padding
  /// so a header's text starts on the same line as the item labels'
  /// container edge.
  static const CoreEdgeInsets defaultSectionLabelPadding = CoreEdgeInsets.only(
    left: CoreSpace.space10,
    top: CoreSpace.space18,
    right: CoreSpace.space10,
    bottom: CoreSpace.space6,
  );

  /// Default colour of a navigation divider line — `outlineSubtle`, the
  /// same step as the bar's own edge ([defaultBarBorderColor]).
  static const CoreColor defaultDividerColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Default thickness of a navigation divider line (logical px).
  static const double defaultDividerThickness = CoreStrokeWidth.stroke1;

  /// Default colour-transition duration for item hover / selection.
  static const Duration defaultDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default nested [CoreClickableStyle] slot for the composed
  /// destination `Clickable` — a partial carrying only what diverges: a
  /// destination is a compact icon + label affordance, so it takes the
  /// Clickable's own standard press-shrink (0.97) / focus ring / cursor
  /// as-is (like the dock), and turns the Clickable's generic disabled
  /// fade off, because a disabled destination paints its own disabled
  /// state with the dedicated `disabledContent` tone
  /// ([defaultDisabledLabelTextStyle] / [defaultDisabledIconStyle]) —
  /// otherwise the disabled item would fade twice. Named so the resolver's
  /// `defaultClickableStyle.merge(merged.clickableStyle)` forward has a
  /// single-source default.
  ///
  /// It also states the tile's corner ([defaultItemRadius]) as the
  /// Clickable's focus-ring radius: the ring sits outside the tile by the
  /// ring's own outset, so it is concentric with the tile only when it
  /// starts from the tile's corner — the Clickable's generic small corner
  /// would draw a ring tighter than the tile it surrounds. A style that
  /// restates [itemRadius] restates this radius too ([glassBarStyle],
  /// [glassRailStyle]).
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    borderRadius: defaultItemRadius,
    disabledOpacity: CoreOpacity.opacity100,
  );

  /// Default size of the bar while it is compact, as a factor of its resting
  /// size — `1`, which is no compact form at all ([hasCompactForm]).
  ///
  /// A bar docked to an edge holds its room in the layout and lies flush
  /// against that edge. Drawn smaller it would come away from the edge, and
  /// laid out smaller it would resize the content whose scrolling made it
  /// compact. So it has no compact form of its own, and a style that floats
  /// the bar states one ([glassBarStyle]).
  static const double defaultCompactScale = 1;

  /// Size of the floating glass bar while it is compact — 0.84 of its
  /// icon-only size, drawn about the middle of its bottom edge.
  ///
  /// Measured off the floating tab bar this form follows: its capsule, its
  /// selected face and its glyphs all draw between 0.83 and 0.84 of their
  /// resting size once the content has been scrolled, and the capsule's
  /// width — 0.84 — is the number the margins either side of it come from.
  /// A 48-tall destination draws 40 tall.
  static const double glassCompactScale = .84;

  /// Whether a bar whose style settles on [compactScale] has a compact form
  /// — anything but [defaultCompactScale].
  ///
  /// The compact form is two things together: the bar is drawn at
  /// [compactScale], and its destinations drop their captions, so a bar of
  /// captioned destinations steps back to a row of glyphs. Both platforms
  /// ask here whether to do either, so a bar cannot lose its captions on
  /// one platform and keep its size on the other.
  static bool hasCompactForm(double compactScale) =>
      compactScale != defaultCompactScale;

  /// Default time the bar takes to reach or leave its compact size.
  static const Duration defaultCompactDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default nested [CoreBadgeStyle] slot for the selection-mark dot (a
  /// `Badge(form: .dot)`), drawn when the bar's `selectionMark` is `dot` — a
  /// 4px circle in `onSurface`, the colour [defaultSelectedLabelTextStyle]
  /// gives the selected label, so the mark and the label read as one
  /// selection. Raw-forwarded to the composed `Badge`, whose resolver owns
  /// the rest.
  ///
  /// It does not follow `selectedLabelTextStyle` on its own: a bar that
  /// recolours its selected label recolours the dot here too (the glass
  /// presets state both).
  static const CoreBadgeStyle defaultSelectionMarkStyle = CoreBadgeStyle(
    backgroundColor: CoreColor.token(CoreColors.onSurface),
    dotSize: CoreSize.size4,
  );

  /// Default overlay on the selection-mark dot of a destination that is
  /// selected AND disabled — `disabledContent`, the tone the disabled label
  /// and icon take.
  ///
  /// The dot stays, dimmed, as the rest of the selection does: layered over
  /// the resolved [selectionMarkStyle] (its size and the indicator's colour),
  /// then [disabledSelectionMarkStyle].
  static const CoreBadgeStyle defaultDisabledSelectionMarkStyle =
      CoreBadgeStyle(
        backgroundColor: CoreColor.token(CoreColors.disabledContent),
      );

  /// Default spacer between the selection-mark dot and the destination's
  /// content below it — `space6`, the distance the bare-label tab bar it was
  /// added for draws.
  static const CoreGapStyle defaultSelectionMarkGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Default icon override for the selected destination — `onSurface`, the
  /// colour the selected label takes. Both indicators state their own in
  /// [defaultsByIndicator] (`primary`); this is what a caller's own
  /// indicator-less style falls back to.
  static const CoreIconStyle defaultSelectedIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default hover foreground — the transparent sentinel, which keeps the
  /// resting foreground (the state layer carries hover instead). The `color`
  /// indicator lays no wash and darkens the foreground to `onSurface`
  /// ([defaultsByIndicator]).
  static const CoreColor defaultHoverForegroundColor = CoreColor.transparent;

  /// The selected destination's face under the `fill` indicator
  /// ([defaultsByIndicator]) — `surfaceContainerHigh` over the whole tile.
  /// The `color` indicator paints none.
  ///
  /// A light grey rather than a primary container: a coloured face jumps out
  /// under a coloured brand, so the selection is carried by the primary
  /// label and glyph and the bold weight, with this tile under them
  /// (designer's decision, #6358).
  static const CoreColor defaultSelectedFaceColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// The face of a destination that is selected AND disabled under the
  /// `fill` indicator — `disabledContainer`, the area tone of a disabled
  /// control. The `color` indicator paints none here either.
  /// A disabled destination that is the current one still says which one it
  /// is; its label and glyph take the disabled tones.
  static const CoreColor defaultDisabledSelectedFaceColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// The pill colour a selected stacked destination used to paint — kept as
  /// a value while [selectedIconAnchorColor] is deprecated.
  @Deprecated(
    'No pill is drawn (since 0.184) — the selected face is '
    'defaultSelectedFaceColor.',
  )
  static const CoreColor defaultSelectedIconAnchorColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  /// The glyph colour on that pill — kept as a value while
  /// [selectedIconAnchorIconStyle] is deprecated.
  @Deprecated(
    'No pill is drawn (since 0.184) — the selected glyph takes the '
    "indicator's selectedIconStyle.",
  )
  static const CoreIconStyle defaultSelectedIconAnchorIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onPrimaryContainer),
  );

  /// The pill colour a selected and disabled destination used to paint —
  /// kept as a value while [disabledSelectedIconAnchorColor] is deprecated.
  @Deprecated(
    'No pill is drawn (since 0.184) — the selected and disabled face is '
    'defaultDisabledSelectedFaceColor.',
  )
  static const CoreColor defaultDisabledSelectedIconAnchorColor =
      CoreColor.token(CoreColors.disabledContainer);

  /// Default face of a selected AND disabled destination — no fill.
  ///
  /// The floor under the indicator cells: both state their own disabled
  /// face ([defaultsByIndicator]). The transparent sentinel keeps the field
  /// a real single source a caller's indicator-less style falls back to.
  static const CoreColor defaultDisabledSelectedBackgroundColor =
      CoreColor.transparent;

  /// Default inset of the box around a stacked destination's icon — 12 at
  /// the sides and 2 above and below, around a 24 glyph. Every stacked
  /// destination keeps the box, selected or not, so the destinations keep
  /// the width and height they had when a pill filled it.
  static const CoreEdgeInsets defaultIconAnchorPadding =
      CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space2,
      );

  /// The pill's corners — kept as a value while [iconAnchorRadius] is
  /// deprecated.
  @Deprecated(
    "No pill is drawn (since 0.184) — the selected face takes the tile's "
    'defaultItemRadius.',
  )
  static const CoreBorderRadius defaultIconAnchorRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default nested [CoreBadgeStyle] slot for the notification dot — an 8px
  /// `error` circle ringed by the chrome tier the bar sits on, so it stays a
  /// separate mark where it overlaps the glyph.
  static const CoreBadgeStyle defaultNotificationDotStyle = CoreBadgeStyle(
    backgroundColor: CoreColor.token(CoreColors.error),
    borderColor: CoreColor.token(CoreColors.surfaceContainerLow),
    borderWidth: CoreStrokeWidth.stroke1_5,
    dotSize: CoreSize.size8,
  );

  /// Default nested [CoreIndicatorStyle] slot for the notification dot — the
  /// dot's corner on the icon's top-end corner.
  static const CoreIndicatorStyle defaultNotificationDotIndicatorStyle =
      CoreIndicatorStyle(offset: CoreSpace.space0);

  /// Per-indicator defaults — how [CoreNavigationSelectionIndicator] marks the
  /// selected destination.
  ///
  /// Resolution order on both platforms, per field: the merged per-instance /
  /// theme style field, the material preset, then this cell, then the mode
  /// cell ([defaultsByMode]), then the flat default. A cell left `null` falls
  /// through.
  ///
  /// Both indicators mark the selected destination with a `primary` label
  /// and glyph at the bold weight. `fill` also paints a face on the whole
  /// tile — `surfaceContainerHigh`, the rounded box the hover wash lights
  /// (designer's decision, #6358). `color` paints no face, selected or
  /// selected and disabled: the colour and the weight carry the selection,
  /// which is what its name says, and on a phone's bottom bar a face across
  /// a wide destination reads as a heavy slab (designer's decision, #6393).
  /// On hover `fill` lays the state layer's wash, `color` lays none and
  /// darkens the foreground to `onSurface` — so a bar with no faces does not
  /// show one appearing under the pointer.
  static const Map<
    CoreNavigationSelectionIndicator,
    CoreNavigationBarIndicatorStyle
  >
  defaultsByIndicator = {
    CoreNavigationSelectionIndicator.fill: CoreNavigationBarIndicatorStyle(
      // The whole tile is the selection face, stacked or a row — the same
      // rounded box the hover wash lights, so what can be pressed and what
      // is selected are one shape (designer's decision, #6358).
      selectedBackgroundColor: defaultSelectedFaceColor,
      selectedLabelTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.primary),
      ),
      selectedIconStyle: CoreIconStyle(
        color: CoreColor.token(CoreColors.primary),
      ),
      // Selected and disabled, the tile dims to the disabled area tone.
      disabledSelectedBackgroundColor: defaultDisabledSelectedFaceColor,
    ),
    CoreNavigationSelectionIndicator.color: CoreNavigationBarIndicatorStyle(
      // No face: the primary colour and the bold weight carry the selection
      // (designer's decision, #6393).
      selectedBackgroundColor: CoreColor.transparent,
      selectedLabelTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.primary),
      ),
      selectedIconStyle: CoreIconStyle(
        color: CoreColor.token(CoreColors.primary),
      ),
      hoverForegroundColor: CoreColor.token(CoreColors.onSurface),
      // Selected and disabled, still no face — the weight tells it from the
      // other disabled destinations.
      disabledSelectedBackgroundColor: CoreColor.transparent,
      // The selection-mark dot takes the selected label's colour, so the
      // mark and the label read as one selection.
      selectionMarkStyle: CoreBadgeStyle(
        backgroundColor: CoreColor.token(CoreColors.primary),
      ),
      // Focus keeps the wash every indicator lays, under the focus ring —
      // the keyboard pose reads the same whichever indicator the bar uses.
      stateLayer: CoreStateLayer(
        hover: CoreOpacity.opacity0,
        focus: CoreOpacity.focus,
        pressed: CoreOpacity.opacity8,
      ),
    ),
  };

  /// Per-variant chrome — single source of truth shared by Flutter and
  /// Web. Navigation bar exposes one visual variant today; the map is
  /// kept so future variants flow through the Phase 6f convention.
  ///
  /// The face is `surfaceContainerLow` — the chrome tier, the step every
  /// app-frame surface that stays put sits on, one below the cards and the
  /// floating panels that open over it. The rail and the sidebar draw it;
  /// the bottom bar states its own face in its [defaultsByMode] cell
  /// (`surface`), which sits between the merged field and this one.
  static const Map<CoreNavigationBarVariant, CoreNavigationBarVariantStyle>
  defaultsByVariant = {
    CoreNavigationBarVariant.standard: CoreNavigationBarVariantStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainerLow),
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Background colour of the navigation container surface.
  final CoreColor? backgroundColor;

  /// Outer padding of the navigation container.
  ///
  /// A docked [CoreNavigationBarMode.bar] (no [barMargin]) adds the
  /// device's bottom safe area — the home indicator — to the bottom of this
  /// padding on both platforms: Flutter adds `MediaQuery.paddingOf(context)
  /// .bottom`, Web `env(safe-area-inset-bottom)`. The bar consumes the inset
  /// itself, so its face paints under the indicator and the destinations
  /// sit above it. Do not wrap it in a `SafeArea` as well; if an ancestor
  /// `SafeArea` has already consumed the inset, the bar reads zero and the
  /// inset is not added twice. A detached bar (a [barMargin], or the glass
  /// bar) does not take the inset into its padding.
  final CoreEdgeInsets? padding;

  /// The bar's own corners. `null` leaves the bar square, which is what a
  /// bar docked to an edge wants (a liquid-glass bar or rail takes its
  /// capsule from [glassStyleFor]).
  ///
  /// Distinct from the item radius: this rounds the bar, which is what
  /// makes a detached floating bar read as one object rather than a strip
  /// with rounded buttons in it.
  final CoreBorderRadius? barRadius;

  /// Space outside the bar.
  ///
  /// What detaches the bar from the edge it would otherwise sit flush
  /// against. Padding cannot express this — padding moves the items and
  /// leaves the bar's own box where it was.
  final CoreEdgeInsets? barMargin;

  /// Colour of the bar's content-facing hairline.
  ///
  /// Drawn on the edge that faces the navigated content — the top edge
  /// of a horizontal bar, the trailing (logical end) edge of a rail /
  /// sidebar.
  final CoreColor? barBorderColor;

  /// Thickness of the bar's content-facing hairline (logical px).
  final double? barBorderWidth;

  /// Gap between adjacent navigation items (logical px).
  ///
  /// The baseline lives in [defaultsByMode], not in a `defaultItemSpacing`
  /// constant. There used to be one, and it was a single `space8` for all
  /// three modes — which `bar` does not want: its items sit flush at `0`.
  /// A scalar default cannot state that, so it cannot come back; read
  /// `defaultsByMode[mode].spacing` instead.
  final double? itemSpacing;

  /// Inner padding of a navigation item.
  final CoreEdgeInsets? itemPadding;

  /// Corner radius of a navigation item.
  final CoreBorderRadius? itemRadius;

  /// Minimum height of a navigation item (logical px).
  final double? itemMinHeight;

  /// Maximum width of a navigation item (logical px).
  ///
  /// A destination still takes its equal share of the bar up to this width
  /// and shrinks below it with the others; the width left over is split on
  /// both sides, so the destinations sit together in the middle.
  /// `double.infinity` states no cap. `null` uses the mode's cap
  /// ([defaultsByMode] — the bar caps at 96), then [defaultItemMaxWidth].
  ///
  /// Reaches only destinations that share the container's main axis — a
  /// bar that scrolls because its destinations do not fit keeps their
  /// natural widths.
  final double? itemMaxWidth;

  /// Minimum painted height of a stacked destination that hides its label
  /// (logical px). Defaults to [defaultIconOnlyItemMinHeight]; a stated
  /// [itemMinHeight] reaches these destinations too when this is `null`.
  final double? iconOnlyItemMinHeight;

  /// Minimum painted width of a stacked destination that hides its label
  /// (logical px). Defaults to [defaultIconOnlyItemMinWidth].
  final double? iconOnlyItemMinWidth;

  /// Smallest region, on either axis, that accepts a pointer around a
  /// stacked destination (logical px) — hit testing only, nothing painted
  /// moves. Defaults to [defaultTouchTargetSize].
  final double? touchTargetSize;

  /// Native flex `spacing` between an item's icon and its label —
  /// passed directly to `Row.spacing` / `Column.spacing` (Flutter) and
  /// the inner flex `gap` (Web). Not wrapped in `Gap` (logical px).
  final double? labelSpacing;

  /// Navigation item icon style override. `size` defers to
  /// [defaultIconStyle].
  final CoreIconStyle? iconStyle;

  /// Icon style for a disabled destination, laid over the [iconStyle] in
  /// effect. Defaults to [defaultDisabledIconStyle].
  final CoreIconStyle? disabledIconStyle;

  /// Style for the `Indicator` that places a destination's `badge` over its
  /// icon in the bar and the rail. Laid over [defaultBadgeIndicatorStyle]
  /// and passed to the `Indicator` as is; it fills in the rest.
  final CoreIndicatorStyle? badgeIndicatorStyle;

  /// Background colour of the selected item — the whole tile, stacked or a
  /// row.
  final CoreColor? selectedBackgroundColor;

  /// Label text style override for a selected item. Text colour is
  /// carried via [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `selectedForegroundColor` field removed). Defaults to
  /// [defaultSelectedLabelTextStyle].
  final CoreTextStyle? selectedLabelTextStyle;

  /// Background colour applied to an item on hover. Defaults to
  /// [defaultHoverBackgroundColor] — transparent, i.e. no swap. Set it to
  /// paint a fill on hover INSTEAD of [stateLayer]; the two do not stack.
  ///
  /// They do not stack because two mechanisms saying the same state is how
  /// this component's hover drifted in the first place.
  final CoreColor? hoverBackgroundColor;

  /// Ramp laid over the bar while a destination is hovered, focused or
  /// pressed. Defaults to [defaultStateLayer].
  final CoreStateLayer? stateLayer;

  /// Ink [stateLayer] lays over the bar. Defaults to
  /// [defaultStateLayerColor].
  final CoreColor? stateLayerColor;

  /// Label text style override for an unselected item. Text colour is
  /// carried via [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `foregroundColor` field removed). Defaults to
  /// [defaultLabelTextStyle].
  final CoreTextStyle? labelTextStyle;

  /// Label text style override for a disabled item. Text colour is
  /// carried via [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `disabledForegroundColor` field removed). Defaults to
  /// [defaultDisabledLabelTextStyle].
  final CoreTextStyle? disabledLabelTextStyle;

  /// Label text style override for a destination that is selected AND
  /// disabled, layered over [disabledLabelTextStyle]. Defaults to
  /// [defaultDisabledSelectedLabelTextStyle].
  final CoreTextStyle? disabledSelectedLabelTextStyle;

  /// Text style override for a non-selectable section header. The
  /// semibold weight and `onSurfaceSubtle` colour live in the
  /// [defaultSectionLabelTextStyle] overlay; this slot tweaks them per
  /// instance. Defaults to [defaultSectionLabelTextStyle].
  final CoreTextStyle? sectionLabelTextStyle;

  /// Inset around a non-selectable section header. Defaults to
  /// [defaultSectionLabelPadding].
  final CoreEdgeInsets? sectionLabelPadding;

  /// Colour of a navigation divider line.
  final CoreColor? dividerColor;

  /// Thickness of a navigation divider line (logical px).
  final double? dividerThickness;

  /// Colour-transition duration for item hover / selection.
  final Duration? duration;

  /// Style for each destination's `Clickable` — press scale, focus ring,
  /// cursor, keyboard activation. Laid over [defaultClickableStyle] and
  /// passed to the `Clickable` as is; it fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Style for the selection-mark dot. Laid over [defaultSelectionMarkStyle]
  /// and passed as is to the `Badge(form: .dot)` that draws it. Read only
  /// while the bar's `selectionMark` is `dot`.
  final CoreBadgeStyle? selectionMarkStyle;

  /// Space between the selection-mark dot and the content under it. Laid
  /// over [defaultSelectionMarkGapStyle] and passed as is to `Gap`.
  final CoreGapStyle? selectionMarkGapStyle;

  /// Badge style laid over the selection-mark dot of a selected, disabled
  /// destination — on top of the [selectionMarkStyle] in effect and
  /// [defaultDisabledSelectionMarkStyle].
  final CoreBadgeStyle? disabledSelectionMarkStyle;

  /// Icon style for the selected destination, laid over the [iconStyle] in
  /// effect (size from there, colour from here). Defaults to
  /// [defaultSelectedIconStyle], with the indicator's own colour
  /// ([defaultsByIndicator]) between the two.
  final CoreIconStyle? selectedIconStyle;

  /// Foreground (label and icon) colour of a hovered, unselected destination.
  /// Defaults to [defaultHoverForegroundColor] — the transparent sentinel,
  /// which leaves the resting foreground in place; the `color` indicator
  /// states `onSurface` in [defaultsByIndicator].
  final CoreColor? hoverForegroundColor;

  /// No longer read: no destination draws a pill — a selected destination
  /// paints its whole tile in [selectedBackgroundColor].
  @Deprecated(
    'No pill is drawn (since 0.184) — the selected destination paints its '
    'whole tile. Use selectedBackgroundColor.',
  )
  final CoreColor? selectedIconAnchorColor;

  /// No longer read: the selected glyph takes [selectedIconStyle].
  @Deprecated(
    'No pill is drawn (since 0.184) — the selected destination paints its '
    'whole tile. Use selectedIconStyle.',
  )
  final CoreIconStyle? selectedIconAnchorIconStyle;

  /// Face of a destination that is selected AND disabled — the whole tile.
  /// Defaults to [defaultDisabledSelectedBackgroundColor], with the
  /// indicator's own ([defaultsByIndicator]) between the two.
  final CoreColor? disabledSelectedBackgroundColor;

  /// No longer read: a selected and disabled destination dims its whole
  /// tile to [disabledSelectedBackgroundColor].
  @Deprecated(
    'No pill is drawn (since 0.184) — the selected destination paints its '
    'whole tile. Use disabledSelectedBackgroundColor.',
  )
  final CoreColor? disabledSelectedIconAnchorColor;

  /// Inset of the box around a stacked destination's icon. Defaults to
  /// [defaultIconAnchorPadding].
  final CoreEdgeInsets? iconAnchorPadding;

  /// No longer read: the selected face takes the tile's [itemRadius].
  @Deprecated(
    'No pill is drawn (since 0.184) — the selected face takes the '
    "tile's itemRadius.",
  )
  final CoreBorderRadius? iconAnchorRadius;

  /// Style for a destination's notification dot (`showDot`). Laid over
  /// [defaultNotificationDotStyle] and passed as is to the
  /// `Badge(form: .dot)` that draws it.
  final CoreBadgeStyle? notificationDotStyle;

  /// Style for the `Indicator` that places the notification dot over the
  /// icon's top-end corner. Laid over [defaultNotificationDotIndicatorStyle]
  /// and passed to the `Indicator` as is.
  final CoreIndicatorStyle? notificationDotIndicatorStyle;

  /// Size the bar is drawn at while it is compact, as a factor of its
  /// resting size. `null` uses [defaultCompactScale] — `1`, so a docked bar
  /// does not change — and the floating glass bar states
  /// [glassCompactScale].
  ///
  /// The scale is drawn only, about the middle of the bottom edge for the
  /// horizontal bar and about the centre for the vertical modes. A bar that
  /// has a compact form ([hasCompactForm]) also drops its destinations'
  /// captions while compact — a hidden caption is still the destination's
  /// accessible name — so the bar is laid out as a row of glyphs and then
  /// drawn at this size. Read only while the bar's `compact` asks for the
  /// compact form.
  final double? compactScale;

  /// Time the bar takes to reach or leave its compact size. `null` uses
  /// [defaultCompactDuration].
  final Duration? compactDuration;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreNavigationBarStyle merge(CoreNavigationBarStyle? other) {
    if (other == null) return this;
    return CoreNavigationBarStyle(
      surfaceStyle: other.surfaceStyle ?? surfaceStyle,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      padding: other.padding ?? padding,
      barRadius: other.barRadius ?? barRadius,
      barMargin: other.barMargin ?? barMargin,
      barBorderColor: other.barBorderColor ?? barBorderColor,
      barBorderWidth: other.barBorderWidth ?? barBorderWidth,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      itemPadding: other.itemPadding ?? itemPadding,
      itemRadius: other.itemRadius ?? itemRadius,
      itemMinHeight: other.itemMinHeight ?? itemMinHeight,
      itemMaxWidth: other.itemMaxWidth ?? itemMaxWidth,
      iconOnlyItemMinHeight:
          other.iconOnlyItemMinHeight ?? iconOnlyItemMinHeight,
      iconOnlyItemMinWidth: other.iconOnlyItemMinWidth ?? iconOnlyItemMinWidth,
      touchTargetSize: other.touchTargetSize ?? touchTargetSize,
      labelSpacing: other.labelSpacing ?? labelSpacing,
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      disabledIconStyle: _mergeIcon(disabledIconStyle, other.disabledIconStyle),
      badgeIndicatorStyle:
          badgeIndicatorStyle?.merge(other.badgeIndicatorStyle) ??
          other.badgeIndicatorStyle,
      selectedBackgroundColor:
          other.selectedBackgroundColor ?? selectedBackgroundColor,
      selectedLabelTextStyle: _mergeText(
        selectedLabelTextStyle,
        other.selectedLabelTextStyle,
      ),
      hoverBackgroundColor: other.hoverBackgroundColor ?? hoverBackgroundColor,
      stateLayer: other.stateLayer ?? stateLayer,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      disabledLabelTextStyle: _mergeText(
        disabledLabelTextStyle,
        other.disabledLabelTextStyle,
      ),
      disabledSelectedLabelTextStyle: _mergeText(
        disabledSelectedLabelTextStyle,
        other.disabledSelectedLabelTextStyle,
      ),
      sectionLabelTextStyle: _mergeText(
        sectionLabelTextStyle,
        other.sectionLabelTextStyle,
      ),
      sectionLabelPadding: other.sectionLabelPadding ?? sectionLabelPadding,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerThickness: other.dividerThickness ?? dividerThickness,
      duration: other.duration ?? duration,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      selectionMarkStyle:
          selectionMarkStyle?.merge(other.selectionMarkStyle) ??
          other.selectionMarkStyle,
      selectionMarkGapStyle:
          selectionMarkGapStyle?.merge(other.selectionMarkGapStyle) ??
          other.selectionMarkGapStyle,
      disabledSelectionMarkStyle:
          disabledSelectionMarkStyle?.merge(other.disabledSelectionMarkStyle) ??
          other.disabledSelectionMarkStyle,
      selectedIconStyle: _mergeIcon(selectedIconStyle, other.selectedIconStyle),
      hoverForegroundColor: other.hoverForegroundColor ?? hoverForegroundColor,
      selectedIconAnchorColor:
          other.selectedIconAnchorColor ?? selectedIconAnchorColor,
      selectedIconAnchorIconStyle: _mergeIcon(
        selectedIconAnchorIconStyle,
        other.selectedIconAnchorIconStyle,
      ),
      disabledSelectedBackgroundColor:
          other.disabledSelectedBackgroundColor ??
          disabledSelectedBackgroundColor,
      disabledSelectedIconAnchorColor:
          other.disabledSelectedIconAnchorColor ??
          disabledSelectedIconAnchorColor,
      iconAnchorPadding: other.iconAnchorPadding ?? iconAnchorPadding,
      iconAnchorRadius: other.iconAnchorRadius ?? iconAnchorRadius,
      notificationDotStyle:
          notificationDotStyle?.merge(other.notificationDotStyle) ??
          other.notificationDotStyle,
      notificationDotIndicatorStyle:
          notificationDotIndicatorStyle?.merge(
            other.notificationDotIndicatorStyle,
          ) ??
          other.notificationDotIndicatorStyle,
      compactScale: other.compactScale ?? compactScale,
      compactDuration: other.compactDuration ?? compactDuration,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreNavigationBarStyle copyWith({
    CoreSurfaceStyleId? surfaceStyle,
    CoreColor? backgroundColor,
    CoreEdgeInsets? padding,
    CoreBorderRadius? barRadius,
    CoreEdgeInsets? barMargin,
    CoreColor? barBorderColor,
    double? barBorderWidth,
    double? itemSpacing,
    CoreEdgeInsets? itemPadding,
    CoreBorderRadius? itemRadius,
    double? itemMinHeight,
    double? itemMaxWidth,
    double? iconOnlyItemMinHeight,
    double? iconOnlyItemMinWidth,
    double? touchTargetSize,
    double? labelSpacing,
    CoreIconStyle? iconStyle,
    CoreIconStyle? disabledIconStyle,
    CoreIndicatorStyle? badgeIndicatorStyle,
    CoreColor? selectedBackgroundColor,
    CoreTextStyle? selectedLabelTextStyle,
    CoreColor? hoverBackgroundColor,
    CoreStateLayer? stateLayer,
    CoreColor? stateLayerColor,
    CoreTextStyle? labelTextStyle,
    CoreTextStyle? disabledLabelTextStyle,
    CoreTextStyle? disabledSelectedLabelTextStyle,
    CoreTextStyle? sectionLabelTextStyle,
    CoreEdgeInsets? sectionLabelPadding,
    CoreColor? dividerColor,
    double? dividerThickness,
    Duration? duration,
    CoreClickableStyle? clickableStyle,
    CoreBadgeStyle? selectionMarkStyle,
    CoreGapStyle? selectionMarkGapStyle,
    CoreBadgeStyle? disabledSelectionMarkStyle,
    CoreIconStyle? selectedIconStyle,
    CoreColor? hoverForegroundColor,
    CoreColor? selectedIconAnchorColor,
    CoreIconStyle? selectedIconAnchorIconStyle,
    CoreColor? disabledSelectedBackgroundColor,
    CoreColor? disabledSelectedIconAnchorColor,
    CoreEdgeInsets? iconAnchorPadding,
    CoreBorderRadius? iconAnchorRadius,
    CoreBadgeStyle? notificationDotStyle,
    CoreIndicatorStyle? notificationDotIndicatorStyle,
    double? compactScale,
    Duration? compactDuration,
  }) {
    return CoreNavigationBarStyle(
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      padding: padding ?? this.padding,
      barRadius: barRadius ?? this.barRadius,
      barMargin: barMargin ?? this.barMargin,
      barBorderColor: barBorderColor ?? this.barBorderColor,
      barBorderWidth: barBorderWidth ?? this.barBorderWidth,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      itemPadding: itemPadding ?? this.itemPadding,
      itemRadius: itemRadius ?? this.itemRadius,
      itemMinHeight: itemMinHeight ?? this.itemMinHeight,
      itemMaxWidth: itemMaxWidth ?? this.itemMaxWidth,
      iconOnlyItemMinHeight:
          iconOnlyItemMinHeight ?? this.iconOnlyItemMinHeight,
      iconOnlyItemMinWidth: iconOnlyItemMinWidth ?? this.iconOnlyItemMinWidth,
      touchTargetSize: touchTargetSize ?? this.touchTargetSize,
      labelSpacing: labelSpacing ?? this.labelSpacing,
      iconStyle: iconStyle ?? this.iconStyle,
      disabledIconStyle: disabledIconStyle ?? this.disabledIconStyle,
      badgeIndicatorStyle: badgeIndicatorStyle ?? this.badgeIndicatorStyle,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      selectedLabelTextStyle:
          selectedLabelTextStyle ?? this.selectedLabelTextStyle,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      stateLayer: stateLayer ?? this.stateLayer,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      disabledLabelTextStyle:
          disabledLabelTextStyle ?? this.disabledLabelTextStyle,
      disabledSelectedLabelTextStyle:
          disabledSelectedLabelTextStyle ?? this.disabledSelectedLabelTextStyle,
      sectionLabelTextStyle:
          sectionLabelTextStyle ?? this.sectionLabelTextStyle,
      sectionLabelPadding: sectionLabelPadding ?? this.sectionLabelPadding,
      dividerColor: dividerColor ?? this.dividerColor,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      duration: duration ?? this.duration,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      selectionMarkStyle: selectionMarkStyle ?? this.selectionMarkStyle,
      selectionMarkGapStyle:
          selectionMarkGapStyle ?? this.selectionMarkGapStyle,
      disabledSelectionMarkStyle:
          disabledSelectionMarkStyle ?? this.disabledSelectionMarkStyle,
      selectedIconStyle: selectedIconStyle ?? this.selectedIconStyle,
      hoverForegroundColor: hoverForegroundColor ?? this.hoverForegroundColor,
      selectedIconAnchorColor:
          selectedIconAnchorColor ?? this.selectedIconAnchorColor,
      selectedIconAnchorIconStyle:
          selectedIconAnchorIconStyle ?? this.selectedIconAnchorIconStyle,
      disabledSelectedBackgroundColor:
          disabledSelectedBackgroundColor ??
          this.disabledSelectedBackgroundColor,
      disabledSelectedIconAnchorColor:
          disabledSelectedIconAnchorColor ??
          this.disabledSelectedIconAnchorColor,
      iconAnchorPadding: iconAnchorPadding ?? this.iconAnchorPadding,
      iconAnchorRadius: iconAnchorRadius ?? this.iconAnchorRadius,
      notificationDotStyle: notificationDotStyle ?? this.notificationDotStyle,
      notificationDotIndicatorStyle:
          notificationDotIndicatorStyle ?? this.notificationDotIndicatorStyle,
      compactScale: compactScale ?? this.compactScale,
      compactDuration: compactDuration ?? this.compactDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNavigationBarStyle &&
          runtimeType == other.runtimeType &&
          surfaceStyle == other.surfaceStyle &&
          backgroundColor == other.backgroundColor &&
          padding == other.padding &&
          barRadius == other.barRadius &&
          barMargin == other.barMargin &&
          barBorderColor == other.barBorderColor &&
          barBorderWidth == other.barBorderWidth &&
          itemSpacing == other.itemSpacing &&
          itemPadding == other.itemPadding &&
          itemRadius == other.itemRadius &&
          itemMinHeight == other.itemMinHeight &&
          itemMaxWidth == other.itemMaxWidth &&
          iconOnlyItemMinHeight == other.iconOnlyItemMinHeight &&
          iconOnlyItemMinWidth == other.iconOnlyItemMinWidth &&
          touchTargetSize == other.touchTargetSize &&
          labelSpacing == other.labelSpacing &&
          iconStyle == other.iconStyle &&
          disabledIconStyle == other.disabledIconStyle &&
          badgeIndicatorStyle == other.badgeIndicatorStyle &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          selectedLabelTextStyle == other.selectedLabelTextStyle &&
          hoverBackgroundColor == other.hoverBackgroundColor &&
          stateLayer == other.stateLayer &&
          stateLayerColor == other.stateLayerColor &&
          labelTextStyle == other.labelTextStyle &&
          disabledLabelTextStyle == other.disabledLabelTextStyle &&
          disabledSelectedLabelTextStyle ==
              other.disabledSelectedLabelTextStyle &&
          sectionLabelTextStyle == other.sectionLabelTextStyle &&
          sectionLabelPadding == other.sectionLabelPadding &&
          dividerColor == other.dividerColor &&
          dividerThickness == other.dividerThickness &&
          duration == other.duration &&
          clickableStyle == other.clickableStyle &&
          selectionMarkStyle == other.selectionMarkStyle &&
          selectionMarkGapStyle == other.selectionMarkGapStyle &&
          disabledSelectionMarkStyle == other.disabledSelectionMarkStyle &&
          selectedIconStyle == other.selectedIconStyle &&
          hoverForegroundColor == other.hoverForegroundColor &&
          selectedIconAnchorColor == other.selectedIconAnchorColor &&
          selectedIconAnchorIconStyle == other.selectedIconAnchorIconStyle &&
          disabledSelectedBackgroundColor ==
              other.disabledSelectedBackgroundColor &&
          disabledSelectedIconAnchorColor ==
              other.disabledSelectedIconAnchorColor &&
          iconAnchorPadding == other.iconAnchorPadding &&
          iconAnchorRadius == other.iconAnchorRadius &&
          notificationDotStyle == other.notificationDotStyle &&
          notificationDotIndicatorStyle ==
              other.notificationDotIndicatorStyle &&
          compactScale == other.compactScale &&
          compactDuration == other.compactDuration;

  @override
  int get hashCode => Object.hashAll([
    surfaceStyle,
    backgroundColor,
    padding,
    barRadius,
    barMargin,
    barBorderColor,
    barBorderWidth,
    itemSpacing,
    itemPadding,
    itemRadius,
    itemMinHeight,
    itemMaxWidth,
    iconOnlyItemMinHeight,
    iconOnlyItemMinWidth,
    touchTargetSize,
    labelSpacing,
    iconStyle,
    disabledIconStyle,
    badgeIndicatorStyle,
    selectedBackgroundColor,
    selectedLabelTextStyle,
    hoverBackgroundColor,
    stateLayer,
    stateLayerColor,
    labelTextStyle,
    disabledLabelTextStyle,
    disabledSelectedLabelTextStyle,
    sectionLabelTextStyle,
    sectionLabelPadding,
    dividerColor,
    dividerThickness,
    duration,
    clickableStyle,
    selectionMarkStyle,
    selectionMarkGapStyle,
    disabledSelectionMarkStyle,
    selectedIconStyle,
    hoverForegroundColor,
    selectedIconAnchorColor,
    selectedIconAnchorIconStyle,
    disabledSelectedBackgroundColor,
    disabledSelectedIconAnchorColor,
    iconAnchorPadding,
    iconAnchorRadius,
    notificationDotStyle,
    notificationDotIndicatorStyle,
    compactScale,
    compactDuration,
  ]);

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
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
}

/// Mode-dependent chrome for a `NavigationBar` — the per-mode default
/// table [CoreNavigationBarStyle.defaultsByMode] holds one of these per
/// [CoreNavigationBarMode].
///
/// Every cell but [spacing] is optional: a `null` cell means "this mode
/// draws the flat `CoreNavigationBarStyle.default*` value", so a mode
/// states only where its density differs. Each cell sits between the
/// merged per-instance / theme field of the same name and that flat
/// default.
@immutable
class CoreNavigationBarModeStyle {
  /// Creates a [CoreNavigationBarModeStyle].
  const CoreNavigationBarModeStyle({
    required this.spacing,
    this.padding,
    this.itemMinHeight,
    this.itemMaxWidth,
    this.itemPadding,
    this.iconStyle,
    this.labelSpacing,
    this.labelTextStyle,
    this.selectedBackgroundColor,
    this.backgroundColor,
  });

  /// Default gap between adjacent navigation items for this mode
  /// (logical px). Named `spacing`, not `itemSpacing` — this class is
  /// already scoped to "this mode's item spacing" by its own name, and
  /// a bare `double` field ending in `Spacing` reads as the nullable
  /// `CoreXxxStyle` override slot rule (`check_gap_spacing_naming.sh`)
  /// rather than this map-value holder's own required default.
  final double spacing;

  /// Outer padding of the navigation container in this mode. `null` uses
  /// `CoreNavigationBarStyle.defaultPadding`.
  ///
  /// Deliberately has no `default*` of its own: `null` says "this mode draws
  /// the flat value", and the flat value is
  /// `CoreNavigationBarStyle.defaultPadding`. A second constant here would
  /// fork the bar's and the rail's padding from the one a cell left `null`
  /// falls through to.
  final CoreEdgeInsets? padding;

  /// Minimum height of a navigation item in this mode (logical px). `null`
  /// uses `CoreNavigationBarStyle.defaultItemMinHeight`.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to
  /// `CoreNavigationBarStyle.defaultItemMinHeight`, the bar and rail height
  /// every app's bottom bar already draws. A cell-level default would move
  /// that height for the modes that state nothing.
  final double? itemMinHeight;

  /// Maximum width of a navigation item in this mode (logical px). `null`
  /// uses `CoreNavigationBarStyle.defaultItemMaxWidth` — no cap.
  ///
  /// The bar states 96, so the destinations of a bar wider than a phone
  /// gather in the middle instead of spreading across it; the rail and the
  /// sidebar size their destinations by their own column and state nothing.
  final double? itemMaxWidth;

  /// Inner padding of a navigation item in this mode. `null` uses
  /// `CoreNavigationBarStyle.defaultItemPadding`.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to
  /// `CoreNavigationBarStyle.defaultItemPadding`, which stays the single
  /// source for the modes that state nothing.
  final CoreEdgeInsets? itemPadding;

  /// Icon style partial for this mode, layered between
  /// `CoreNavigationBarStyle.defaultIconStyle` and the merged override.
  ///
  /// Deliberately has no `default*` of its own: `null` leaves the flat
  /// default alone, and a partial stated here only moves the fields it
  /// names (the sidebar names the size).
  final CoreIconStyle? iconStyle;

  /// Native flex spacing between an item's icon and its label in this
  /// mode (logical px). `null` uses
  /// `CoreNavigationBarStyle.defaultLabelSpacing`.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to
  /// `CoreNavigationBarStyle.defaultLabelSpacing`.
  final double? labelSpacing;

  /// Destination label typography role for this mode, layered over every
  /// per-state label default (selected / unselected / disabled) so the
  /// three keep their own colour and weight and take this role. A role,
  /// not a font size — the role brings its own tracking and line box with
  /// it.
  ///
  /// Deliberately has no `default*` of its own: `null` leaves each
  /// per-state default on its own `labelSmall`, which a bar and a rail
  /// draw.
  final CoreTextStyle? labelTextStyle;

  /// Background colour of the selected item in this mode. `null` uses
  /// `CoreNavigationBarStyle.defaultSelectedBackgroundColor` — no fill.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to
  /// `CoreNavigationBarStyle.defaultSelectedBackgroundColor`, the no-fill
  /// a bar and a rail draw — selection reads through the label there.
  final CoreColor? selectedBackgroundColor;

  /// Background colour of the navigation container surface in this mode.
  /// `null` uses the variant's face
  /// (`CoreNavigationBarStyle.defaultsByVariant`), as the rail and the
  /// sidebar do; the bar mode sets `surface`.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to
  /// the variant's face (`CoreNavigationBarStyle.defaultsByVariant`), the
  /// chrome tier a rail and a sidebar draw. The bar states `surface`.
  final CoreColor? backgroundColor;

  /// Returns a copy with the supplied non-null fields overridden.
  CoreNavigationBarModeStyle copyWith({
    double? spacing,
    CoreEdgeInsets? padding,
    double? itemMinHeight,
    double? itemMaxWidth,
    CoreEdgeInsets? itemPadding,
    CoreIconStyle? iconStyle,
    double? labelSpacing,
    CoreTextStyle? labelTextStyle,
    CoreColor? selectedBackgroundColor,
    CoreColor? backgroundColor,
  }) {
    return CoreNavigationBarModeStyle(
      spacing: spacing ?? this.spacing,
      padding: padding ?? this.padding,
      itemMinHeight: itemMinHeight ?? this.itemMinHeight,
      itemMaxWidth: itemMaxWidth ?? this.itemMaxWidth,
      itemPadding: itemPadding ?? this.itemPadding,
      iconStyle: iconStyle ?? this.iconStyle,
      labelSpacing: labelSpacing ?? this.labelSpacing,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNavigationBarModeStyle &&
          runtimeType == other.runtimeType &&
          spacing == other.spacing &&
          padding == other.padding &&
          itemMinHeight == other.itemMinHeight &&
          itemMaxWidth == other.itemMaxWidth &&
          itemPadding == other.itemPadding &&
          iconStyle == other.iconStyle &&
          labelSpacing == other.labelSpacing &&
          labelTextStyle == other.labelTextStyle &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(
    spacing,
    padding,
    itemMinHeight,
    itemMaxWidth,
    itemPadding,
    iconStyle,
    labelSpacing,
    labelTextStyle,
    selectedBackgroundColor,
    backgroundColor,
  );
}

/// Variant-dependent chrome for a `NavigationBar`.
@immutable
class CoreNavigationBarVariantStyle {
  /// Creates a [CoreNavigationBarVariantStyle].
  const CoreNavigationBarVariantStyle({required this.backgroundColor});

  /// Default container background colour for this variant.
  final CoreColor backgroundColor;
}

/// Indicator-dependent chrome for a `NavigationBar` — the per-indicator
/// default table [CoreNavigationBarStyle.defaultsByIndicator] holds one of
/// these per [CoreNavigationSelectionIndicator].
///
/// Every cell is optional: a `null` cell falls through to the mode cell and
/// the flat default of the same name.
@immutable
class CoreNavigationBarIndicatorStyle {
  /// Creates a [CoreNavigationBarIndicatorStyle].
  const CoreNavigationBarIndicatorStyle({
    this.selectedBackgroundColor,
    this.selectedLabelTextStyle,
    this.selectedIconStyle,
    this.hoverForegroundColor,
    this.selectionMarkStyle,
    this.stateLayer,
    this.selectedRowLabelTextStyle,
    this.disabledSelectedBackgroundColor,
  });

  /// Face of the selected destination under this indicator.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to the
  /// mode cell and `CoreNavigationBarStyle.defaultSelectedBackgroundColor`.
  final CoreColor? selectedBackgroundColor;

  /// Overlay on the selected label under this indicator (colour and weight).
  /// `null` keeps `CoreNavigationBarStyle.defaultSelectedLabelTextStyle` as
  /// it is.
  ///
  /// Deliberately has no `default*` of its own: `null` leaves
  /// `CoreNavigationBarStyle.defaultSelectedLabelTextStyle` alone.
  final CoreTextStyle? selectedLabelTextStyle;

  /// Overlay on the selected icon under this indicator.
  ///
  /// Deliberately has no `default*` of its own: `null` leaves
  /// `CoreNavigationBarStyle.defaultSelectedIconStyle` alone.
  final CoreIconStyle? selectedIconStyle;

  /// Hover foreground under this indicator. `null` uses
  /// `CoreNavigationBarStyle.defaultHoverForegroundColor`.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to
  /// `CoreNavigationBarStyle.defaultHoverForegroundColor`.
  final CoreColor? hoverForegroundColor;

  /// Overlay on the selection-mark dot under this indicator.
  ///
  /// Deliberately has no `default*` of its own: `null` leaves
  /// `CoreNavigationBarStyle.defaultSelectionMarkStyle` alone.
  final CoreBadgeStyle? selectionMarkStyle;

  /// State-layer ramp under this indicator. `null` uses
  /// `CoreNavigationBarStyle.defaultStateLayer`.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to
  /// `CoreNavigationBarStyle.defaultStateLayer`.
  final CoreStateLayer? stateLayer;

  /// Overlay on a selected row's label under this indicator, layered over
  /// [selectedLabelTextStyle].
  ///
  /// Deliberately has no `default*` of its own: `null` leaves the selected
  /// label as [selectedLabelTextStyle] states it.
  final CoreTextStyle? selectedRowLabelTextStyle;

  /// Face of a selected, disabled destination that paints its selection on
  /// the tile, under this indicator. `null` uses
  /// `CoreNavigationBarStyle.defaultDisabledSelectedBackgroundColor`.
  ///
  /// Deliberately has no `default*` of its own: `null` falls through to
  /// `CoreNavigationBarStyle.defaultDisabledSelectedBackgroundColor`.
  final CoreColor? disabledSelectedBackgroundColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreNavigationBarIndicatorStyle &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          selectedLabelTextStyle == other.selectedLabelTextStyle &&
          selectedIconStyle == other.selectedIconStyle &&
          hoverForegroundColor == other.hoverForegroundColor &&
          selectionMarkStyle == other.selectionMarkStyle &&
          stateLayer == other.stateLayer &&
          selectedRowLabelTextStyle == other.selectedRowLabelTextStyle &&
          disabledSelectedBackgroundColor ==
              other.disabledSelectedBackgroundColor;

  @override
  int get hashCode => Object.hash(
    selectedBackgroundColor,
    selectedLabelTextStyle,
    selectedIconStyle,
    hoverForegroundColor,
    selectionMarkStyle,
    stateLayer,
    selectedRowLabelTextStyle,
    disabledSelectedBackgroundColor,
  );
}
