import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedPopup
// ═══════════════════════════════════════════════════

/// Resolver output for [Popup].
///
/// Single struct that the widget reads — every chrome / dimensional
/// field has had the nested-merge chain applied plus the
/// `CorePopupStyle.defaultX` static const fallback and Flutter type
/// conversion:
///
/// ```text
/// CorePopupStyle.defaultX                         // design system default
///   → theme.coreComponentTheme.popup.style
///   → widget.popupStyle
/// ```
class ResolvedPopup {
  /// Creates a [ResolvedPopup].
  const ResolvedPopup({
    required this.padding,
    required this.borderRadius,
    required this.borderWidth,
    required this.backgroundColor,
    required this.borderColor,
    required this.boxShadow,
    required this.insetBoxShadow,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.minWidth,
    required this.maxWidth,
    required this.spacing,
    required this.contentTextColor,
    required this.openAnimationDuration,
    required this.closeAnimationDuration,
    this.refraction,
    this.isGlass = false,
  });

  /// Effective internal padding of the popup panel (scaling applied).
  final EdgeInsets padding;

  /// Effective corner radius of the popup panel.
  final BorderRadius borderRadius;

  /// Effective border width of the popup panel (logical px, scaling
  /// applied).
  final double borderWidth;

  /// Effective background colour of the popup panel.
  final Color backgroundColor;

  /// Effective border colour of the popup panel.
  final Color borderColor;

  /// Effective elevation shadow of the popup panel.
  final List<BoxShadow> boxShadow;

  /// The inset rim the active surface style adds, drawn over the panel
  /// rather than behind it — Flutter paints decoration shadows before
  /// the background, so an inset layer left there never appears.
  final List<BoxShadow> insetBoxShadow;

  /// Effective minimum width of the popup panel (logical px, scaling
  /// applied).
  final double minWidth;

  /// Effective maximum width of the popup panel (logical px, scaling
  /// applied; `double.infinity` when unbounded).
  final double maxWidth;

  /// Effective uniform spacing between children along the panel axis
  /// (logical px, scaling applied) — fed to `Column` / `Row.spacing`.
  final double spacing;

  /// Effective ambient content text colour — the panel wraps its content
  /// in a `DefaultTextStyle` whose colour is this, overriding only the
  /// colour (ambient typography role inherited).
  final Color contentTextColor;

  /// Effective open (enter) animation duration of the panel — behaviour
  /// timing fed to the shared overlay engine's `showDuration`, not paint
  /// chrome. The menu panel is a `Popup`, so this is the single source for
  /// the menu family's enter motion (user-overridable via
  /// `popupStyle.openAnimationDuration`).
  final Duration openAnimationDuration;

  /// Effective close (exit) animation duration of the panel — fed to the
  /// overlay engine's `dismissDuration`.
  final Duration closeAnimationDuration;

  /// Backdrop blur the active surface style asks this panel for, or null
  /// when the panel states no fill for a blur to sit behind.
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

  /// Resolved local refraction, respecting accessibility.
  final CoreSurfaceRefraction? refraction;

  /// Whether the panel uses glass rather than an opaque surface.
  final bool isGlass;
}

// ═══════════════════════════════════════════════════
// resolvePopup — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedPopup] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CorePopupStyle.defaultX` static const fallback so the widget
/// reads only fully-resolved Flutter-typed values.
ResolvedPopup resolvePopup(
  BuildContext context, {
  CorePopupStyle? popupStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final popupTheme = theme.coreComponentTheme?.popup;

  final merged = resolveStyleChain(const CorePopupStyle(), [
    popupTheme?.style,
    popupStyle,
  ]);

  final materialTheme = resolveSurfaceTheme(context, merged.surfaceStyle);

  // ─── Stage 1 RESOLVE — settle each value to its Core type ──
  final shadowBaseColor =
      merged.shadowBaseColor ?? CorePopupStyle.defaultShadowBaseColor;
  final padding = merged.padding ?? CorePopupStyle.defaultPadding;
  final borderRadius =
      merged.borderRadius ?? CorePopupStyle.defaultBorderRadius;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CorePopupStyle.defaultBorderWidth,
    scaling: scaling,
  );
  final backgroundColor =
      merged.backgroundColor ?? CorePopupStyle.defaultBackgroundColor;
  final borderColor = merged.borderColor ?? CorePopupStyle.defaultBorderColor;
  final boxShadow = merged.boxShadow ?? CorePopupStyle.defaultBoxShadow;
  final minWidth =
      (merged.minWidth ?? CorePopupStyle.defaultMinWidth) * scaling;
  final maxWidth =
      (merged.maxWidth ?? CorePopupStyle.defaultMaxWidth) * scaling;
  final spacing =
      theme.geometry.space(merged.spacing ?? CorePopupStyle.defaultSpacing) *
      scaling;

  // ─── Stage 2 EMIT — Flutter native (theme-dependent) ──
  final shadowBase = scheme.resolve(shadowBaseColor).toValue();
  // A panel may state its inset by the reading direction (start / end); the
  // physical sides it is drawn with are resolved here, against the direction
  // around the panel. A symmetric inset — every panel's default — needs none.
  final paddingValue =
      (padding.isDirectional
          ? padding
                .toGeometry(geometry: theme.geometry)
                .resolve(Directionality.of(context))
          : padding.toValue(geometry: theme.geometry)) *
      scaling;
  final borderRadiusValue = borderRadius.toValue(geometry: theme.geometry);
  // The material is a pair: a blur behind an opaque fill is invisible, and
  // translucency without a blur is just a lighter panel. Web restates the
  // fill for every surface it marks, so a Flutter panel that skips this
  // fold stays opaque while the same panel on the other platform turns to
  // glass — and the blur below would be painted and then covered.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = materialTheme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(materialTheme);
  final backgroundColorValue = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundColor
            : backgroundColor.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Through the shared helper, like every surface that resolves its own
  // stroke. This panel is the one the material reached last, and a
  // second copy of the rule here is how it would come to disagree.
  final borderColorValue = resolveSurfaceStroke(
    materialTheme,
    scheme.resolve(borderColor).toValue(),
    role: CoreSurfaceRole.functional,
  );
  final boxShadowValue = boxShadow.toValue(
    base: shadowBase,
    geometry: theme.geometry,
  );
  // Web gives this panel a rim already: its stack is a scale step and
  // its tint is the shadow token, so `emitShadow` routes it through
  // `var(--shadow-lg)`, which the active style has rewritten. Without
  // this line the same panel carries a rim on one platform and nothing
  // on the other.
  final insetBoxShadowValue = resolveSurfaceRim(context, stack: boxShadow);

  // A material is a statement about a fill — it blurs what shows through
  // one and lights that fill's edge. A panel with no fill has neither to
  // give, and this kit builds such panels: a nested submenu is a `Popup`
  // whose style states a transparent background so it reads as a group
  // inside its parent's panel rather than as a second panel. Handing that
  // one a material stacks a backdrop pass inside the pass already running
  // and draws a squared band around an indented group — both visible.
  //
  // The rim above needs no such gate because it derives from the shadow
  // stack, and a fill-less panel states none. The material has no stack to
  // read, so the gate has to be written.
  final hasFill = backgroundColorValue.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(materialTheme)
      : null;
  final surfaceSheen = hasFill
      ? resolveSurfaceSheen(materialTheme, role: CoreSurfaceRole.functional)
      : null;
  final contentTextColor = scheme
      .resolve(merged.contentColor ?? CorePopupStyle.defaultContentColor)
      .toValue();

  return ResolvedPopup(
    refraction: hasFill ? materialTheme.surfaceRefraction : null,
    isGlass: material?.type == SurfaceType.glass,
    padding: paddingValue,
    borderRadius: borderRadiusValue,
    borderWidth: borderWidth,
    backgroundColor: backgroundColorValue,
    borderColor: borderColorValue,
    boxShadow: boxShadowValue,
    insetBoxShadow: insetBoxShadowValue,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    minWidth: minWidth,
    maxWidth: maxWidth,
    spacing: spacing,
    contentTextColor: contentTextColor,
    // Behaviour timing (overlay engine), not paint — settled from the same
    // merge chain so the menu family's enter / exit motion is chained &
    // user-overridable, mirroring Web's `ResolvedPopup.style`.
    openAnimationDuration: resolveMotionDuration(
      context,
      merged.openAnimationDuration ??
          CorePopupStyle.defaultOpenAnimationDuration,
    ),
    closeAnimationDuration: resolveMotionDuration(
      context,
      merged.closeAnimationDuration ??
          CorePopupStyle.defaultCloseAnimationDuration,
    ),
  );
}
