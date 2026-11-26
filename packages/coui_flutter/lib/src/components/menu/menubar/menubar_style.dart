import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedMenubar
// ═══════════════════════════════════════════════════

/// Resolver output for [Menubar].
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has had the nested-merge chain applied plus the
/// `CoreMenubarStyle.defaultX` / `defaultsByVariant` static const
/// fallback and Flutter type conversion:
///
/// ```text
/// CoreMenubarStyle.defaultX                       // design system default
///   → theme.coreComponentTheme.menubar.style
///   → theme.coreComponentTheme.menubar.variantStyles[variant]
///   → widget.menubarStyle
/// ```
class ResolvedMenubar {
  /// Creates a [ResolvedMenubar].
  const ResolvedMenubar({
    required this.barPadding,
    required this.barBorderRadius,
    required this.barBorderWidth,
    required this.barBackgroundColor,
    required this.barBorderColor,
    required this.triggerButtonStyle,
    required this.openTriggerButtonStyle,
    required this.menuPanelStyle,
    required this.menuOffset,
    required this.labelTextStyle,
    required this.openLabelTextStyle,
    required this.boxShadow,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    this.refraction,
  });

  /// Effective internal padding of the horizontal bar (scaling applied).
  final EdgeInsets barPadding;

  /// Effective corner radius of the horizontal bar.
  final BorderRadius barBorderRadius;

  /// Effective border width of the horizontal bar (logical px, scaling
  /// applied).
  final double barBorderWidth;

  /// Effective background colour of the horizontal bar.
  final Color barBackgroundColor;

  /// Effective border colour of the horizontal bar.
  final Color barBorderColor;

  /// Nested [CoreButtonStyle] raw-forwarded to the top-level trigger
  /// `Button(variant: menubar)` — `CoreMenubarStyle.defaultTriggerButtonStyle`
  /// merged with the per-instance override. The `Button` resolver owns the
  /// resting / hover / open (selected) fill + scaling, so this is the
  /// single source for the trigger's button chrome (no resolver-side
  /// assembly).
  final CoreButtonStyle triggerButtonStyle;

  /// Nested [CoreButtonStyle] raw-forwarded to the trigger whose menu is
  /// open — [triggerButtonStyle] with the open trigger's overlay laid on top
  /// ([CoreMenubarStyle.defaultOpenTriggerButtonStyle] then the
  /// per-instance `openTriggerButtonStyle`). The open fill itself is the
  /// `menubar` `Button` variant's selected fill.
  final CoreButtonStyle openTriggerButtonStyle;

  /// Nested panel-box style raw-forwarded to the composed `Popup` — the
  /// menubar-divergent dropdown chrome ([CoreMenubarStyle
  /// .defaultMenuPanelStyle]: borderless + wider) merged with the
  /// per-instance override. The popup resolver fills the rest (padding /
  /// radius / background / shadow) and applies scheme / scaling.
  final CorePopupStyle menuPanelStyle;

  /// Effective vertical gap between the bar and a dropdown panel
  /// (logical px, scaling applied).
  final double menuOffset;

  /// Effective top-level trigger label typography. Each caller layer merges
  /// its label and nested trigger-label intent before the layers combine.
  /// The combined intent overlays [CoreMenubarStyle.defaultLabelTextStyle]
  /// (regular `labelLarge` and foreground colour), then materialises to a
  /// paint-ready Flutter [TextStyle].
  final TextStyle labelTextStyle;

  /// Effective label typography of the trigger whose menu is open —
  /// [labelTextStyle] with the open trigger's label overlay (the heavier
  /// weight) laid on top, materialised to a paint-ready [TextStyle].
  final TextStyle openLabelTextStyle;

  /// The active surface style's injected cast, or empty under a
  /// style that injects none.
  ///
  /// This surface draws its own box rather than composing
  /// `OutlinedContainer`, so the opt-in is restated. Empty under
  /// every style that casts nothing, so the widget paints it
  /// unconditionally.
  final List<BoxShadow> boxShadow;

  /// Backdrop blur sigma for the bar, `null` when the active theme
  /// states no material or the bar states no fill to blur behind
  /// (only reachable when `Menubar.border` is drawn).
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

  /// Local refraction, respecting accessibility.
  final CoreSurfaceRefraction? refraction;
}

// ═══════════════════════════════════════════════════
// resolveMenubar — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMenubar] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreMenubarStyle.defaultX` / `defaultsByVariant` static const
/// fallback so the widget reads only fully-resolved Flutter-typed
/// values.
ResolvedMenubar resolveMenubar(
  BuildContext context, {
  required CoreMenubarVariant variant,
  CoreMenubarStyle? menubarStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final menubarTheme = theme.coreComponentTheme?.menubar;

  // Variant chrome — defaultsByVariant single source of truth.
  final chrome = CoreMenubarStyle.defaultsByVariant[variant]!;

  // 3-stage merge chain — theme.style → theme.variantStyles[variant]
  // → widget.menubarStyle.
  final layers = [
    menubarTheme?.style,
    menubarTheme?.variantStyles?[variant],
    menubarStyle,
  ];
  final merged = resolveStyleChain(const CoreMenubarStyle(), layers);

  final materialTheme = resolveSurfaceTheme(context, merged.surfaceStyle);

  // ─── Panel box chrome — raw-forwarded to the composed `Popup` ─────
  // The menubar-divergent dropdown chrome (`defaultMenuPanelStyle`:
  // borderless + wider) merged with the per-instance override. No
  // scheme.resolve / `* scaling` here — the popup resolver owns that
  // (rule 2.2 nested-slot raw-forward).
  final menuPanelStyle = CoreMenubarStyle.defaultMenuPanelStyle
      .merge(CorePopupStyle(surfaceStyle: merged.surfaceStyle))
      .merge(merged.menuPanelStyle);

  // ─── Stage 1 RESOLVE — Core values (merge + fallback) ───
  final barBackgroundColorCore =
      merged.barBackgroundColor ?? chrome.barBackgroundColor;
  final barBorderColorCore = merged.barBorderColor ?? chrome.barBorderColor;
  final barBorderRadiusCore =
      merged.barBorderRadius ?? CoreMenubarStyle.defaultBarBorderRadius;
  // Keep each caller layer together before adding the default role.
  // A raw style merged with a role retains its size and line box.
  var labelIntent = const CoreTextStyle();
  for (final layer in layers) {
    final layerIntent = const CoreTextStyle()
        .merge(layer?.labelTextStyle)
        .merge(layer?.triggerButtonStyle?.labelStyle);
    labelIntent = labelIntent.merge(layerIntent);
  }
  final labelTextCore = CoreMenubarStyle.defaultLabelTextStyle.merge(
    labelIntent,
  );
  // The open trigger reads heavier than a resting one: the open slot's
  // label overlay (default, then per-instance) rides on the resting label.
  final openLabelTextCore = labelTextCore
      .merge(CoreMenubarStyle.defaultOpenTriggerButtonStyle.labelStyle)
      .merge(merged.openTriggerButtonStyle?.labelStyle);

  // The bar draws its own box rather than composing `OutlinedContainer`
  // (its root also hosts the trigger row + the border-visibility gate),
  // so it restates the same content-material seat directly here. Q2
  // (something passes behind it) is inferred from the code: the bar
  // mounts its dropdown through `PopoverOverlayHandler`/`OverlayPortal`,
  // so it is floating chrome over the page, not a nested content panel
  // — see `surface:functional` on the widget's class doc.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다.
  final material = materialTheme.surfaceFor(
    .functional,
    depth: SurfaceDepth.of(context),
  );

  // ─── Stage 2 EMIT — Flutter native (theme-dependent) ───
  // Colours: `scheme.resolve(core).toValue()`.
  final surfaceOpacity = material?.opacityIn(materialTheme);
  final barBackgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? barBackgroundColorCore
            : barBackgroundColorCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Gated on the fill, same as every other restated surface: a bar drawn
  // with `border: false` never reaches this box at all (see
  // `menubar.dart`), and a bar whose caller overrides the background to
  // fully transparent has nothing for a backdrop pass to blur behind.
  final hasFill = barBackgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(materialTheme)
      : null;
  final surfaceSheen = hasFill
      ? resolveSurfaceSheen(materialTheme, role: .functional)
      : null;
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border, and a surface that skips this keeps a border its siblings
  // have dropped.
  final barBorderColor = resolveSurfaceStroke(
    materialTheme,
    scheme.resolve(barBorderColorCore).toValue(),
    role: .functional,
  );
  final barBorderRadius = barBorderRadiusCore.toValue(geometry: theme.geometry);

  // Typography: single primitive `.toValue(theme:)` materialises the
  // token role + overlay + colour. No hand-rolled role / weight assembly.
  final labelTextStyle = labelTextCore.toValue(theme: theme);
  final openLabelTextStyle = openLabelTextCore.toValue(theme: theme);

  // Dimensional EMIT — `* scaling` is Stage2, so it finishes in the local.
  final barPadding =
      (merged.barPadding ?? CoreMenubarStyle.defaultBarPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final barBorderWidth = theme.geometry.stroke(
    merged.barBorderWidth ?? CoreMenubarStyle.defaultBarBorderWidth,
    scaling: scaling,
  );
  // Placement gap (trigger ↔ panel) is NOT scaled — it mirrors the Web
  // `OverlayPositioner` gap (a fixed logical-px offset) and `DropdownMenu`,
  // which both pass the raw `CoreSpace.space4`. Scaling it (unlike the other
  // menus) made the menubar panel sit at a different vertical gap than Web.
  final menuOffset = merged.menuOffset ?? CoreMenubarStyle.defaultMenuOffset;

  // Nested trigger Button style — raw-forward the Core slot (no
  // resolver-side assembly): `default.merge(override)`, handed straight to
  // the composed `Button`, which owns the resting / hover / selected fill +
  // scaling. The dropdown entry chrome is owned by the composed `Menu`.
  final triggerButtonStyle = CoreMenubarStyle.defaultTriggerButtonStyle.merge(
    merged.triggerButtonStyle,
  );
  // The open trigger adds its overlay on top of the resting style (the same
  // shape `NavigationMenu` gives its open trigger).
  final openTriggerButtonStyle = triggerButtonStyle
      .merge(CoreMenubarStyle.defaultOpenTriggerButtonStyle)
      .merge(merged.openTriggerButtonStyle);

  // The style injects its cast into surfaces that state no shadow of
  // their own — empty under every style that injects none.
  final boxShadow = resolveInjectedCast(theme);

  return ResolvedMenubar(
    refraction: hasFill ? materialTheme.surfaceRefraction : null,
    boxShadow: boxShadow,
    barPadding: barPadding,
    barBorderRadius: barBorderRadius,
    barBorderWidth: barBorderWidth,
    barBackgroundColor: barBackgroundColor,
    barBorderColor: barBorderColor,
    triggerButtonStyle: triggerButtonStyle,
    openTriggerButtonStyle: openTriggerButtonStyle,
    menuPanelStyle: menuPanelStyle,
    menuOffset: menuOffset,
    labelTextStyle: labelTextStyle,
    openLabelTextStyle: openLabelTextStyle,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
  );
}
