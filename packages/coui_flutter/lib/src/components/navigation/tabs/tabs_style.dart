import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedTabs
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Tabs`.
///
/// Single struct that the widget reads — every tab-bar chrome /
/// dimensional override has had the nested merge chain applied plus
/// the `CoreTabsStyle.defaultsByVariant` / `CoreTabsStyle.defaultX`
/// fallback and Flutter type conversion:
///
/// ```text
/// CoreTabsStyle.defaultX / defaultsByVariant
///   → theme.coreComponentTheme.tabs.style
///   → theme.coreComponentTheme.tabs.variantStyles[variant]
///   → widget.tabsStyle
/// ```
///
/// **Scaling boundary (Epic #1603 C12)** — every dimensional field
/// (`*Padding`, `*Radius`, `*Thickness`, `borderWidth`, `tabSpacing`)
/// is materialised with `theme.scaling` pre-applied in [resolveTabs],
/// mirroring the `Button` resolver baking `* scaling` into its `gap`.
/// `co_tabs` reads `resolved.*` straight into the widget tree and never
/// re-multiplies by `theme.scaling`. `swipeSensitivity` (a velocity
/// threshold) and `indicatorTransitionDuration` (a [Duration]) are
/// semantic values, not layout dimensions, so they stay unscaled.
class ResolvedTabs {
  /// Creates a [ResolvedTabs].
  const ResolvedTabs({
    required this.backgroundColor,
    required this.activeIndicatorColor,
    required this.disabledIndicatorColor,
    required this.inactiveIndicatorColor,
    required this.clickableStyle,
    required this.activeIndicatorRadius,
    required this.activeIndicatorThickness,
    required this.borderColor,
    required this.borderWidth,
    required this.activeContentColor,
    required this.inactiveContentColor,
    required this.tabBarPadding,
    required this.tabPadding,
    required this.containerRadius,
    required this.tabSpacing,
    required this.indicatorTransitionDuration,
    required this.swipeSensitivity,
    required this.itemHeight,
    required this.activeContentTextStyle,
    required this.inactiveContentTextStyle,
    required this.disabledContentColor,
    required this.hoverStateLayerColor,
    required this.pressedStateLayerColor,
    required this.boxShadow,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.labelBadgeGapStyle,
    required this.closeButtonStyle,
    required this.closeIconStyle,
  });

  /// Effective tab-bar container background colour (`null` for the
  /// `underline` variant — no surface fill).
  final Color? backgroundColor;

  /// Effective active-indicator (pill fill / underline) colour.
  final Color activeIndicatorColor;

  /// Indicator colour for a selected tab that is DISABLED — the variant's
  /// `disabledIndicatorColor` (`disabled-container` for the pill's fill,
  /// `disabled-content` for the underline's rule). A disabled tab keeps
  /// its indicator so it can still say which one is current.
  final Color disabledIndicatorColor;

  /// Inactive indicator colour — [activeIndicatorColor] at alpha 0
  /// (hue held). `AnimatedContainer` lerps the underline border
  /// between states; a plain transparent BLACK would drag the
  /// midpoints through dark grey and flash on every tab switch.
  final Color inactiveIndicatorColor;

  /// Nested [CoreClickableStyle] slot for the composed per-tab
  /// `Clickable` — `CoreTabsStyle.defaultClickableStyle` merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Effective active-indicator (pill) corner radius (scaling
  /// pre-applied).
  final BorderRadius activeIndicatorRadius;

  /// Effective active-indicator (underline) thickness (logical px,
  /// scaling pre-applied).
  final double activeIndicatorThickness;

  /// Effective tab/content separator border colour (`null` for the
  /// `pill` variant — no border).
  final Color? borderColor;

  /// Effective tab/content separator border thickness (logical px,
  /// scaling pre-applied; underline variant only — falls back to the
  /// token default).
  final double borderWidth;

  /// Effective active tab content colour.
  final Color activeContentColor;

  /// Effective inactive tab content colour.
  final Color inactiveContentColor;

  /// Effective tab-bar container padding (scaling pre-applied).
  final EdgeInsets tabBarPadding;

  /// Effective per-tab button padding (scaling pre-applied).
  final EdgeInsets tabPadding;

  /// Effective tab-bar container corner radius (scaling pre-applied).
  final BorderRadius containerRadius;

  /// Effective inter-tab spacing (logical px, scaling pre-applied) —
  /// applied to `Row(spacing:)` between adjacent tab buttons.
  final double tabSpacing;

  /// Effective active-indicator colour-transition duration.
  final Duration indicatorTransitionDuration;

  /// Effective minimum horizontal drag distance / swipe velocity to
  /// trigger a tab switch (logical px / sec).
  final double swipeSensitivity;

  /// Effective individual tab item height floor (logical px, scaling
  /// and `MediaQuery.textScaler` pre-applied) — `CoreTabsStyle.tabHeight`
  /// of the size rung: the rung itself where the variant row has no track
  /// around its tabs, and the rung less [tabBarPadding]'s top and bottom
  /// where the rung is the track's (`CoreTabVariantStyle.sizeRungIsTrack`),
  /// so the track around the tab stands at the rung. Distinct from
  /// `ResolvedTabPane.barHeight` (the surrounding `TabPane` bar container).
  /// The widget treats this as `minHeight`, not a clip.
  final double itemHeight;

  /// Paint-ready label text style of the SELECTED tab — the variant's (else
  /// the rung's) typography role with the variant's `activeFontWeight`, and
  /// the per-instance `contentTextStyle` override merged in. The widget
  /// layers the per-tab content colour on top with `copyWith(color: …)`.
  final TextStyle activeContentTextStyle;

  /// Paint-ready label text style of every tab that is not selected — the
  /// same role as [activeContentTextStyle] with the variant's
  /// `inactiveFontWeight`.
  final TextStyle inactiveContentTextStyle;

  /// Label / indicator colour when a tab item is disabled.
  final Color disabledContentColor;

  /// Hover state-layer colour, laid over an enabled item while the
  /// pointer is over it.
  final Color hoverStateLayerColor;

  /// Pressed state-layer colour.
  final Color pressedStateLayerColor;

  /// The active surface style's injected cast, or empty under a
  /// style that injects none.
  ///
  /// This surface draws its own box rather than composing
  /// `OutlinedContainer`, so the opt-in is restated. Empty under
  /// every style that casts nothing, so the widget paints it
  /// unconditionally.
  final List<BoxShadow> boxShadow;

  /// Backdrop blur sigma for the `pill` container, `null` for the
  /// `underline` variant (no fill to blur behind) or when the active
  /// theme states no material.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  ///
  /// Rides the same backdrop pass as [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Nested [CoreGapStyle] slot for the 1-off spacer between a tab's
  /// label and its `CoreTabItem.badge` —
  /// `CoreTabsStyle.defaultLabelBadgeGapStyle` merged with the
  /// per-instance override, raw-forwarded to `Gap(gapStyle:)` (the Gap's
  /// own resolver scales it). The widget composes the `Gap` only for an
  /// item that carries a badge, and before the close affordance of an
  /// item that carries `CoreTabItem.onClose`.
  final CoreGapStyle labelBadgeGapStyle;

  /// Nested [CoreButtonStyle] slot for the close affordance —
  /// `CoreTabsStyle.defaultCloseButtonStyle` merged with the per-instance
  /// override, raw-forwarded to the composed `Button` (its own resolver
  /// scales and fills the rest).
  final CoreButtonStyle closeButtonStyle;

  /// Nested [CoreIconStyle] slot for the close glyph —
  /// `CoreTabsStyle.defaultCloseIconStyle` merged with the per-instance
  /// override, raw-forwarded to the composed `Icon`.
  final CoreIconStyle closeIconStyle;
}

// ═══════════════════════════════════════════════════
// resolveTabs — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTabs] for the given [context] and [variant].
///
/// Walks the 3-stage merge chain and applies the
/// `CoreTabsStyle.defaultsByVariant[variant]` / `CoreTabsStyle.defaultX`
/// fallback so the widget reads only fully-resolved, scaling-applied
/// Flutter-typed values.
ResolvedTabs resolveTabs(
  BuildContext context, {
  required CoreTabVariant variant,
  required CoreTabsSize size,
  CoreTabsStyle? tabsStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final tabsTheme = theme.coreComponentTheme?.tabs;

  // Variant-specific chrome from defaultsByVariant.
  final chrome = CoreTabsStyle.defaultsByVariant[variant]!;
  // Size-specific chrome from defaultsBySize (itemHeight + the label
  // typography role, which now varies by rung).
  final sizeChrome = CoreTabsStyle.defaultsBySize[size]!;

  // ─── Stage 1 — RESOLVE (merge chain + default fallback) ──────────
  // 3-stage merge chain — theme.style → theme.variantStyles[variant]
  // → widget.tabsStyle.
  final merged = resolveStyleChain(const CoreTabsStyle(), [
    tabsTheme?.style,
    tabsTheme?.variantStyles?[variant],
    tabsStyle,
  ]);

  // Chrome — `merged` (user intent) wins, else variant / token default.
  final mergedBg = merged.backgroundColor ?? chrome.backgroundColor;
  final mergedIndicator =
      merged.activeIndicatorColor ?? chrome.activeIndicatorColor;
  final mergedBorder = merged.borderColor ?? chrome.borderColor;
  final mergedActiveContent =
      merged.activeContentColor ?? CoreTabsStyle.defaultActiveContentColor;
  final mergedInactiveContent =
      merged.inactiveContentColor ?? chrome.inactiveContentColor;
  final mergedTabBarPadding = merged.tabBarPadding ?? chrome.tabBarPadding;
  final mergedTabPadding = merged.tabPadding ?? chrome.tabPadding;
  final mergedActiveIndicatorRadius =
      merged.activeIndicatorRadius ??
      CoreTabsStyle.defaultActiveIndicatorRadius;
  final mergedActiveIndicatorThickness =
      merged.activeIndicatorThickness ??
      CoreTabsStyle.defaultActiveIndicatorThickness;
  final mergedBorderWidth =
      merged.borderWidth ?? CoreTabsStyle.defaultBorderWidth;
  final mergedContainerRadius =
      merged.containerRadius ?? CoreTabsStyle.defaultContainerRadius;
  final mergedTabSpacing =
      merged.tabSpacing ?? chrome.tabSpacing ?? CoreTabsStyle.defaultTabSpacing;
  final mergedItemHeight = merged.itemHeight ?? sizeChrome.itemHeight!;
  final sizeRungIsTrack = chrome.sizeRungIsTrack;
  final indicatorTransitionDuration = resolveMotionDuration(
    context,
    merged.indicatorTransitionDuration ??
        CoreTabsStyle.defaultIndicatorTransitionDuration,
  );
  final swipeSensitivity =
      merged.swipeSensitivity ?? CoreTabsStyle.defaultSwipeSensitivity;

  // ─── Stage 2 — EMIT (Flutter: scheme.resolve + toValue, scaling) ──
  //
  // surface:content — a face in the content layer alongside the panes
  // it switches between. Only the `pill` variant paints a fill (`co_tabs`
  // never reads `backgroundColor` in the `underline` branch — see
  // `Tabs.build`), so the material is gated on that variant exactly like
  // `Table` gates it on whether a caller actually painted one: a bar
  // with no box to blur behind pays for no backdrop pass.
  final material = variant == .pill
      ? theme.surfaceFor(.content, depth: SurfaceDepth.of(context))
      : null;
  final surfaceOpacity = material?.opacityIn(theme);
  final backgroundColor = mergedBg == null
      ? null
      : scheme
            .resolve(
              surfaceOpacity == null
                  ? mergedBg
                  : mergedBg.scaleAlpha(surfaceOpacity),
            )
            .toValue();
  final hasFill = backgroundColor != null && backgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill ? resolveSurfaceSheen(theme) : null;
  final activeIndicatorColor = scheme.resolve(mergedIndicator).toValue();
  final disabledIndicatorColor = scheme
      .resolve(chrome.disabledIndicatorColor)
      .toValue();
  // Hue-held transparent counterpart for the underline lerp (see
  // `ResolvedTabs.inactiveIndicatorColor`).
  final inactiveIndicatorColor = activeIndicatorColor.withAlpha(0);
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest). The
  // focus ring's own radius is injected here as a *variant default* (the
  // ring has to follow whichever shape the item currently draws — square
  // for `underline`, the pill's own radius for `pill`) so it lands
  // between the shared default and any per-instance override, matching
  // `Clickable`'s already-composed `FocusOutline` (`align`/`offsetColor`/
  // `borderColor`/`borderWidth` all come from `FocusOutline`'s own
  // defaults — `CoreFocusRing.ringOffset`+`ringWidth` = the "band R+2 /
  // ring R+4" pair the redesign asks for, the transparent gap band
  // included — so only the radius needs stating here).
  final focusRingRadius = variant == .underline
      ? CoreBorderRadius.zero
      : mergedActiveIndicatorRadius;
  final clickableStyle = CoreTabsStyle.defaultClickableStyle
      .merge(
        CoreClickableStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            borderRadius: focusRingRadius,
          ),
        ),
      )
      .merge(merged.clickableStyle);
  // Nested Gap slot for the label↔badge spacer — same partial-default
  // merge, raw-forwarded (Gap self-scales, so no `* scaling` here).
  final closeButtonStyle = CoreTabsStyle.defaultCloseButtonStyle.merge(
    merged.closeButtonStyle,
  );
  final closeIconStyle = CoreTabsStyle.defaultCloseIconStyle.merge(
    merged.closeIconStyle,
  );
  final labelBadgeGapStyle = CoreTabsStyle.defaultLabelBadgeGapStyle.merge(
    merged.labelBadgeGapStyle,
  );
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border, and a surface that skips this keeps a border its siblings
  // have dropped. Called unconditionally (not gated on `hasFill`) —
  // mirrors `Table`, whose stroke suppression reads the active style's
  // stated material independent of whether this particular instance
  // paints a fill.
  final borderColor = mergedBorder == null
      ? null
      : resolveSurfaceStroke(theme, scheme.resolve(mergedBorder).toValue());
  final activeContentColor = scheme.resolve(mergedActiveContent).toValue();
  final inactiveContentColor = scheme.resolve(mergedInactiveContent).toValue();
  final tabBarPadding =
      mergedTabBarPadding.toValue(geometry: theme.geometry) * scaling;
  final tabPadding =
      mergedTabPadding.toValue(geometry: theme.geometry) * scaling;
  final activeIndicatorRadius =
      mergedActiveIndicatorRadius.toValue(geometry: theme.geometry) * scaling;
  final activeIndicatorThickness = theme.geometry.stroke(
    mergedActiveIndicatorThickness,
    scaling: scaling,
  );
  final borderWidth = theme.geometry.stroke(
    mergedBorderWidth,
    scaling: scaling,
  );
  final containerRadius =
      mergedContainerRadius.toValue(geometry: theme.geometry) * scaling;
  final tabSpacing = theme.geometry.space(mergedTabSpacing) * scaling;
  // `MediaQuery.textScaler` on the rung — the widget treats the item
  // height as a floor, so the label grows past it rather than being cut
  // off. The rung is the bar's outside height (`CoreTabsStyle
  // .defaultsBySize`); the variant row says whether it is the track's
  // (`sizeRungIsTrack`), in which case each tab gets the rung less the
  // track's resolved top and bottom inset and the track comes out at
  // exactly the rung.
  final rungHeight = MediaQuery.textScalerOf(
    context,
  ).scale(mergedItemHeight * scaling);
  final itemHeight = CoreTabsStyle.tabHeight(
    rung: rungHeight,
    trackInset: tabBarPadding.vertical,
    sizeRungIsTrack: sizeRungIsTrack,
  );
  // Content typography — single-primitive conversion of the variant's role
  // where its row states one (`underline`: `labelXl`), else the per-size
  // role default (`labelMedium` sm, `labelLarge` md, `labelXl` lg — see
  // `CoreTabsStyle.defaultsBySize`), merged with the per-instance override.
  // The weight follows the selection: the instance's own `fontWeight` wins,
  // else the variant row's active / inactive weight, else the role's. The
  // widget binds the state-resolved content colour on top and only picks
  // between the two finished styles.
  final roleTextStyle = sizeChrome.contentTextStyle!.merge(
    chrome.contentTextStyle,
  );
  final instanceTextStyle = merged.contentTextStyle;
  final activeContentTextStyle = roleTextStyle
      .copyWith(fontWeight: chrome.activeFontWeight)
      .merge(instanceTextStyle)
      .toValue(theme: theme);
  final inactiveContentTextStyle = roleTextStyle
      .copyWith(fontWeight: chrome.inactiveFontWeight)
      .merge(instanceTextStyle)
      .toValue(theme: theme);
  final disabledContentColor = scheme
      .resolve(
        merged.disabledContentColor ??
            CoreTabsStyle.defaultDisabledContentColor,
      )
      .toValue();
  final hoverStateLayerColor = scheme
      .resolve(
        merged.hoverStateLayerColor ??
            CoreTabsStyle.defaultHoverStateLayerColor,
      )
      .toValue();
  final pressedStateLayerColor = scheme
      .resolve(
        merged.pressedStateLayerColor ??
            CoreTabsStyle.defaultPressedStateLayerColor,
      )
      .toValue();

  // The style injects its cast into surfaces that state no shadow of
  // their own — empty under every style that injects none.
  final boxShadow = resolveInjectedCast(theme);

  return ResolvedTabs(
    boxShadow: boxShadow,
    backgroundColor: backgroundColor,
    activeIndicatorColor: activeIndicatorColor,
    disabledIndicatorColor: disabledIndicatorColor,
    inactiveIndicatorColor: inactiveIndicatorColor,
    clickableStyle: clickableStyle,
    activeIndicatorRadius: activeIndicatorRadius,
    activeIndicatorThickness: activeIndicatorThickness,
    borderColor: borderColor,
    borderWidth: borderWidth,
    activeContentColor: activeContentColor,
    inactiveContentColor: inactiveContentColor,
    tabBarPadding: tabBarPadding,
    tabPadding: tabPadding,
    containerRadius: containerRadius,
    tabSpacing: tabSpacing,
    indicatorTransitionDuration: indicatorTransitionDuration,
    swipeSensitivity: swipeSensitivity,
    itemHeight: itemHeight,
    activeContentTextStyle: activeContentTextStyle,
    inactiveContentTextStyle: inactiveContentTextStyle,
    disabledContentColor: disabledContentColor,
    hoverStateLayerColor: hoverStateLayerColor,
    pressedStateLayerColor: pressedStateLayerColor,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    labelBadgeGapStyle: labelBadgeGapStyle,
    closeButtonStyle: closeButtonStyle,
    closeIconStyle: closeIconStyle,
  );
}

// ═══════════════════════════════════════════════════
// ResolvedTabPane
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `TabPane`.
///
/// ```text
/// CoreTabPaneStyle.defaultX / defaultsByVariant
///   → theme.coreComponentTheme.tabPane.style
///   → theme.coreComponentTheme.tabPane.variantStyles[variant]
///   → widget.tabPaneStyle
/// ```
///
/// **Scaling boundary (Epic #1603 C12)** — the dimensional fields
/// (`tabPadding`, `tabSpacing`, `barHeight`) carry `theme.scaling`
/// pre-applied in [resolveTabPane]; `co_tab_pane` reads `resolved.*`
/// without re-multiplying. `borderWidth` / `borderRadius` mirror the
/// resting boxed-tab + content-panel chrome, which the legacy widget
/// rendered unscaled, so they stay unscaled for byte parity.
class ResolvedTabPane {
  /// Creates a [ResolvedTabPane].
  const ResolvedTabPane({
    required this.stripOnly,
    required this.backgroundColor,
    required this.stripBackgroundColor,
    required this.stripBorderColor,
    required this.tabSeparatorColor,
    required this.tabSeparatorWidth,
    required this.activeContentColor,
    required this.inactiveContentColor,
    required this.tabBorderColor,
    required this.borderRadius,
    required this.borderWidth,
    required this.barHeight,
    required this.barPadding,
    required this.tabPadding,
    required this.tabSpacing,
    required this.dragOpacity,
    required this.contentTextStyle,
    required this.clickableStyle,
    required this.panelBackgroundColor,
    required this.panelBorderColor,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.labelBadgeGapStyle,
    required this.indicatorColor,
    required this.indicatorWidth,
    required this.indicatorBorderRadius,
    required this.closeButtonStyle,
    required this.closeIconStyle,
    required this.slotIconStyle,
  });

  /// Whether this resolve is for [CoreTabPaneVariant.editorStrip] —
  /// strip only, no content panel and no card.
  ///
  /// Paint-ready layout flag so the widget stays render-only: it reads
  /// this rather than re-branching on the semantic enum.
  final bool stripOnly;

  /// Effective content panel / focused-tab background colour.
  ///
  /// Shared, deliberately unfolded by the content-role material: the
  /// boxed tab and the content panel below it are drawn as one
  /// continuous filled region (the tab's bottom corners are square so it
  /// fuses onto the panel's top edge — see [borderRadius]), so this stays
  /// the plain resolved token both slots read. [panelBackgroundColor] is
  /// the material-folded counterpart the content panel actually paints —
  /// see its doc for why the two diverge.
  final Color backgroundColor;

  /// Effective FOCUSED tab-label colour, layered onto
  /// [contentTextStyle]'s role at render time.
  final Color activeContentColor;

  /// Effective UNFOCUSED tab-label colour. A colour, not an opacity —
  /// see `CoreTabPaneStyle.defaultInactiveContentColor` for why.
  final Color inactiveContentColor;

  /// Effective inter-tab rule colour, or `null` when none is drawn.
  ///
  /// Painted on each tab's inline-end edge of the per-tab WRAPPER — see
  /// `CoreTabPaneStyle.defaultTabSeparatorColor` for why the wrapper and
  /// not the tab box.
  final Color? tabSeparatorColor;

  /// Effective inter-tab rule thickness (logical px, scaling applied).
  final double tabSeparatorWidth;

  /// Effective tab-strip band colour, painted behind the whole strip
  /// edge to edge (the bar padding moves the tabs, not the band).
  ///
  /// `null` — the default — means NO band: the widget adds no box, so a
  /// pane that never states one renders exactly the tree it rendered
  /// before this field existed. See `CoreTabPaneStyle
  /// .defaultStripBackgroundColor` for what a stated band does to the
  /// panel's top rule.
  final Color? stripBackgroundColor;

  /// Effective colour of the strip's bottom line — `CoreTabPaneStyle
  /// .borderColor` painted at [borderWidth] along the bottom edge of the
  /// strip, inside [barHeight], beneath the chips (so the focused tab's
  /// face covers it).
  ///
  /// `null` means NO line: the pane stated a `transparent` `borderColor` or
  /// a zero [borderWidth]. Both variant rows state `outlineVariant`, so by
  /// default this is non-null and the line is drawn — the boxed card's rule
  /// between its bar and its panel, the editorStrip's bottom edge.
  ///
  /// Deliberately NOT folded through the material's stroke suppression
  /// ([panelBorderColor] goes through `resolveSurfaceStroke`): the Web twin
  /// has no material marker on the strip and always draws this line, so
  /// suppressing it here would leave a line on one platform only.
  final Color? stripBorderColor;

  /// Effective FOCUSED-TAB border colour (`CoreTabPaneStyle
  /// .tabBorderColor`). The panel's own edge is [panelBorderColor],
  /// which carries the material suppression this one must not.
  ///
  /// `null` — the default on both rows — means the focused tab draws no
  /// outline and, on the boxed variant, no face: the indicator marks it.
  final Color? tabBorderColor;

  /// Effective container corner radius.
  final BorderRadius borderRadius;

  /// Effective container / tab border thickness (logical px) — also the
  /// thickness of the editorStrip's bottom line ([stripBorderColor]).
  final double borderWidth;

  /// Effective tab-bar height (logical px, scaling pre-applied).
  final double barHeight;

  /// Inset of the tabs inside the bar (scaling pre-applied) —
  /// `CoreTabPaneStyle.barPadding`. The boxed row states 16 each side so the
  /// tabs clear the card's corners; the editorStrip row states none.
  final EdgeInsetsGeometry barPadding;

  /// Effective per-tab chip padding (scaling pre-applied) — wraps the
  /// whole chip, leading glyph through the close ×.
  ///
  /// Directional when the style states it so (`CoreEdgeInsets.directional`
  /// — the editorStrip's start 12 / end 8), so it follows the ambient text
  /// direction; a symmetric one resolves to plain [EdgeInsets].
  final EdgeInsetsGeometry tabPadding;

  /// Effective inter-tab spacing (logical px, scaling pre-applied).
  final double tabSpacing;

  /// Effective drag-feedback opacity (0..1) applied to the reorder
  /// drag preview.
  final double dragOpacity;

  /// Paint-ready content / label text style (base typography + the
  /// per-instance `contentTextStyle` override merged in).
  final TextStyle contentTextStyle;

  /// Nested style for the composed boxed-tab `Clickable` — raw-forwarded
  /// (the Clickable's own resolver fills the rest).
  final CoreClickableStyle clickableStyle;

  /// Content-panel background fill with the active content-role
  /// material's `surfaceOpacity` folded in. The panel always paints a
  /// fill (`CoreTabPaneStyle.defaultBackgroundColor`), so this is the
  /// one value the boxed-tab chrome restates the marker+fill pair on —
  /// the focused tab chip stays a plain highlight (mirrors the Web
  /// resolver, which marks only the content `<div>` and not the tab
  /// `<span>`).
  final Color panelBackgroundColor;

  /// Content-panel border stroke, suppressed via the shared
  /// `resolveSurfaceStroke` helper when the active material draws its
  /// own edge.
  final Color panelBorderColor;

  /// Backdrop blur sigma for the content panel, `null` when the active
  /// theme states no material or the panel states no fill to blur
  /// behind.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  ///
  /// Rides the same backdrop pass as [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Nested [CoreGapStyle] slot for the in-tab spacer — the step that
  /// separates a boxed tab's label from its `CoreTabItem.badge`,
  /// `leading` and `trailing` alike.
  /// `CoreTabPaneStyle.defaultLabelBadgeGapStyle` merged with the
  /// per-instance override, raw-forwarded to `Gap(gapStyle:)`.
  final CoreGapStyle labelBadgeGapStyle;

  /// Effective colour of the selected tab's indicator bar, or `null` when
  /// none is drawn (`CoreTabPaneStyle.indicatorColor` is `transparent` — the
  /// boxed default). Painted along the INSIDE of the selected tab's top
  /// edge, over the tab face; it takes no layout height.
  final Color? indicatorColor;

  /// Effective indicator thickness (logical px, stroke-floor applied).
  final double indicatorWidth;

  /// Effective corner radius of the indicator bar — flat on the editorStrip,
  /// the two outer corners on the boxed variant.
  final BorderRadius indicatorBorderRadius;

  /// Nested [CoreButtonStyle] slot for a tab's close affordance —
  /// `CoreTabPaneStyle.defaultCloseButtonStyle`, the variant row
  /// (editorStrip: a 20×20 box) and the per-instance override merged,
  /// raw-forwarded to `Button(buttonStyle:)`.
  final CoreButtonStyle closeButtonStyle;

  /// Nested [CoreIconStyle] slot for the close glyph — the same merge,
  /// raw-forwarded to `Icon(iconStyle:)`. A `color` it states pins the
  /// glyph through every button state; with none the glyph follows its
  /// ghost button's foreground.
  final CoreIconStyle closeIconStyle;

  /// Nested [CoreIconStyle] slot for the glyphs in a tab's `leading` /
  /// `trailing` slots — the merge, of which only `size` is read: the widget
  /// hands it down as the ambient `IconTheme` size (token size; the `Icon`
  /// applies the theme scaling itself).
  final CoreIconStyle slotIconStyle;
}

// ═══════════════════════════════════════════════════
// resolveTabPane — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTabPane] for the given [context].
ResolvedTabPane resolveTabPane(
  BuildContext context, {
  CoreTabPaneVariant variant = CoreTabPaneVariant.defaultVariant,
  CoreTabPaneStyle? tabPaneStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final paneTheme = theme.coreComponentTheme?.tabPane;
  final stripOnly = variant == CoreTabPaneVariant.editorStrip;

  // Variant-specific chrome from defaultsByVariant.
  final chrome = CoreTabPaneStyle.defaultsByVariant[variant]!;

  // ─── Stage 1 — RESOLVE (merge chain + default fallback) ──────────
  // 3-stage merge chain — theme.style → theme.variantStyles[variant]
  // → widget.tabPaneStyle. Variant chrome is applied as `merged.X ??
  // chrome.X ?? defaultX` below (Tabs pattern), not as a chain layer.
  final merged = resolveStyleChain(const CoreTabPaneStyle(), [
    paneTheme?.style,
    paneTheme?.variantStyles?[variant],
    tabPaneStyle,
  ]);

  final mergedBg =
      merged.backgroundColor ??
      chrome.backgroundColor ??
      CoreTabPaneStyle.defaultBackgroundColor;
  final mergedBorder =
      merged.borderColor ??
      chrome.borderColor ??
      CoreTabPaneStyle.defaultBorderColor;
  // The focused tab's stroke is its own field. Both default to `outline`,
  // so a caller who overrides neither still sees one continuous outline —
  // but an editor-style strip can keep the panel's rule and drop the tab's.
  final mergedTabBorder =
      merged.tabBorderColor ??
      chrome.tabBorderColor ??
      CoreTabPaneStyle.defaultTabBorderColor;
  // The band behind the strip. Transparent by default, so the panel's top
  // rule keeps showing through exactly as before. Given a colour it covers
  // that rule for the strip's whole width — the editor reading, where the
  // visible line is the band/panel boundary rather than the panel's edge.
  // The inter-tab rule. `transparent` = not drawn, which is the default,
  // so a pane that never asks for one is unchanged. It lands on the
  // per-tab WRAPPER (no radius) because a rounded box cannot take a
  // per-side stroke colour on either Flutter or Figma.
  final mergedSeparator =
      merged.tabSeparatorColor ??
      chrome.tabSeparatorColor ??
      CoreTabPaneStyle.defaultTabSeparatorColor;
  final mergedStripBg =
      merged.stripBackgroundColor ??
      chrome.stripBackgroundColor ??
      CoreTabPaneStyle.defaultStripBackgroundColor;
  // The label's colour is the one thing that varies by focus. The ROLE is
  // one statement (`contentTextStyle`) and only the colour is a pair —
  // the shape the sibling `CoreTabsStyle` already uses.
  final mergedActiveContent =
      merged.activeContentColor ?? CoreTabPaneStyle.defaultActiveContentColor;
  final mergedInactiveContent =
      merged.inactiveContentColor ??
      CoreTabPaneStyle.defaultInactiveContentColor;
  final mergedRadius =
      merged.borderRadius ??
      chrome.borderRadius ??
      CoreTabPaneStyle.defaultBorderRadius;
  final mergedBorderWidth =
      merged.borderWidth ??
      chrome.borderWidth ??
      CoreTabPaneStyle.defaultBorderWidth;
  final mergedBarHeight =
      merged.barHeight ?? chrome.barHeight ?? CoreTabPaneStyle.defaultBarHeight;
  final mergedTabPadding =
      merged.tabPadding ??
      chrome.tabPadding ??
      CoreTabPaneStyle.defaultTabPadding;
  final mergedTabSpacing =
      merged.tabSpacing ??
      chrome.tabSpacing ??
      CoreTabPaneStyle.defaultTabSpacing;
  final dragOpacity = merged.dragOpacity ?? CoreTabPaneStyle.defaultDragOpacity;
  final mergedIndicator =
      merged.indicatorColor ??
      chrome.indicatorColor ??
      CoreTabPaneStyle.defaultIndicatorColor;
  final mergedIndicatorWidth =
      merged.indicatorWidth ??
      chrome.indicatorWidth ??
      CoreTabPaneStyle.defaultIndicatorWidth;
  final mergedSeparatorWidth =
      merged.tabSeparatorWidth ??
      chrome.tabSeparatorWidth ??
      CoreTabPaneStyle.defaultTabSeparatorWidth;

  // ─── Stage 2 — EMIT (Flutter: scheme.resolve + toValue, scaling) ──
  final backgroundColor = scheme.resolve(mergedBg).toValue();
  final borderColor = scheme.resolve(mergedBorder).toValue();
  final tabBorderColor = mergedTabBorder == CoreColor.transparent
      ? null
      : scheme.resolve(mergedTabBorder).toValue();
  // `null` when the band is the `transparent` sentinel — the widget then
  // adds no box at all, so the default widget tree is byte-identical to
  // one without this field. Web skips its emit on the same Core-level
  // comparison and the canvas's `fillData` drops an alpha-0 fill, so all
  // three surfaces decide from the same value with the same rule.
  final activeContentColor = scheme.resolve(mergedActiveContent).toValue();
  final inactiveContentColor = scheme.resolve(mergedInactiveContent).toValue();
  final tabSeparatorColor = mergedSeparator == CoreColor.transparent
      ? null
      : scheme.resolve(mergedSeparator).toValue();
  // `null` = no indicator drawn (the `transparent` sentinel, or a zero
  // width) — the widget then adds no border, so the boxed tree is unchanged.
  final indicatorWidth = theme.geometry.stroke(mergedIndicatorWidth);
  final indicatorColor =
      mergedIndicator == CoreColor.transparent || indicatorWidth <= 0
      ? null
      : scheme.resolve(mergedIndicator).toValue();
  final stripBackgroundColor = mergedStripBg == CoreColor.transparent
      ? null
      : scheme.resolve(mergedStripBg).toValue();
  final borderRadius = mergedRadius.toValue(geometry: theme.geometry);

  // surface:content — the content panel always paints a fill
  // (`mergedBg` above), so it is the one slot in this boxed-tab pair
  // that restates the content-material seat; the focused tab chip stays
  // the plain [backgroundColor]/[tabBorderColor] above (mirrors the Web
  // resolver's separate `content` vs `tabs` chrome builders).
  final material = theme.surfaceFor(.content, depth: SurfaceDepth.of(context));
  final surfaceOpacity = material?.opacityIn(theme);
  final panelBackgroundColor = scheme
      .resolve(
        surfaceOpacity == null ? mergedBg : mergedBg.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Gated on the fill for the reason every other restated panel is: a
  // caller can override [tabPaneStyle] to a fully transparent
  // background, and a material handed to a fill-less panel stacks a
  // backdrop pass over nothing.
  final hasFill = panelBackgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill ? resolveSurfaceSheen(theme) : null;
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border, and a surface that skips this keeps a border its siblings
  // have dropped.
  final panelBorderColor = resolveSurfaceStroke(theme, borderColor);
  // No `scaling:` argument — this mirrors the legacy widget's
  // deliberately-unscaled boxed-tab/content-panel chrome (see the
  // doc comment above), but a strokeFloor preset must still be able
  // to raise a below-floor width (and 0 stays 0 per `stroke()`'s
  // contract), so the geometry seat still applies.
  final borderWidth = theme.geometry.stroke(mergedBorderWidth);
  // The editorStrip's bottom line: `borderColor` at `borderWidth`, drawn
  // inside the bar. Taken from the plain resolved colour, not
  // [panelBorderColor] — no material suppression (see
  // [ResolvedTabPane.stripBorderColor]). `null` = nothing to draw: not the
  // strip variant, a `transparent` colour, or a zero width.
  final stripBorderColor =
      mergedBorder != CoreColor.transparent && borderWidth > 0
      ? borderColor
      : null;
  final barHeight = mergedBarHeight * scaling;
  // The tabs' inset inside the bar: a stated value, not derived from the
  // card's corner radius.
  final barPadding =
      (merged.barPadding ??
              chrome.barPadding ??
              CoreTabPaneStyle.defaultBarPadding)
          .toGeometry(geometry: theme.geometry) *
      scaling;
  final indicatorBorderRadius =
      (merged.indicatorBorderRadius ??
              chrome.indicatorBorderRadius ??
              CoreTabPaneStyle.defaultIndicatorBorderRadius)
          .toValue(geometry: theme.geometry);
  final tabPadding =
      mergedTabPadding.toGeometry(geometry: theme.geometry) * scaling;
  final tabSpacing = theme.geometry.space(mergedTabSpacing) * scaling;
  // Content typography — single-primitive conversion of the bodyMedium
  // role default, the variant row's role (editorStrip: `codeSm`) and the
  // per-instance override, each merged over the one before.
  final contentTextStyle = CoreTabPaneStyle.defaultContentTextStyle
      .merge(chrome.contentTextStyle)
      .merge(merged.contentTextStyle)
      .toValue(theme: theme);
  // Nested Clickable slot — partial default, then the variant row (the
  // editorStrip's inset focus ring), then the override, raw-forwarded (the
  // Clickable's own resolver fills the rest, including the keyboard focus
  // ring that this style used to paint manually).
  final clickableStyle = CoreTabPaneStyle.defaultClickableStyle
      .merge(chrome.clickableStyle)
      .merge(merged.clickableStyle);
  // Nested Gap slot for the label↔badge spacer — raw-forwarded (Gap
  // self-scales).
  final labelBadgeGapStyle = CoreTabPaneStyle.defaultLabelBadgeGapStyle.merge(
    merged.labelBadgeGapStyle,
  );

  // Nested close slots — empty partial default, then the variant row (the
  // editorStrip's 20×20 box and 12 px glyph), then the override;
  // raw-forwarded (Button / Icon resolve and scale them).
  final closeButtonStyle = CoreTabPaneStyle.defaultCloseButtonStyle
      .merge(chrome.closeButtonStyle)
      .merge(merged.closeButtonStyle);
  final closeIconStyle = CoreTabPaneStyle.defaultCloseIconStyle
      .merge(chrome.closeIconStyle)
      .merge(merged.closeIconStyle);
  final slotIconStyle = CoreTabPaneStyle.defaultSlotIconStyle
      .merge(chrome.slotIconStyle)
      .merge(merged.slotIconStyle);

  return ResolvedTabPane(
    stripOnly: stripOnly,
    backgroundColor: backgroundColor,
    stripBackgroundColor: stripBackgroundColor,
    stripBorderColor: stripBorderColor,
    tabSeparatorColor: tabSeparatorColor,
    tabSeparatorWidth: theme.geometry.stroke(mergedSeparatorWidth),
    activeContentColor: activeContentColor,
    inactiveContentColor: inactiveContentColor,
    tabBorderColor: tabBorderColor,
    borderRadius: borderRadius,
    borderWidth: borderWidth,
    barHeight: barHeight,
    barPadding: barPadding,
    tabPadding: tabPadding,
    tabSpacing: tabSpacing,
    dragOpacity: dragOpacity,
    contentTextStyle: contentTextStyle,
    clickableStyle: clickableStyle,
    panelBackgroundColor: panelBackgroundColor,
    panelBorderColor: panelBorderColor,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    labelBadgeGapStyle: labelBadgeGapStyle,
    indicatorColor: indicatorColor,
    indicatorWidth: indicatorWidth,
    indicatorBorderRadius: indicatorBorderRadius,
    closeButtonStyle: closeButtonStyle,
    closeIconStyle: closeIconStyle,
    slotIconStyle: slotIconStyle,
  );
}
