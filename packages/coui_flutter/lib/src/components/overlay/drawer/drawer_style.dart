import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedDrawer
// ═══════════════════════════════════════════════════

/// Resolver output for `Drawer`.
///
/// Single struct that the widget reads — every panel-chrome /
/// dimensional / barrier / animation override has had the nested
/// merge chain applied plus `CoreDrawerStyle.defaultX` static const
/// fallback and Flutter type conversion:
///
/// ```text
/// CoreDrawerStyle.defaultX            // design system default
///   → theme.coreComponentTheme.drawer.style
///   → widget.drawerStyle
/// ```
///
/// Side-flush corner suppression is resolved here — [panelBorderRadius]
/// is a paint-ready Flutter [BorderRadius] (scaling pre-applied) with
/// the two edge-flush corners already zeroed per the [CoreDrawerSide]
/// passed to [resolveDrawer]. The widget paints it as-is (C9/C11 —
/// no raw `double` radius, no widget-side `* scaling`).
class ResolvedDrawer {
  /// Creates a [ResolvedDrawer].
  const ResolvedDrawer({
    required this.panelBackgroundColor,
    required this.panelBorderColor,
    required this.panelBorderRadius,
    required this.panelBorderWidth,
    required this.panelWidth,
    required this.panelHeight,
    required this.panelPadding,
    required this.headerPadding,
    required this.headerSpacing,
    required this.footerPadding,
    required this.dividerStyle,
    required this.closeButtonStyle,
    required this.panelBoxShadow,
    required this.panelInsetBoxShadow,
    required this.barrierColor,
    required this.backdropScale,
    required this.backdropCornerRadius,
    required this.openAnimationDuration,
    required this.closeAnimationDuration,
    required this.titleStyle,
    required this.descriptionStyle,
    required this.titleDescriptionGapStyle,
    required this.dragHandleColor,
    required this.dragHandleWidth,
    required this.dragHandleThickness,
    required this.dragHandleInset,
    required this.dragHandleBorderRadius,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    this.castOutsideBox = false,
  });

  /// Resolved panel background fill, with `surfaceOpacity` already
  /// folded in — a blur behind an opaque fill is painted and then
  /// covered, so the material only arrives as a pair.
  final Color panelBackgroundColor;

  /// Backdrop blur sigma for the panel, `null` when the active theme
  /// states no material or the panel states no fill to blur behind.
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

  /// Resolved panel border stroke colour.
  final Color panelBorderColor;

  /// Paint-ready panel corner radius (scaling pre-applied). The two
  /// viewport-facing corners carry the resolved radius; the two
  /// edge-flush corners are zeroed per the [CoreDrawerSide] passed to
  /// [resolveDrawer]. The widget paints it straight onto
  /// `BoxDecoration.borderRadius`.
  final BorderRadius panelBorderRadius;

  /// Resolved panel border stroke width (logical px, **not**
  /// scaled).
  final double panelBorderWidth;

  /// Resolved panel width for `left` / `right` sides (logical px,
  /// **not** scaled).
  final double panelWidth;

  /// Resolved panel height for `top` / `bottom` sides (logical px).
  /// Null = content-sized — the panel wraps its content on the slide
  /// axis, capped at the viewport extent.
  final double? panelHeight;

  /// Resolved panel inner content padding (logical px, **not**
  /// scaled).
  final EdgeInsets panelPadding;

  /// Resolved header padding (logical px, **not** scaled).
  final EdgeInsets headerPadding;

  /// Resolved space between the title block and the close button
  /// (paint-ready, scaling pre-applied).
  final double headerSpacing;

  /// Resolved footer-row padding (paint-ready, scaling pre-applied).
  final EdgeInsets footerPadding;

  /// Nested header divider style with the panel-border colour token baked
  /// in — forwarded straight to `Divider`, which self-resolves it.
  final CoreDividerStyle dividerStyle;

  /// Nested header close-button style — `defaultCloseButtonStyle`
  /// (tap-target padding / hit-area radius / 16-px close glyph / hover
  /// transition / focus-ring width) merged with the per-instance
  /// `closeButtonStyle` slot, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`. The button resolves
  /// its own chrome and self-applies `theme.scaling` (the `plain`
  /// variant owns the resting-opacity / hover-fade / foreground).
  final CoreButtonStyle closeButtonStyle;

  /// Paint-ready panel elevation shadow layers (resolved against the
  /// scheme's shadow colour). Consumed by the panel's
  /// `BoxDecoration.boxShadow`, or by `InjectedCast` where [castOutsideBox].
  final List<BoxShadow> panelBoxShadow;

  /// Whether [panelBoxShadow] is painted outside the box (`InjectedCast`)
  /// rather than by the panel's `BoxDecoration`.
  ///
  /// True where [panelBackgroundColor] is not opaque. A decoration's shadow
  /// is a filled shape behind the box, so it shows through a translucent
  /// fill — on Flutter only, because CSS paints an outer shadow outside the
  /// border box. An opaque fill hides it, and the panel keeps the plain tree.
  final bool castOutsideBox;

  /// The inset rim the active surface style adds over the panel.
  final List<BoxShadow> panelInsetBoxShadow;

  /// Resolved barrier (scrim) overlay colour.
  final Color barrierColor;

  /// Resolved backdrop scale-down factor (dimensionless ratio; only
  /// consumed when the widget's `transformBackdrop` flag is on).
  final double backdropScale;

  /// Resolved backdrop clip corner radius (paint-ready [BorderRadius],
  /// scaling pre-applied) — the host lerps it with the open progress,
  /// per-corner (`BorderRadius.lerp`), so an asymmetric
  /// `CoreDrawerStyle.backdropCornerRadius` override survives to paint
  /// instead of collapsing to a single representative corner.
  final BorderRadius backdropCornerRadius;

  /// Resolved open-direction animation duration.
  final Duration openAnimationDuration;

  /// Resolved close-direction animation duration.
  final Duration closeAnimationDuration;

  /// Paint-ready header title text style — the `titleMedium` role
  /// overlaid with the `onSurface` tone default and the per-instance
  /// `titleStyle` slot. The widget forwards it straight to the title
  /// `Text` (no widget-side `theme.typography.titleMedium.copyWith`).
  final TextStyle titleStyle;

  /// Paint-ready header description text style — the `bodySmall` role in
  /// `onSurfaceVariant`, with the per-instance `descriptionStyle` slot over
  /// it.
  final TextStyle descriptionStyle;

  /// Nested spacer between the title and the description — forwarded raw
  /// to `Gap`, which applies the density and `scaling` itself.
  final CoreGapStyle titleDescriptionGapStyle;

  /// Resolved grab-handle pill colour.
  final Color dragHandleColor;

  /// Grab-handle pill length along its edge (logical px, scaling applied).
  final double dragHandleWidth;

  /// Grab-handle pill thickness across its edge (logical px, scaling
  /// applied).
  final double dragHandleThickness;

  /// Space around the pill (logical px, density and scaling applied).
  final double dragHandleInset;

  /// Grab-handle pill corner (scaling applied).
  final BorderRadius dragHandleBorderRadius;
}

// ═══════════════════════════════════════════════════
// resolveDrawer — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedDrawer] for the given [context] and [side].
///
/// Walks the nested-merge chain and applies the
/// `CoreDrawerStyle.defaultX` static const fallback so the widget
/// reads only fully-resolved Flutter-typed values. [side] drives the
/// paint-ready [ResolvedDrawer.panelBorderRadius] — the two
/// edge-flush corners are zeroed and `theme.scaling` is pre-applied
/// here so the widget paints the radius as-is.
ResolvedDrawer resolveDrawer(
  BuildContext context, {
  required CoreDrawerSide side,
  CoreDrawerStyle? drawerStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final drawerTheme = theme.coreComponentTheme?.drawer;

  // 2 단 merge chain — theme.style → widget.drawerStyle.
  final merged = resolveStyleChain(const CoreDrawerStyle(), [
    drawerTheme?.style,
    drawerStyle,
  ]);

  // ─── Stage 1/2 — RESOLVE + EMIT (all synthesis in local vars) ───
  // 변환 — merged (사용자 의도) 가 null 인 필드만 static const default 사용.
  final bgCore =
      merged.panelBackgroundColor ??
      CoreDrawerStyle.defaultPanelBackgroundColor;
  final borderCore =
      merged.panelBorderColor ?? CoreDrawerStyle.defaultPanelBorderColor;
  // Barrier (scrim) — the `barrierOpacity` multiplier is folded in via
  // `scaleAlpha` before resolution so the resolved `Color` carries the
  // right alpha (mirrors the dialog backdrop; the token itself is pure
  // black).
  final barrierOpacity =
      merged.barrierOpacity ?? CoreDrawerStyle.defaultBarrierOpacity;
  final barrierCore =
      (merged.barrierColor ?? CoreDrawerStyle.defaultBarrierColor).scaleAlpha(
        barrierOpacity,
      );
  // The material is a pair: translucency without a blur is a lighter
  // panel, and a blur behind an opaque fill is painted and then covered.
  // Both halves come off the theme here.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = theme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(theme);
  final panelBackgroundColor = scheme
      .resolve(
        surfaceOpacity == null ? bgCore : bgCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Gated on the fill for the reason a nested submenu taught this kit:
  // handing a material to a panel that states no fill stacks a backdrop
  // pass inside the one already running and draws a squared band around
  // a box that is not there. A drawer normally fills, so this gate is
  // usually open — it is here because "usually" is not a guarantee a
  // caller has to keep.
  final hasFill = panelBackgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill
      ? resolveSurfaceSheen(theme, role: CoreSurfaceRole.functional)
      : null;
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border, and a surface that skips this keeps a border its siblings
  // have dropped.
  final panelBorderColor = resolveSurfaceStroke(
    theme,
    scheme.resolve(borderCore).toValue(),
    role: CoreSurfaceRole.functional,
  );
  final barrierColor = scheme.resolve(barrierCore).toValue();
  final backdropScale =
      merged.backdropScale ?? CoreDrawerStyle.defaultBackdropScale;
  // Full 4-corner BorderRadius (not `.topLeft` only) — preserves an
  // asymmetric override; `BorderRadius.lerp` in the backdrop host
  // interpolates each corner independently with the open progress.
  final backdropCornerRadius =
      (merged.backdropCornerRadius ??
              CoreDrawerStyle.defaultBackdropCornerRadius)
          .toValue(geometry: theme.geometry) *
      scaling;

  // A left / right drawer is a square column of the page; a top / bottom
  // sheet rounds the corners that face into the viewport.
  final isSidePanel = side == .left || side == .right;
  final radiusCore = theme.geometry.borderRadius(
    merged.panelBorderRadius ??
        (isSidePanel
            ? CoreDrawerStyle.defaultSidePanelBorderRadius
            : CoreDrawerStyle.defaultPanelBorderRadius),
  );
  // Paint-ready radius (C9/C11): uniform corner radius scaled by
  // `theme.scaling`, with the two edge-flush corners zeroed per `side`
  // so only the viewport-facing pair rounds. The widget paints this
  // straight onto `BoxDecoration.borderRadius` — no `* scaling`,
  // no per-side `BorderRadius.only` reconstruction widget-side.
  final scaledRadius = radiusCore.topLeft * scaling; // scaled-shared
  final panelBorderRadius = switch (side) {
    .left => BorderRadius.only(
      topRight: .circular(scaledRadius),
      bottomRight: .circular(scaledRadius),
    ),
    .right => BorderRadius.only(
      topLeft: .circular(scaledRadius),
      bottomLeft: .circular(scaledRadius),
    ),
    .top => BorderRadius.only(
      bottomLeft: .circular(scaledRadius),
      bottomRight: .circular(scaledRadius),
    ),
    .bottom => BorderRadius.only(
      topLeft: .circular(scaledRadius),
      topRight: .circular(scaledRadius),
    ),
  };
  final panelBorderWidth = theme.geometry.stroke(
    merged.panelBorderWidth ??
        (isSidePanel
            ? CoreDrawerStyle.defaultPanelBorderWidth
            : CoreDrawerStyle.defaultSheetPanelBorderWidth),
    scaling: scaling,
  );
  final panelWidth =
      (merged.panelWidth ?? CoreDrawerStyle.defaultPanelWidth) * scaling;
  final panelHeight = merged.panelHeight != null
      ? merged.panelHeight! * scaling
      : null;
  final panelPadding =
      ((merged.panelPadding ?? CoreDrawerStyle.defaultPanelPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  final headerPadding =
      ((merged.headerPadding ?? CoreDrawerStyle.defaultHeaderPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;

  final headerSpacing =
      theme.geometry.space(
        merged.headerSpacing ?? CoreDrawerStyle.defaultHeaderSpacing,
      ) *
      scaling;
  final footerPadding =
      ((merged.footerPadding ?? CoreDrawerStyle.defaultFooterPadding).toValue(
        geometry: theme.geometry,
      )) *
      scaling;

  // Close-button chrome — chained `defaultCloseButtonStyle` (the `sm` row's
  // 32 square, no padding, radius 8 + 16-px close glyph + 150 ms hover + 2-px
  // focus ring) with the per-instance override on top. Raw-forwarded to
  // `Button(variant: .plain, buttonStyle: …)` — the button resolves
  // its own padding / icon / hover-fade / focus-ring and self-applies
  // `theme.scaling`, so the resolver does NOT scale here (Anti-Pattern
  // A; mirrors the toast dismiss button). The `plain` variant owns the
  // resting-opacity / hover-fade / `onSurface` foreground.
  final closeButtonStyle = CoreDrawerStyle.defaultCloseButtonStyle.merge(
    merged.closeButtonStyle,
  );
  // Header divider — raw-forwarded nested slot, empty by default so
  // `Divider` applies its own shared default (`outlineVariant` →
  // `outline` fallback, #4815 디자이너 결정 #1). Previously forwarded
  // the panel-border token (`borderCore`) here, which conflated two
  // different surfaces (the panel's own edge vs. the header's inner
  // separator) under one value — they happened to agree only because
  // both were `outline`.
  final dividerStyle =
      merged.dividerStyle ?? CoreDrawerStyle.defaultDividerStyle;

  // Paint-ready box shadow — the shadow base colour flows through the
  // single Core source (`defaultShadowBaseColor` = `shadow` token) and
  // is resolved against the active scheme so the widget paints it as-is
  // (dark-mode tracking) — in the panel's decoration, or outside the box
  // where the fill is translucent.
  final shadowBase = scheme
      .resolve(merged.shadowBaseColor ?? CoreDrawerStyle.defaultShadowBaseColor)
      .toValue();
  final panelStack =
      merged.panelBoxShadow ?? CoreDrawerStyle.defaultPanelBoxShadow;
  final panelBoxShadow = panelStack.toValue(
    base: shadowBase,
    geometry: theme.geometry,
  );
  // Where the cast is painted: behind a fill that is not opaque, a
  // decoration's shadow shows through the panel (see [castOutsideBox]).
  final castOutsideBox = panelBackgroundColor.a < 1;
  // The Web panel already carries the rim — its stack is a scale step
  // routed through `var(--shadow-lg)`, which the active style rewrites.
  final panelInsetBoxShadow = resolveSurfaceRim(context, stack: panelStack);

  final openAnimationDuration = resolveMotionDuration(
    context,
    merged.openAnimationDuration ??
        CoreDrawerStyle.defaultOpenAnimationDuration,
  );
  final closeAnimationDuration = resolveMotionDuration(
    context,
    merged.closeAnimationDuration ??
        CoreDrawerStyle.defaultCloseAnimationDuration,
  );
  // Header title typography (paint-ready TextStyle) — single-primitive
  // `default.merge(override).toValue(theme:)`. The `defaultTitleStyle`
  // nested slot (`titleMedium` role + `onSurface` tone) carries the role
  // + colour token, the per-instance `titleStyle` slot overlays on top,
  // and `toValue(theme:)` materialises the size-aware role and resolves
  // the foreground colour through the active scheme so dark mode tracks
  // (sb-text-style-repackage).
  final titleStyle = CoreDrawerStyle.defaultTitleStyle
      .merge(merged.titleStyle)
      .toValue(theme: theme);
  final descriptionStyle = CoreDrawerStyle.defaultDescriptionStyle
      .merge(merged.descriptionStyle)
      .toValue(theme: theme);
  // Nested CoreGapStyle slot — forwarded raw to `Gap`, which scales itself.
  final titleDescriptionGapStyle = CoreDrawerStyle
      .defaultTitleDescriptionGapStyle
      .merge(merged.titleDescriptionGapStyle);

  // ── Grab handle ──
  // The pill's length and thickness are sizes; the space around it is
  // spacing, so a theme density moves it before the size factor.
  final dragHandleColor = scheme
      .resolve(merged.dragHandleColor ?? CoreDrawerStyle.defaultDragHandleColor)
      .toValue();
  final dragHandleWidth =
      (merged.dragHandleWidth ?? CoreDrawerStyle.defaultDragHandleWidth) *
      scaling;
  final dragHandleThickness =
      (merged.dragHandleThickness ??
          CoreDrawerStyle.defaultDragHandleThickness) *
      scaling;
  final dragHandleInset =
      theme.geometry.space(
        merged.dragHandleInset ?? CoreDrawerStyle.defaultDragHandleInset,
      ) *
      scaling;
  final dragHandleBorderRadius =
      (merged.dragHandleBorderRadius ??
              CoreDrawerStyle.defaultDragHandleBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;

  return ResolvedDrawer(
    panelBackgroundColor: panelBackgroundColor,
    panelBorderColor: panelBorderColor,
    panelBorderRadius: panelBorderRadius,
    panelBorderWidth: panelBorderWidth,
    panelWidth: panelWidth,
    panelHeight: panelHeight,
    panelPadding: panelPadding,
    headerPadding: headerPadding,
    headerSpacing: headerSpacing,
    footerPadding: footerPadding,
    dividerStyle: dividerStyle,
    closeButtonStyle: closeButtonStyle,
    panelBoxShadow: panelBoxShadow,
    castOutsideBox: castOutsideBox,
    panelInsetBoxShadow: panelInsetBoxShadow,
    barrierColor: barrierColor,
    backdropScale: backdropScale,
    backdropCornerRadius: backdropCornerRadius,
    openAnimationDuration: openAnimationDuration,
    closeAnimationDuration: closeAnimationDuration,
    titleStyle: titleStyle,
    descriptionStyle: descriptionStyle,
    titleDescriptionGapStyle: titleDescriptionGapStyle,
    dragHandleColor: dragHandleColor,
    dragHandleWidth: dragHandleWidth,
    dragHandleThickness: dragHandleThickness,
    dragHandleInset: dragHandleInset,
    dragHandleBorderRadius: dragHandleBorderRadius,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
  );
}
