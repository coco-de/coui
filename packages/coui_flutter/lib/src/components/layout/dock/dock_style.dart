import 'package:coui_flutter/coui_flutter.dart';

/// Resolved styling values for [Dock].
///
/// Widget tree (`dock.dart` builds):
///
/// ```text
/// Semantics (navigation)
///   └─ Padding (barMargin)
///    └─ InjectedCast (boxShadow — outside the bar only)
///     └─ SurfaceBlur → InsetShadow (insetBoxShadow — the style's rim)
///      └─ Container (minHeight, backgroundColor, border all round, barRadius,
///        │         horizontalPadding)
///        └─ Stacks (passthrough)   // as tall as its row asks, never under
///             │                     // minHeight
///             ├─ Position.fill → LiquidMorphClip → DecoratedBox
///             │                                     (indicatorColor)
///             │                     // only while the plate is in flight
///             └─ Padding (rowPadding — top and bottom)
///                  └─ Row (center, spacing: itemSpacing)
///                       └─ _DockItem (× n)
///                            └─ Clickable → Semantics → SizedBox (itemWidth)
///                               │  // Clickable only when onPressed != null
///                               └─ Column (center, min)
///                                    ├─ Stacks (none)     // the icon row
///                                    │    ├─ Position (-indicatorPadding)
///                                    │    │    → DecoratedBox (plate)
///                                    │    │    // active item, not in flight
///                                    │    └─ SizedBox (itemWidth) → Center
///                                    │         → IconTheme (iconSize, colour)
///                                    ├─ Gap (itemIconLabelGapStyle)
///                                    │      // showLabel && label != null
///                                    └─ Text (active | inactive label style)
/// ```
///
/// Carries paint-ready values; the widget never resolves a colour,
/// materialises a typography role, or applies the fallback chain inline
/// (render-only.md — widget is select + render).
class ResolvedDock {
  /// Creates a [ResolvedDock].
  const ResolvedDock({
    required this.minHeight,
    required this.iconSize,
    required this.barRadius,
    required this.barMargin,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.horizontalPadding,
    required this.itemIconLabelGapStyle,
    required this.clickableStyle,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.activeColor,
    required this.inactiveColor,
    required this.showLabel,
    required this.activeLabelTextStyle,
    required this.inactiveLabelTextStyle,
    required this.indicatorColor,
    required this.indicatorRadius,
    required this.indicatorPadding,
    required this.indicatorClearance,
    required this.indicatorSpring,
    required this.rowPadding,
    required this.itemSpacing,
    required this.itemWidth,
    required this.boxShadow,
    required this.insetBoxShadow,
  });

  /// The bar's minimum height, border included (already scaled): the bar is
  /// exactly this tall while its item row — and the room kept for the pill
  /// around it ([indicatorClearance]) — fits, and as tall as the row asks
  /// once it does not. A floor handed to the layout, never a height.
  final double minHeight;

  /// The bar's minimum height, as [minHeight].
  @Deprecated(
    'Renamed to minHeight (since 0.174) — the bar is not a fixed height: '
    'this value is its floor, and the bar grows past it when its row needs '
    'the room.',
  )
  double get height => minHeight;

  /// The bar's own corners — `BorderRadius.zero` when the bar is square.
  final BorderRadius barRadius;

  /// Space outside the bar, which is what detaches a floating bar from
  /// the edge it would otherwise sit flush against.
  final EdgeInsets barMargin;

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

  /// Default icon size (already scaled).
  final double iconSize;

  /// Horizontal padding applied to the dock bar (already scaled).
  final double horizontalPadding;

  /// Resolved gap slot between icon and label inside each item.
  /// Forwarded straight to `Gap(gapStyle: …)` — no manual
  /// `CoreGapStyle(size: …)` reconstruction in the widget body
  /// (Epic #1603 옵션 B nested-slot pattern). `Gap` self-scales, so
  /// the resolver passes the raw design-system slot forward.
  final CoreGapStyle itemIconLabelGapStyle;

  /// Nested [CoreClickableStyle] slot for the `Clickable` composed
  /// around each tappable (`onPressed != null`) dock item —
  /// `CoreDockStyle.defaultClickableStyle` merged with the
  /// per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)` (the Clickable's own resolver fills
  /// the remaining defaults).
  final CoreClickableStyle clickableStyle;

  /// Resolved background colour.
  final Color backgroundColor;

  /// Colour of the line around the bar.
  final Color borderColor;

  /// Width of the line around the bar, bent by the surface style's stroke
  /// floor.
  final double borderWidth;

  /// Icon tint of the active item. The label's colour is baked into
  /// [activeLabelTextStyle].
  final Color activeColor;

  /// Icon tint of the inactive items. The labels' colour is baked into
  /// [inactiveLabelTextStyle].
  final Color inactiveColor;

  /// Whether labels render for this size. `xs`/`sm` hide labels to match
  /// legacy behaviour; `md`/`lg`/`xl` show them.
  final bool showLabel;

  /// Paint-ready label text style for the **active** item — `labelXs`
  /// role + `semiBold` weight + on-surface + per-instance `labelTextStyle`
  /// overlay. The widget reads this directly (no `theme.typography` /
  /// `copyWith` reassembly).
  final TextStyle activeLabelTextStyle;

  /// Paint-ready label text style for **inactive** items — `labelXs` role
  /// + `medium` weight + on-surface-variant + per-instance
  /// `labelTextStyle` overlay.
  final TextStyle inactiveLabelTextStyle;

  /// Fill of the plate behind the active item's icon, resolved. Fully
  /// transparent when the style turned the plate off.
  final Color indicatorColor;

  /// Corners of that plate.
  final BorderRadius indicatorRadius;

  /// How far the plate reaches past the icon row, scaled.
  final EdgeInsets indicatorPadding;

  /// The room above and below the item row inside the bar's line, scaled —
  /// `CoreDockStyle.rowInsetFor` of the bar's padding side and the plate's
  /// padding, bent through the spacing axis. Only `top` and `bottom` are
  /// set; the sides are [horizontalPadding].
  final EdgeInsets rowPadding;

  /// Space between neighbouring apps, scaled and bent through the spacing
  /// axis.
  final double itemSpacing;

  /// Fixed width of each app's cell, scaled, or `null` for a cell as wide
  /// as its icon.
  final double? itemWidth;

  /// The bar's shadow, paint-ready and strengthened by the theme's
  /// brightness. Painted outside the bar only (`InjectedCast`): a surface
  /// style can make the bar translucent, and a decoration shadow would then
  /// show through it — the Web `box-shadow` never does.
  final List<BoxShadow> boxShadow;

  /// The rim the active surface style lays inside a bar that casts a
  /// shadow — empty under every style that draws none.
  final List<BoxShadow> insetBoxShadow;

  /// The room the active plate alone asks for above and below the item
  /// row, scaled — `CoreDockStyle.indicatorClearanceFor` of the plate's
  /// padding, bent through the same spacing axis as the plate's own reach.
  /// [rowPadding] is what the bar keeps; this is its lower bound.
  final double indicatorClearance;

  /// The tempo the pill travels between items at.
  ///
  /// Not paint-ready and not meant to be: the flight is the morph
  /// engine's, and the engine takes the spring as it is — the same object
  /// the Web twin hands its runtime.
  final CoreMorphSpring indicatorSpring;
}

/// Resolves [ResolvedDock] for [Dock].
///
/// Single entry point — applies the merge chain (`CoreDockTheme.style`
/// → `dockStyle`) followed by design-system default fallback. Chrome
/// flows entirely through [CoreDockStyle]; every colour routes through a
/// `CoreDockStyle.defaultX` named default (never `theme.colorScheme.X`
/// directly) before `scheme.resolve(...).toValue()`. Per-size
/// dimensional defaults live on [CoreDockStyle.defaultsBySize] so Flutter
/// and Web share one source of truth. `size` is a widget-only semantic
/// identifier — the theme cannot override it.
ResolvedDock resolveDock(
  BuildContext context, {
  CoreDockSize? size,
  CoreDockStyle? dockStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.dock;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreDockStyle(), [
    coreTheme?.style,
    dockStyle,
  ]);

  // ─── Semantic identifier + size table ─────────────────
  // `size` comes straight from the widget — the theme cannot override it
  // (render-only.md (c): theme-override of a semantic identifier is a
  // violation). Web resolves this identically, so the two platforms stay
  // 1:1.
  final effectiveSize = size ?? .md;
  final sizeStyle = CoreDockStyle.defaultsBySize[effectiveSize]!;
  final showLabel = CoreDockStyle.labelVisibleFor(effectiveSize);

  // ─── Dimensional fallback ─────────────────────────────
  // The floor of the bar's height, not its height: the layout grows the bar
  // past it when the row needs more room (`CoreDockStyle.height`).
  final minHeight = (merged.height ?? sizeStyle.height!) * scaling;
  final padding = merged.padding ?? sizeStyle.padding!;
  final horizontalPadding = theme.geometry.space(padding.left) * scaling;
  final itemSpacing =
      theme.geometry.space(merged.itemSpacing ?? sizeStyle.itemSpacing!) *
      scaling;
  final itemWidthValue = merged.itemWidth ?? sizeStyle.itemWidth;
  final itemWidth = itemWidthValue == null ? null : itemWidthValue * scaling;
  // Nested CoreGapStyle slot — forwarded raw to `Gap(gapStyle: …)`,
  // which self-applies `theme.scaling` (no scaling baked in here).
  final itemIconLabelGapStyle = CoreDockStyle.defaultItemIconLabelGapStyle
      .merge(merged.itemIconLabelGapStyle);
  final mergedIconStyle = CoreDockStyle.defaultIconStyle
      .merge(sizeStyle.iconStyle)
      .merge(merged.iconStyle);
  final iconSize = mergedIconStyle.size! * scaling;
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreDockStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // ─── Colour resolution (single-source — no `cs.<token>`) ───
  // A theme-wide surface treatment reaches the bar the same way it
  // reaches a card — otherwise the bar stays opaque while every panel
  // around it turns translucent.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = theme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(theme);
  final backgroundToken =
      merged.backgroundColor ?? CoreDockStyle.defaultBackgroundColor;
  final backgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundToken
            : backgroundToken.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border. This one sat outside the guard because its call was split
  // across lines, not because it was exempt.
  final borderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(merged.borderColor ?? CoreDockStyle.defaultBorderColor)
        .toValue(),
    role: CoreSurfaceRole.functional,
  );
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreDockStyle.defaultBorderWidth,
  );
  final activeColor = scheme
      .resolve(merged.activeColor ?? CoreDockStyle.defaultActiveColor)
      .toValue();
  final inactiveColor = scheme
      .resolve(merged.inactiveColor ?? CoreDockStyle.defaultInactiveColor)
      .toValue();

  // ─── Label text styles (role + weight + per-state colour) ──
  // EMIT Stage 2 (Flutter) — `default.merge(override).toValue(theme:)`
  // materialises the `labelXs` role, the per-state weight and the per-state
  // colour the label style states. The per-instance `labelTextStyle`
  // merges on top so a caller override (e.g. fontSize) wins. Single
  // primitive — no hand-rolled `theme.typography` / `copyWith` assembly.
  final activeLabelTextStyle = CoreDockStyle.defaultActiveLabelStyle
      .merge(merged.activeLabelStyle)
      .merge(merged.labelTextStyle)
      .toValue(theme: theme);
  final inactiveLabelTextStyle = CoreDockStyle.defaultInactiveLabelStyle
      .merge(merged.inactiveLabelStyle)
      .merge(merged.labelTextStyle)
      .toValue(theme: theme);

  // Bar geometry — the size's corners, and no margin: the bar sits where
  // its parent puts it.
  final barRadiusValue = (merged.barRadius ?? sizeStyle.barRadius!).toValue(
    geometry: theme.geometry,
  );
  final barMarginValue =
      (merged.barMargin ?? CoreDockStyle.defaultBarMargin).toValue(
        geometry: theme.geometry,
      ) *
      scaling;

  // The bar's shadow — through the geometry seat, so a surface style bends
  // it and a dark theme strengthens it — and the rim a style lays inside a
  // surface that casts one.
  final boxShadowStack = merged.boxShadow ?? CoreDockStyle.defaultBoxShadow;
  final shadowBase = scheme
      .resolve(merged.shadowBaseColor ?? CoreDockStyle.defaultShadowBaseColor)
      .toValue();
  final boxShadow = boxShadowStack.toValue(
    base: shadowBase,
    geometry: theme.geometry,
  );
  final insetBoxShadow = resolveSurfaceRim(context, stack: boxShadowStack);

  // The active plate. Through the geometry axis for its corners, like the
  // bar's own, so a style that squares corners squares this too.
  final indicatorColor = scheme
      .resolve(merged.indicatorColor ?? CoreDockStyle.defaultIndicatorColor)
      .toValue();
  final indicatorRadius = (merged.indicatorRadius ?? sizeStyle.indicatorRadius!)
      .toValue(geometry: theme.geometry);
  final indicatorPaddingValue =
      merged.indicatorPadding ?? sizeStyle.indicatorPadding!;
  final indicatorPadding =
      indicatorPaddingValue.toValue(geometry: theme.geometry) * scaling;
  // The room the plate alone asks for, from the one rule Core states and
  // through the spacing axis, like the plate's reach it makes room for.
  final indicatorClearance =
      theme.geometry.space(
        CoreDockStyle.indicatorClearanceFor(indicatorPaddingValue),
      ) *
      scaling;
  // The room above and below the row: the bar's padding, or the plate's
  // reach where that is larger — one rule in Core, bent through spacing.
  final rowPadding = EdgeInsets.only(
    top:
        theme.geometry.space(
          CoreDockStyle.rowInsetFor(padding.top, indicatorPaddingValue),
        ) *
        scaling,
    bottom:
        theme.geometry.space(
          CoreDockStyle.rowInsetFor(padding.bottom, indicatorPaddingValue),
        ) *
        scaling,
  );
  final indicatorSpring =
      merged.indicatorSpring ?? CoreDockStyle.defaultIndicatorSpring;

  return ResolvedDock(
    minHeight: minHeight,
    iconSize: iconSize,
    barRadius: barRadiusValue,
    barMargin: barMarginValue,
    surfaceBlur: material?.blurRadius,
    surfaceSaturation: material?.saturation,
    surfaceBackdropBrightness: material?.backdropBrightnessIn(theme),
    surfaceSheen: resolveSurfaceSheen(theme, role: CoreSurfaceRole.functional),
    horizontalPadding: horizontalPadding,
    itemIconLabelGapStyle: itemIconLabelGapStyle,
    clickableStyle: clickableStyle,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    showLabel: showLabel,
    activeLabelTextStyle: activeLabelTextStyle,
    inactiveLabelTextStyle: inactiveLabelTextStyle,
    indicatorColor: indicatorColor,
    indicatorRadius: indicatorRadius,
    indicatorPadding: indicatorPadding,
    indicatorClearance: indicatorClearance,
    indicatorSpring: indicatorSpring,
    rowPadding: rowPadding,
    itemSpacing: itemSpacing,
    itemWidth: itemWidth,
    boxShadow: boxShadow,
    insetBoxShadow: insetBoxShadow,
  );
}
