import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedNavigationBar
// ═══════════════════════════════════════════════════

/// Resolver output for [NavigationBar].
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has had the nested-merge chain applied plus the
/// `CoreNavigationBarStyle.defaultX` static const fallback and Flutter
/// type conversion:
///
/// ```text
/// CoreNavigationBarStyle.defaultX           // design system default
///   → CoreNavigationBarStyle.defaultsByVariant[variant]
///   → theme.coreComponentTheme.navigationBar.style
///   → theme.coreComponentTheme.navigationBar.variantStyles[variant]
///   → widget.navigationBarStyle
/// ```
class ResolvedNavigationBar {
  /// Creates a [ResolvedNavigationBar].
  const ResolvedNavigationBar({
    required this.backgroundColor,
    required this.padding,
    required this.barRadius,
    required this.barMargin,
    required this.barBorder,
    required this.barHairline,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.itemSpacing,
    required this.itemPadding,
    required this.itemRadius,
    required this.itemMinHeight,
    required this.itemMaxWidth,
    required this.iconOnlyItemMinHeight,
    required this.iconOnlyItemMinWidth,
    required this.touchTargetSize,
    required this.labelSpacing,
    required this.iconSize,
    required this.iconBoxSize,
    required this.iconColor,
    required this.disabledIconColor,
    required this.badgeIndicatorStyle,
    required this.selectedBackgroundColor,
    required this.selectedHoverBackgroundColor,
    required this.selectedFocusBackgroundColor,
    required this.selectedPressedBackgroundColor,
    required this.selectedForegroundColor,
    required this.hoverBackgroundColor,
    required this.focusBackgroundColor,
    required this.pressedBackgroundColor,
    required this.idleBackgroundColor,
    required this.foregroundColor,
    required this.disabledForegroundColor,
    required this.selectedLabelTextStyle,
    required this.selectedRowLabelTextStyle,
    required this.labelTextStyle,
    required this.disabledLabelTextStyle,
    required this.disabledSelectedLabelTextStyle,
    required this.disabledSelectedBackgroundColor,
    required this.sectionLabelTextStyle,
    required this.sectionLabelPadding,
    required this.dividerStyle,
    required this.duration,
    required this.clickableStyle,
    required this.selectionMarkStyle,
    required this.selectionMarkGapStyle,
    required this.disabledSelectionMarkStyle,
    required this.indicator,
    required this.selectedIconTint,
    required this.hoverForegroundColor,
    required this.hoverLabelTextStyle,
    required this.iconAnchorPadding,
    required this.notificationDotStyle,
    required this.notificationDotIndicatorStyle,
    required this.compactScale,
    required this.compactDuration,
    required this.hasCompactForm,
    this.refraction,
    this.isGlass = false,
    this.floatingGlass = false,
    this.selectedIconColor,
    this.selectionRefraction,
  });

  /// Effective navigation container background colour.
  final Color backgroundColor;

  /// Impeller refraction request after local material resolution.
  final CoreSurfaceRefraction? refraction;

  /// Temporary optical lens, enabled only during pointer interaction.
  final CoreSurfaceRefraction? selectionRefraction;

  /// Whether the bar's material is glass, in any mode — a glass destination
  /// tints its selected icon with the selected label's colour.
  final bool isGlass;

  /// Whether the bar is drawn as the floating glass capsule — the material
  /// is glass and the mode has a capsule
  /// (`CoreNavigationBarStyle.glassStyleFor`: the bar and the rail). The
  /// capsule moves one lens over its destinations and answers the mode's
  /// glass defaults (`CoreNavigationBarMode.defaultLabelModeFor` /
  /// `defaultIndicatorFor`).
  final bool floatingGlass;

  /// Glass selection tint; an explicitly authored icon colour takes precedence.
  final Color? selectedIconColor;

  /// Effective outer padding of the navigation container (scaling
  /// applied).
  final EdgeInsets padding;

  /// The bar's own corners — `BorderRadius.zero` when the bar is square.
  final BorderRadius barRadius;

  /// Space outside the bar, which is what detaches a floating bar from
  /// the edge it would otherwise sit flush against.
  final EdgeInsets barMargin;

  /// Hairline on the content-facing edge of a vertical mode — the logical
  /// `end` of a rail or sidebar, laid out as a border (it adds to the
  /// width). Empty for [CoreNavigationBarMode.bar], whose hairline is
  /// [barHairline]. The other three sides carry [BorderSide.none].
  final BorderDirectional barBorder;

  /// Hairline the horizontal bar draws over its own top edge — painted as
  /// a foreground decoration, so it lies on the top padding instead of
  /// adding to it and the bar is `padding + item` tall with or without
  /// the line. Empty for the vertical modes and for a detached bar.
  final BorderDirectional barHairline;

  /// Backdrop blur sigma from a theme-wide material treatment, or `null`
  /// when the surface is an opaque fill.
  final double? surfaceBlur;

  /// Chroma lift riding the same material treatment as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  ///
  /// Rides the same backdrop pass as [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Effective gap between adjacent items (logical px, scaling
  /// applied).
  final double itemSpacing;

  /// Effective inner padding of a navigation item (scaling applied).
  final EdgeInsets itemPadding;

  /// Effective navigation item corner radius.
  final BorderRadius itemRadius;

  /// Effective minimum height of a navigation item (logical px, scaling
  /// applied).
  final double itemMinHeight;

  /// Effective maximum width of a destination that shares the bar's main
  /// axis (logical px, scaling applied). `double.infinity` — no cap.
  final double itemMaxWidth;

  /// Minimum painted height of a stacked destination that hides its label,
  /// scaled.
  final double iconOnlyItemMinHeight;

  /// Minimum painted width of a stacked destination that hides its label,
  /// scaled. Yields to a narrower share of the bar.
  final double iconOnlyItemMinWidth;

  /// Smallest region that accepts a pointer around a stacked destination,
  /// scaled — read by `TouchTarget`, which grows hit testing only.
  final double touchTargetSize;

  /// Effective native flex `spacing` between an item's icon and its
  /// label — passed directly to `Row.spacing` / `Column.spacing`
  /// (logical px, scaling applied). Not wrapped in `Gap`.
  final double labelSpacing;

  /// Navigation item icon size as a token size (logical px, before the
  /// theme scaling) — handed to the destination's `Icon` through the
  /// ambient `IconTheme`, which scales its own box. Layout arithmetic reads
  /// [iconBoxSize], the extent the glyph lands at.
  final double iconSize;

  /// Edge of the box the destination's icon lays out to (logical px, scaling
  /// applied) — [iconSize] times the theme scaling, which is the number the
  /// `Icon` resolves to. The width estimates count this.
  final double iconBoxSize;

  /// Effective navigation item icon colour — state-independent
  /// (`onSurfaceVariant` by default) across rest / hover / selected,
  /// decoupled from the per-state label colours below.
  final Color iconColor;

  /// Icon colour of a disabled destination — `disabledContent` by default,
  /// the same tone as [disabledForegroundColor].
  final Color disabledIconColor;

  /// Nested [CoreIndicatorStyle] for the composed `Indicator` that lays a
  /// destination's badge over its icon in the bar and the rail —
  /// `CoreNavigationBarStyle.defaultBadgeIndicatorStyle` merged with the
  /// per-instance override, raw-forwarded (the indicator resolves and
  /// scales its own offset).
  final CoreIndicatorStyle badgeIndicatorStyle;

  /// Effective selected-item background colour.
  final Color selectedBackgroundColor;

  /// [selectedBackgroundColor] under the hover state layer — the layer is
  /// laid over the selection, not swapped for it.
  final Color selectedHoverBackgroundColor;

  /// [selectedBackgroundColor] under the focus state layer.
  final Color selectedFocusBackgroundColor;

  /// [selectedBackgroundColor] under the pressed state layer.
  final Color selectedPressedBackgroundColor;

  /// Effective selected-item foreground colour.
  final Color selectedForegroundColor;

  /// Effective hover background colour.
  final Color hoverBackgroundColor;

  /// Item fill while the destination holds keyboard focus.
  final Color focusBackgroundColor;

  /// Item fill while the destination is held down.
  final Color pressedBackgroundColor;

  /// Idle / disabled item fill — [hoverBackgroundColor] at alpha 0
  /// (hue held). `AnimatedContainer` lerps the item fill between
  /// states; a plain transparent BLACK would drag the midpoints
  /// through dark translucent grey and both the deselected and the
  /// newly-selected item flash dark on every selection change.
  final Color idleBackgroundColor;

  /// Effective unselected-item foreground colour.
  final Color foregroundColor;

  /// Effective disabled-item foreground colour.
  final Color disabledForegroundColor;

  /// Paint-ready label text style for a selected destination — the
  /// `labelSmall` typography role materialised against the active scale
  /// with the selected foreground colour baked in (sb8 — the widget reads
  /// this directly instead of re-materialising `theme.typography.labelSmall`).
  final TextStyle selectedLabelTextStyle;

  /// Paint-ready label style for a selected row.
  final TextStyle selectedRowLabelTextStyle;

  /// Paint-ready label text style for an enabled, unselected destination.
  final TextStyle labelTextStyle;

  /// Paint-ready label text style for a disabled destination.
  final TextStyle disabledLabelTextStyle;

  /// Paint-ready label text style for a destination that is selected AND
  /// disabled — the disabled tone at the selected weight.
  final TextStyle disabledSelectedLabelTextStyle;

  /// Face of a selected, disabled destination that paints its selection on
  /// the whole tile, stacked or a row. A face with no alpha
  /// is the hue-held [idleBackgroundColor], so the state lerp does not pass
  /// through transparent black.
  final Color disabledSelectedBackgroundColor;

  /// Paint-ready text style for a non-selectable section header —
  /// `labelSmall` (12px) typography role overlaid with the semibold weight
  /// and `onSurfaceVariant` colour from the merged `sectionLabelTextStyle`
  /// slot.
  final TextStyle sectionLabelTextStyle;

  /// Effective inset around a non-selectable section header (scaling
  /// applied).
  final EdgeInsets sectionLabelPadding;

  /// Effective divider style — colour + line thickness handed straight
  /// to the nested [Divider], which finalises the platform conversion
  /// (mirrors the way `Menu` passes its divider chrome to a composed
  /// `Divider`).
  final CoreDividerStyle dividerStyle;

  /// Effective colour-transition duration for hover / selection.
  final Duration duration;

  /// Nested [CoreClickableStyle] slot for the composed destination
  /// `Clickable` — `CoreNavigationBarStyle.defaultClickableStyle` (an
  /// empty partial — the destination takes the Clickable's standard
  /// press / focus / cursor chrome) merged with the per-instance
  /// override, raw-forwarded to `Clickable(clickableStyle: …)`. The
  /// Clickable's own resolver fills the rest, so the destination stops
  /// hand-rolling `MouseRegion` + `GestureDetector` +
  /// `SelectionContainer` in the widget body (render-only).
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreBadgeStyle] slot for the selection-mark dot —
  /// `CoreNavigationBarStyle.defaultSelectionMarkStyle`, the material
  /// preset's row (the glass bar's primary) and the per-instance override,
  /// raw-forwarded to `Badge(form: .dot)`, which resolves and scales it.
  final CoreBadgeStyle selectionMarkStyle;

  /// Nested [CoreGapStyle] slot for the space between the selection-mark
  /// dot and the content under it — raw-forwarded to `Gap`.
  final CoreGapStyle selectionMarkGapStyle;

  /// Nested [CoreBadgeStyle] slot for the selection-mark dot of a selected,
  /// disabled destination — [selectionMarkStyle] with the `disabledContent`
  /// overlay (`CoreNavigationBarStyle.defaultDisabledSelectionMarkStyle`) and
  /// the per-instance override, raw-forwarded to `Badge(form: .dot)`.
  final CoreBadgeStyle disabledSelectionMarkStyle;

  /// How the selected destination is marked — the indicator these values
  /// were resolved for.
  final CoreNavigationSelectionIndicator indicator;

  /// Icon colour of the selected destination (outside the glass bar, which
  /// keeps [selectedIconColor]).
  final Color selectedIconTint;

  /// Foreground of a hovered, unselected destination, or `null` to keep the
  /// resting foreground (the state layer carries hover then).
  final Color? hoverForegroundColor;

  /// Paint-ready label text style of a hovered, unselected destination —
  /// [labelTextStyle] unless the indicator darkens the foreground on hover.
  final TextStyle hoverLabelTextStyle;

  /// Inset of the box around a stacked destination's icon (scaling applied).
  final EdgeInsets iconAnchorPadding;

  /// Nested [CoreBadgeStyle] for the notification dot — raw-forwarded to
  /// `Badge(form: .dot)`.
  final CoreBadgeStyle notificationDotStyle;

  /// Nested [CoreIndicatorStyle] for the `Indicator` that lays the
  /// notification dot over the icon — raw-forwarded.
  final CoreIndicatorStyle notificationDotIndicatorStyle;

  /// Size the bar is drawn at while compact, as a factor of its resting
  /// size — `1` for a bar with no compact form. A factor, so the theme's
  /// size scaling does not apply.
  final double compactScale;

  /// Time the bar takes to reach or leave its compact size — zero under
  /// reduced motion.
  final Duration compactDuration;

  /// Whether the bar has a compact form
  /// (`CoreNavigationBarStyle.hasCompactForm`): one that has is drawn at
  /// [compactScale] and drops its captions while compact; one that has not
  /// stays as it is.
  final bool hasCompactForm;
}

// ═══════════════════════════════════════════════════
// resolveNavigationBar — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedNavigationBar] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreNavigationBarStyle.defaultX` / `defaultsByVariant` static const
/// fallback so the widget reads only fully-resolved Flutter-typed
/// values.
ResolvedNavigationBar resolveNavigationBar(
  BuildContext context, {
  required CoreNavigationBarMode mode,
  required CoreNavigationBarVariant variant,
  CoreNavigationSelectionIndicator? indicator,
  CoreNavigationBarStyle? navigationBarStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final navTheme = theme.coreComponentTheme?.navigationBar;

  // Variant chrome — defaultsByVariant single source of truth.
  final chrome = CoreNavigationBarStyle.defaultsByVariant[variant]!;
  // Mode density — each cell sits between the merged field of the same
  // name and the flat default; a null cell falls through to the flat one.
  final modeCell = CoreNavigationBarStyle.defaultsByMode[mode]!;

  // 3-stage merge chain — theme.style → theme.variantStyles → widget.
  final overrides = resolveStyleChain(const CoreNavigationBarStyle(), [
    navTheme?.style,
    navTheme?.variantStyles?[variant],
    navigationBarStyle,
  ]);

  final materialTheme = resolveSurfaceTheme(context, overrides.surfaceStyle);

  // ─── Stage 1 RESOLVE (local) ──────────────────────────
  // A theme-wide surface treatment — the translucency and blur a material
  // style preset states — reaches the bar the same way it reaches a card.
  // Without this the bar stayed opaque while every panel around it turned
  // translucent, which reads as the preset being broken rather than
  // unapplied. The bar is the one chrome a user sees on every screen.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = materialTheme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(theme);
  final surfaceBlur = material?.blurRadius;
  final surfaceSaturation = material?.saturation;
  final surfaceBackdropBrightness = material?.backdropBrightnessIn(theme);
  final surfaceSheen = resolveSurfaceSheen(
    materialTheme,
    role: CoreSurfaceRole.functional,
  );
  // Under a glass material the bar and the rail detach into a capsule. The
  // preset is the mode's own (`glassStyleFor`), laid UNDER the caller's
  // chain so every field it states reaches the chains below through
  // `merged` — a preset field cannot be stated in Core and then missed here,
  // and the Web twin merges it the same way.
  final glassStyle = material?.type == SurfaceType.glass
      ? CoreNavigationBarStyle.glassStyleFor(mode)
      : null;
  final floatingGlass = glassStyle != null;
  final merged = (glassStyle ?? const CoreNavigationBarStyle()).merge(
    overrides,
  );
  // Indicator chrome — sits between the material preset and the mode cell.
  // The capsule's lens is its selected face, so it marks with colour alone
  // unless the caller states otherwise.
  final effectiveIndicator =
      indicator ?? mode.defaultIndicatorFor(floatingGlass: floatingGlass);
  final indicatorCell =
      CoreNavigationBarStyle.defaultsByIndicator[effectiveIndicator]!;
  // The mode cell sits between the merged field and the variant face: the
  // bottom bar states `surface`, the rail and the sidebar fall through to
  // the chrome tier.
  final backgroundColor =
      merged.backgroundColor ??
      modeCell.backgroundColor ??
      chrome.backgroundColor;
  final padding =
      merged.padding ??
      modeCell.padding ??
      CoreNavigationBarStyle.defaultPadding;
  final barRadius = merged.barRadius ?? CoreNavigationBarStyle.defaultBarRadius;
  final barMargin = merged.barMargin ?? CoreNavigationBarStyle.defaultBarMargin;
  final barBorderColor =
      merged.barBorderColor ?? CoreNavigationBarStyle.defaultBarBorderColor;
  final barBorderWidth =
      (merged.barBorderWidth ?? CoreNavigationBarStyle.defaultBarBorderWidth) *
      scaling;
  final itemPadding =
      merged.itemPadding ??
      modeCell.itemPadding ??
      CoreNavigationBarStyle.defaultItemPadding;
  final itemRadius =
      merged.itemRadius ?? CoreNavigationBarStyle.defaultItemRadius;
  final itemMinHeight =
      (merged.itemMinHeight ??
          modeCell.itemMinHeight ??
          CoreNavigationBarStyle.defaultItemMinHeight) *
      scaling;
  // `double.infinity` (no cap) stays infinite through the scaling.
  final itemMaxWidth =
      (merged.itemMaxWidth ??
          modeCell.itemMaxWidth ??
          CoreNavigationBarStyle.defaultItemMaxWidth) *
      scaling;
  // An icon-only stacked destination paints its own, shorter floor. A
  // stated `itemMinHeight` (the caller's, or the glass preset's 48 — both
  // already in `merged`) still reaches it — only the destinations nobody
  // sized take the icon-only one.
  final iconOnlyItemMinHeight =
      (merged.iconOnlyItemMinHeight ??
          merged.itemMinHeight ??
          CoreNavigationBarStyle.defaultIconOnlyItemMinHeight) *
      scaling;
  final iconOnlyItemMinWidth =
      (merged.iconOnlyItemMinWidth ??
          CoreNavigationBarStyle.defaultIconOnlyItemMinWidth) *
      scaling;
  final touchTargetSize =
      (merged.touchTargetSize ??
          CoreNavigationBarStyle.defaultTouchTargetSize) *
      scaling;
  // Per-mode default — the horizontal bar packs destinations edge-to-edge
  // (0 gap, each stretches to an equal share); the vertical modes keep an
  // authored gap between hugged items.
  final itemSpacing =
      theme.geometry.space(
        merged.itemSpacing ??
            CoreNavigationBarStyle.defaultsByMode[mode]!.spacing,
      ) *
      scaling;
  final labelSpacing =
      theme.geometry.space(
        merged.labelSpacing ??
            modeCell.labelSpacing ??
            CoreNavigationBarStyle.defaultLabelSpacing,
      ) *
      scaling;
  // Icon chrome is its own nested slot, merged whole rather than
  // pulling `.size` alone off the default — the icon's colour is
  // state-independent across rest / hover / selected, so it does not read
  // the per-state label colour. The mode cell sits between the flat
  // default and the override (the sidebar's 18px glyph).
  final iconStyle = CoreNavigationBarStyle.defaultIconStyle
      .merge(modeCell.iconStyle)
      .merge(merged.iconStyle);
  // `Icon` is a self-scaling child: it reads the ambient `IconTheme` size
  // as a token size and multiplies it by the theme scaling itself, so the
  // size forwarded to it is the token size as stated. The scaled box is
  // kept apart for the layout estimates that need the number the glyph
  // lands at.
  final iconSize = iconStyle.size!;
  final iconBoxSize = iconSize * scaling;
  // Disabled is the one state the icon follows: the disabled partial is
  // layered over the resolved icon so it keeps its size and takes the
  // disabled tone.
  final disabledIconStyle = iconStyle
      .merge(CoreNavigationBarStyle.defaultDisabledIconStyle)
      .merge(merged.disabledIconStyle);
  // The selected icon takes the indicator's colour: the tile's onSurface,
  // or colour-alone's primary. Layered over the resolved icon so it keeps
  // its size.
  // A caller's `iconStyle` still reaches the selected icon: it sits above
  // the selected defaults, and only `selectedIconStyle` outranks it.
  final selectedIconStyle = CoreNavigationBarStyle.defaultIconStyle
      .merge(modeCell.iconStyle)
      .merge(CoreNavigationBarStyle.defaultSelectedIconStyle)
      .merge(indicatorCell.selectedIconStyle)
      .merge(merged.iconStyle)
      .merge(merged.selectedIconStyle);
  // Selected and disabled: the selection stays, dimmed — the tile takes
  // the disabled area tone.
  final disabledSelectedBackgroundColor =
      merged.disabledSelectedBackgroundColor ??
      indicatorCell.disabledSelectedBackgroundColor ??
      CoreNavigationBarStyle.defaultDisabledSelectedBackgroundColor;
  final iconAnchorPadding =
      merged.iconAnchorPadding ??
      CoreNavigationBarStyle.defaultIconAnchorPadding;
  // The transparent sentinel keeps the resting foreground on hover.
  final hoverForegroundColor =
      merged.hoverForegroundColor ??
      indicatorCell.hoverForegroundColor ??
      CoreNavigationBarStyle.defaultHoverForegroundColor;
  final notificationDotStyle = CoreNavigationBarStyle
      .defaultNotificationDotStyle
      .merge(merged.notificationDotStyle);
  final notificationDotIndicatorStyle = CoreNavigationBarStyle
      .defaultNotificationDotIndicatorStyle
      .merge(merged.notificationDotIndicatorStyle);
  // Nested Indicator slot for the bar / rail badge overlay — partial
  // default merged with the override, raw-forwarded.
  final badgeIndicatorStyle = CoreNavigationBarStyle.defaultBadgeIndicatorStyle
      .merge(merged.badgeIndicatorStyle);
  final dividerThickness =
      merged.dividerThickness ?? CoreNavigationBarStyle.defaultDividerThickness;
  final selectedBackgroundColor =
      merged.selectedBackgroundColor ??
      indicatorCell.selectedBackgroundColor ??
      modeCell.selectedBackgroundColor ??
      CoreNavigationBarStyle.defaultSelectedBackgroundColor;
  final hoverBackgroundColor =
      merged.hoverBackgroundColor ??
      CoreNavigationBarStyle.defaultHoverBackgroundColor;
  // Per-state label text style lives inside the matching nested
  // `CoreTextStyle` slot. The flat default carries the `labelSmall` role
  // plus the per-state colour (and the selected weight); the mode cell's
  // role is layered over it, so the sidebar's `labelLarge` reaches all
  // three states while each keeps its own colour and weight. The role +
  // colour are baked into a paint-ready `TextStyle` (Stage 2). The icon's
  // `IconThemeData` colour does not read off this — it comes from the
  // state-independent [iconStyle] slot instead.
  final selectedLabelCore = CoreNavigationBarStyle.defaultSelectedLabelTextStyle
      .merge(modeCell.labelTextStyle)
      .merge(indicatorCell.selectedLabelTextStyle)
      .merge(merged.selectedLabelTextStyle);
  final selectedRowLabelCore = CoreNavigationBarStyle
      .defaultSelectedLabelTextStyle
      .merge(modeCell.labelTextStyle)
      .merge(indicatorCell.selectedLabelTextStyle)
      .merge(indicatorCell.selectedRowLabelTextStyle)
      .merge(merged.selectedLabelTextStyle);
  final labelCore = CoreNavigationBarStyle.defaultLabelTextStyle
      .merge(modeCell.labelTextStyle)
      .merge(merged.labelTextStyle);
  final disabledLabelCore = CoreNavigationBarStyle.defaultDisabledLabelTextStyle
      .merge(modeCell.labelTextStyle)
      .merge(merged.disabledLabelTextStyle);
  // Selected and disabled: the disabled tone at the selected weight. The
  // instance's disabled label reaches it too, then its own override.
  final disabledSelectedLabelCore = CoreNavigationBarStyle
      .defaultDisabledSelectedLabelTextStyle
      .merge(modeCell.labelTextStyle)
      .merge(merged.disabledLabelTextStyle)
      .merge(merged.disabledSelectedLabelTextStyle);
  final selectedLabelColor = selectedLabelCore.color!;
  final labelColor = labelCore.color!;
  final disabledLabelColor = disabledLabelCore.color!;
  final dividerColor =
      merged.dividerColor ?? CoreNavigationBarStyle.defaultDividerColor;
  // Selection is transition motion even when a spring's settling tail is
  // longer than the duration policy's display-timing cutoff.
  final duration = resolveReducedMotion(context)
      ? Duration.zero
      : resolveMotionDuration(
          context,
          merged.duration ??
              (floatingGlass
                  ? Duration(
                      microseconds:
                          (const CoreMorphSpring().settleSeconds() *
                                  Duration.microsecondsPerSecond)
                              .round(),
                    )
                  : CoreNavigationBarStyle.defaultDuration),
        );
  final compactScale =
      merged.compactScale ?? CoreNavigationBarStyle.defaultCompactScale;
  final compactDuration = resolveMotionDuration(
    context,
    merged.compactDuration ?? CoreNavigationBarStyle.defaultCompactDuration,
  );
  final hasCompactForm = CoreNavigationBarStyle.hasCompactForm(compactScale);
  // Nested Clickable slot — the Core default (which states the tile's
  // corner as the focus-ring radius) under the merged one, which carries
  // the material preset's row (a glass capsule's pill item states a pill
  // ring) and the per-instance override over it; raw-forwarded (the
  // Clickable's own resolver fills the rest).
  final clickableStyle = CoreNavigationBarStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  // Nested selection-mark slots — the Core default, the indicator's, then
  // the merged one (the glass presets state their own dot colour, the
  // override sits over it), raw-forwarded: `Badge` and `Gap` resolve and
  // scale their own chrome.
  final selectionMarkStyle = CoreNavigationBarStyle.defaultSelectionMarkStyle
      .merge(indicatorCell.selectionMarkStyle)
      .merge(merged.selectionMarkStyle);
  final selectionMarkGapStyle = CoreNavigationBarStyle
      .defaultSelectionMarkGapStyle
      .merge(merged.selectionMarkGapStyle);
  // Selected and disabled, the dot stays, dimmed — the same dot under the
  // disabled overlay.
  final disabledSelectionMarkStyle = selectionMarkStyle
      .merge(CoreNavigationBarStyle.defaultDisabledSelectionMarkStyle)
      .merge(merged.disabledSelectionMarkStyle);
  // Section header label — fixed `labelSmall` (12px) role merged with the
  // design-system semibold weight + section colour overlay
  // (`defaultSectionLabelTextStyle`) then the per-instance
  // `sectionLabelTextStyle` slot. The slot default carries the section
  // colour inline so the merged style's `color` is always populated.
  final sectionLabelCore = CoreNavigationBarStyle.sectionLabelRole
      .merge(CoreNavigationBarStyle.defaultSectionLabelTextStyle)
      .merge(merged.sectionLabelTextStyle);
  final sectionLabelPadding =
      merged.sectionLabelPadding ??
      CoreNavigationBarStyle.defaultSectionLabelPadding;

  // ─── Stage 2 EMIT (local) — colour = .resolve.toValue,
  //     typography = .toValue(theme:) ──────────────────────
  final backgroundColorValue = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundColor
            : backgroundColor.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Bar geometry — scaled like every other dimensional value.
  final barRadiusValue = barRadius.toValue(geometry: theme.geometry);
  final barMarginValue = barMargin.toValue(geometry: theme.geometry) * scaling;
  // A docked bottom bar consumes the device's bottom safe area (the home
  // indicator) itself: the inset joins the bottom padding, so the face
  // paints under the indicator and the destinations sit above it.
  //
  // `paddingOf`, not `viewPaddingOf`. `padding` is the inset still
  // unobscured — it drops to zero while the keyboard covers the indicator
  // and a bar lifted above the keyboard has nothing under it — and it is
  // the value an ancestor `SafeArea` removes for its subtree, so a bar an
  // app already wrapped in one reads zero here and never takes the inset
  // twice. `viewPadding` survives both and would double it.
  //
  // Device geometry, not a design value: added after scaling. A detached
  // bar takes none — the glass bar sits in its own `SafeArea` (see the
  // widget), and a bar floated by `barMargin` leaves the space below it to
  // the app.
  final docksBottom =
      mode == CoreNavigationBarMode.bar &&
      material?.type != SurfaceType.glass &&
      barMarginValue == EdgeInsets.zero;
  final bottomInset = docksBottom
      ? MediaQuery.maybePaddingOf(context)?.bottom ?? 0.0
      : 0.0;
  final scaledPadding = (padding.toValue(geometry: theme.geometry)) * scaling;
  final paddingValue = bottomInset == 0
      ? scaledPadding
      : scaledPadding.copyWith(bottom: scaledPadding.bottom + bottomInset);
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge (e.g. glass) suppresses
  // this hairline so the bar doesn't draw a second boundary on top of it.
  final barBorderColorValue = resolveSurfaceStroke(
    materialTheme,
    scheme.resolve(barBorderColor).toValue(),
    role: CoreSurfaceRole.functional,
  );
  // The hairline lands on the edge that faces the content the bar
  // navigates — physical top for a docked horizontal bar, logical end
  // for the vertical modes (BorderDirectional so it flips under RTL).
  // Drawn only while the bar is flush against that edge (`barMargin`
  // zero, matching `Dock`'s own docked/floating split): once the bar
  // detaches, the hairline would draw a line across the middle of
  // nothing — the edge it separated is no longer adjacent to it.
  final barBorderSide = BorderSide(
    color: barBorderColorValue,
    width: barBorderWidth,
  );
  //
  // The horizontal bar's line lies over the bar's top padding (a
  // foreground decoration) rather than being laid out as a border: the
  // bar is `padding + item` tall whether or not the line draws, so a
  // style that thins or drops the line does not move what sits above
  // the bar. The vertical modes keep a laid-out trailing border.
  final docked = barMarginValue == EdgeInsets.zero;
  final barBorderValue = docked && mode != .bar
      ? BorderDirectional(end: barBorderSide)
      : const BorderDirectional();
  final barHairlineValue = docked && mode == .bar
      ? BorderDirectional(top: barBorderSide)
      : const BorderDirectional();
  final itemPaddingValue =
      (itemPadding.toValue(geometry: theme.geometry)) * scaling;
  final itemRadiusValue = itemRadius.toValue(geometry: theme.geometry);
  final selectedBackgroundColorValue = scheme
      .resolve(selectedBackgroundColor)
      .toValue();
  final selectedForegroundColorValue = scheme
      .resolve(selectedLabelColor)
      .toValue();
  final hoverSwapValue = scheme.resolve(hoverBackgroundColor).toValue();

  // The state layer. A destination lays one ink over the bar at three
  // weights rather than swapping to another token — one mechanism for the
  // whole ramp, which is what the state-layer record asks for and what
  // this component was the exception to.
  //
  // `hoverBackgroundColor` is transparent by default and stays a real
  // escape hatch: set it and the swap wins outright. The two never stack,
  // because two mechanisms saying the same state is how the drift started.
  final stateLayer =
      merged.stateLayer ??
      indicatorCell.stateLayer ??
      CoreNavigationBarStyle.defaultStateLayer;
  final stateLayerInk = scheme
      .resolve(
        merged.stateLayerColor ?? CoreNavigationBarStyle.defaultStateLayerColor,
      )
      .toValue();
  Color washed(double weight) => Color.alphaBlend(
    stateLayerInk.withValues(alpha: weight),
    backgroundColorValue,
  );
  final swapped = hoverSwapValue.a > 0;
  final hoverBackgroundColorValue = swapped
      ? hoverSwapValue
      : washed(stateLayer.hover);
  final focusBackgroundColorValue = swapped
      ? hoverSwapValue
      : washed(stateLayer.focus);
  final pressedBackgroundColorValue = swapped
      ? hoverSwapValue
      : washed(stateLayer.pressed);
  // The layer over a selected destination: the same ink and weights laid on
  // the selected face composited over the bar, so a selected destination
  // that is hovered, focused or pressed keeps its face and still answers.
  // A transparent face (the `color` indicator) reads as the bar itself.
  final selectedOverBar = Color.alphaBlend(
    selectedBackgroundColorValue,
    backgroundColorValue,
  );
  Color washedSelected(double weight) => Color.alphaBlend(
    stateLayerInk.withValues(alpha: weight),
    selectedOverBar,
  );
  final selectedHoverBackgroundColorValue = swapped
      ? selectedBackgroundColorValue
      : washedSelected(stateLayer.hover);
  final selectedFocusBackgroundColorValue = swapped
      ? selectedBackgroundColorValue
      : washedSelected(stateLayer.focus);
  final selectedPressedBackgroundColorValue = swapped
      ? selectedBackgroundColorValue
      : washedSelected(stateLayer.pressed);
  // Hue-held transparent counterpart for the state lerp (see
  // `ResolvedNavigationBar.idleBackgroundColor`).
  final idleBackgroundColorValue = hoverBackgroundColorValue.withAlpha(0);
  final foregroundColorValue = scheme.resolve(labelColor).toValue();
  final disabledForegroundColorValue = scheme
      .resolve(disabledLabelColor)
      .toValue();
  // Icon colour — state-independent, from [iconStyle] rather than any
  // per-state label colour; disabled reads its own partial.
  final iconColorValue = scheme.resolve(iconStyle.color!).toValue();
  final disabledIconColorValue = scheme
      .resolve(disabledIconStyle.color!)
      .toValue();
  final sectionLabelPaddingValue =
      sectionLabelPadding.toValue(geometry: theme.geometry) * scaling;
  // Per-state label typography (`labelSmall` role + state colour) — the
  // single `.toValue(theme:)` primitive materialises the role against the
  // active scale and resolves the slot's own colour through the scheme, so
  // the widget reads a paint-ready `TextStyle` instead of re-materialising
  // `theme.typography.labelSmall` itself.
  final selectedLabelTextStyleValue = selectedLabelCore.toValue(theme: theme);
  final selectedRowLabelTextStyleValue = selectedRowLabelCore.toValue(
    theme: theme,
  );
  final labelTextStyleValue = labelCore.toValue(theme: theme);
  final disabledLabelTextStyleValue = disabledLabelCore.toValue(theme: theme);
  final disabledSelectedLabelTextStyleValue = disabledSelectedLabelCore.toValue(
    theme: theme,
  );
  final sectionLabelTextStyleValue = sectionLabelCore.toValue(theme: theme);
  final hoverForegroundColorValue =
      hoverForegroundColor == CoreColor.transparent
      ? null
      : scheme.resolve(hoverForegroundColor).toValue();
  final hoverLabelTextStyleValue = hoverForegroundColorValue == null
      ? labelTextStyleValue
      : labelTextStyleValue.copyWith(color: hoverForegroundColorValue);
  final selectedIconTintValue = scheme
      .resolve(selectedIconStyle.color!)
      .toValue();
  final disabledSelectedFaceValue = scheme
      .resolve(disabledSelectedBackgroundColor)
      .toValue();
  final disabledSelectedBackgroundColorValue = disabledSelectedFaceValue.a == 0
      ? idleBackgroundColorValue
      : disabledSelectedFaceValue;
  final iconAnchorPaddingValue =
      iconAnchorPadding.toValue(geometry: theme.geometry) * scaling;
  // Divider chrome handed to the nested `Separator` (Epic #1659):
  // raw-forward the colour token + the raw thickness so the separator's
  // own resolver resolves the theme-aware colour and applies
  // `theme.scaling` exactly once — no resolve→re-wrap round-trip, and no
  // double scaling (the previous `dividerThickness * scaling` was scaled
  // again inside `Separator`).
  final dividerStyle = CoreDividerStyle(
    color: dividerColor,
    thickness: dividerThickness,
  );

  return ResolvedNavigationBar(
    backgroundColor: backgroundColorValue,
    refraction: floatingGlass && materialTheme.surfaceRefraction != null
        ? CoreNavigationBarStyle.glassRestingRefraction
        : materialTheme.surfaceRefraction,
    selectionRefraction:
        floatingGlass &&
            materialTheme.surfaceRefraction != null &&
            duration != Duration.zero
        ? CoreNavigationBarStyle.glassSelectionRefraction
        : null,
    isGlass: material?.type == SurfaceType.glass,
    floatingGlass: floatingGlass,
    // An icon colour the caller authored outranks the glass tint. Read off
    // the caller's chain, not `merged`: a preset is not an author.
    selectedIconColor: overrides.iconStyle?.color == null
        ? selectedForegroundColorValue
        : iconColorValue,
    padding: paddingValue,
    barRadius: barRadiusValue,
    barMargin: barMarginValue,
    barBorder: barBorderValue,
    barHairline: barHairlineValue,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    itemSpacing: itemSpacing,
    itemPadding: itemPaddingValue,
    itemRadius: itemRadiusValue,
    itemMinHeight: itemMinHeight,
    itemMaxWidth: itemMaxWidth,
    iconOnlyItemMinHeight: iconOnlyItemMinHeight,
    iconOnlyItemMinWidth: iconOnlyItemMinWidth,
    touchTargetSize: touchTargetSize,
    labelSpacing: labelSpacing,
    iconSize: iconSize,
    iconBoxSize: iconBoxSize,
    iconColor: iconColorValue,
    disabledIconColor: disabledIconColorValue,
    badgeIndicatorStyle: badgeIndicatorStyle,
    selectedBackgroundColor: selectedBackgroundColorValue,
    selectedHoverBackgroundColor: selectedHoverBackgroundColorValue,
    selectedFocusBackgroundColor: selectedFocusBackgroundColorValue,
    selectedPressedBackgroundColor: selectedPressedBackgroundColorValue,
    selectedForegroundColor: selectedForegroundColorValue,
    hoverBackgroundColor: hoverBackgroundColorValue,
    focusBackgroundColor: focusBackgroundColorValue,
    pressedBackgroundColor: pressedBackgroundColorValue,
    idleBackgroundColor: idleBackgroundColorValue,
    foregroundColor: foregroundColorValue,
    disabledForegroundColor: disabledForegroundColorValue,
    selectedLabelTextStyle: selectedLabelTextStyleValue,
    selectedRowLabelTextStyle: selectedRowLabelTextStyleValue,
    labelTextStyle: labelTextStyleValue,
    disabledLabelTextStyle: disabledLabelTextStyleValue,
    disabledSelectedLabelTextStyle: disabledSelectedLabelTextStyleValue,
    disabledSelectedBackgroundColor: disabledSelectedBackgroundColorValue,
    sectionLabelTextStyle: sectionLabelTextStyleValue,
    sectionLabelPadding: sectionLabelPaddingValue,
    dividerStyle: dividerStyle,
    duration: duration,
    clickableStyle: clickableStyle,
    selectionMarkStyle: selectionMarkStyle,
    selectionMarkGapStyle: selectionMarkGapStyle,
    disabledSelectionMarkStyle: disabledSelectionMarkStyle,
    indicator: effectiveIndicator,
    selectedIconTint: selectedIconTintValue,
    hoverForegroundColor: hoverForegroundColorValue,
    hoverLabelTextStyle: hoverLabelTextStyleValue,
    iconAnchorPadding: iconAnchorPaddingValue,
    notificationDotStyle: notificationDotStyle,
    notificationDotIndicatorStyle: notificationDotIndicatorStyle,
    compactScale: compactScale,
    compactDuration: compactDuration,
    hasCompactForm: hasCompactForm,
  );
}
