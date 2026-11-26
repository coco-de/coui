import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `ValidationBadge`.
///
/// Widget tree (`co_validation_badge` renders it verbatim):
///
/// ```text
/// (optional) SurfaceBlur (surfaceBlur / surfaceSaturation /
///   │                     surfaceBackdropBrightness / surfaceSheen)
///   └─ Container (decoration: backgroundColor / borderColor / borderRadius,
///                 padding: vertical/horizontalPadding)
///        └─ Row (mainAxisSize.min, crossAxisAlignment.center)
///             ├─ Icon (icon, iconStyle: iconStyle)
///             ├─ Gap (gapStyle: iconLabelGapStyle)
///             └─ Flexible > Text (label, textStyle)
/// ```
///
/// Field grouping:
///
/// 1. **State-resolved chrome colours** — [backgroundColor] /
///    [foregroundColor] / [borderColor] are paint-ready Flutter
///    [Color]s. The resolver folds the `pending` / `valid` / `invalid`
///    state plus the per-instance colour override into a single resolved
///    value (each routed through `scheme.resolve(...).toValue()` so the
///    originating token survives dark-mode resolution — Epic #1603 C7).
/// 2. **State-independent chrome** — paint-ready Flutter types
///    ([EdgeInsets]-friendly `double` padding, [BorderRadius]).
/// 3. **Child-component slots** — [iconStyle] is the nested
///    [CoreIconStyle] forwarded straight to `Icon(iconStyle: …)`. Its
///    `size` is the per-size token and its `color` is the resolved
///    per-state foreground [CoreColor] (sb #2305 — flat `iconSize` +
///    `iconColor` folded into one slot; `Icon`'s own resolver applies
///    `theme.scaling`, so the slot stays pre-scaling here).
///    [iconLabelGapStyle] is forwarded straight to `Gap(gapStyle: …)`
///    (Gap runs its own scaling step so the slot stays raw / pre-
///    scaling here); and [textStyle] is the paint-ready label [TextStyle].
class ResolvedValidationBadge {
  /// Creates a [ResolvedValidationBadge].
  const ResolvedValidationBadge({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.height,
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.iconLabelGapStyle,
    required this.borderRadius,
    required this.borderWidth,
    required this.iconStyle,
    required this.textStyle,
    required this.icon,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  /// Paint-ready container background colour (state + override resolved).
  final Color backgroundColor;

  /// Paint-ready text + icon foreground colour (state + override resolved).
  final Color foregroundColor;

  /// Paint-ready container border colour (state + override resolved).
  final Color borderColor;

  /// Fixed height of the badge (already scaled).
  final double height;

  /// Vertical padding (logical px).
  final double verticalPadding;

  /// Horizontal padding (logical px).
  final double horizontalPadding;

  /// Nested [CoreGapStyle] slot for the icon ↔ label gap — forwarded
  /// straight to `Gap(gapStyle: …)`. `Gap` runs its own resolve /
  /// scaling step, so this slot is the merged design-system default +
  /// per-instance override in pre-scaling units (the receiving widget
  /// owns scaling).
  final CoreGapStyle iconLabelGapStyle;

  /// Paint-ready container border radius (Epic #1603 C9 — `BorderRadius`,
  /// not a raw `double`, so the widget passes it straight to
  /// `BoxDecoration.borderRadius`).
  final BorderRadius borderRadius;

  /// Container border stroke width (logical px, geometry-bent + scaling
  /// pre-applied).
  final double borderWidth;

  /// Nested [CoreIconStyle] slot — forwarded straight to
  /// `Icon(iconStyle: …)`. Carries the per-size `size` (logical px) and
  /// the resolved per-state foreground `color` as a tagged [CoreColor].
  /// `Icon`'s own resolver applies `theme.scaling`, so this slot stays
  /// pre-scaling (sb #2305 — flat `iconSize` + `iconColor` folded here,
  /// removing the widget-side inline `CoreIconStyle(…)` repackaging).
  final CoreIconStyle iconStyle;

  /// Resolved label text style (already colour-bound).
  final TextStyle textStyle;

  /// Resolved icon glyph for the current state.
  final IconName icon;

  // ── Surface material (the part the fill share cannot carry) ──

  /// Backdrop blur sigma behind the chip, or `null` when the active style
  /// states no material, when this state paints no fill, or when the chip
  /// sits inside another surface (the nested token drops the pass).
  ///
  /// The Web twin gets the same frost from the style rule its surface
  /// marker selects; without this the chip frosted on one platform and
  /// only faded on the other.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through the chip, or null.
  final double? surfaceBackdropBrightness;

  /// Edge light along the chip's contour, or null.
  final ResolvedSurfaceSheen? surfaceSheen;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedValidationBadge] for the given [context].
///
/// Single public entry point — the 2-tier colour merge chain
/// (`theme.style` → `widget.style`), the per-state colour table, the
/// typography lookup, and the icon selection are all applied once here.
/// The effective [size] (widget → default) is resolved widget-side and
/// handed in concrete, so the per-size token lookup is a plain map index
/// here (mirrors the Web resolver + PoC `Alert` / `Button` where
/// semantic identifiers stay on the widget). The per-state icon fallback
/// lives in the file-private `_defaultValidationBadgeIcon` below so the
/// widget stays render-only (Epic #1603 C1 single-entry).
///
/// Merge chain:
///
/// ```text
/// design-system default (defaultsBySize[size] / defaultsByState[state])
///   → theme.coreComponentTheme.validationBadge.style
///   → widget.style
/// ```
ResolvedValidationBadge resolveValidationBadge(
  BuildContext context, {
  required CoreValidationState state,
  required CoreValidationBadgeSize size,
  required IconName? pendingIcon,
  required IconName? validIcon,
  required IconName? invalidIcon,
  CoreValidationBadgeStyle? widgetStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final coreTheme = theme.coreComponentTheme?.validationBadge;

  // 1. Per-size dimensional defaults from the Core single source (the
  //    effective `size` is already resolved widget-side).
  final tokens = CoreValidationBadgeStyle.defaultsBySize[size]!;

  // 2. Colour resolution — 2-tier merge chain (widget → theme → defaults).
  final merged = resolveStyleChain(const CoreValidationBadgeStyle(), [
    coreTheme?.style,
    widgetStyle,
  ]);

  // Per-state override slots (per-instance colour override, else null →
  // the design-system default colour for the state takes over below).
  // sb8 — per-state foreground colour now lives inside the nested
  // `xxxLabelTextStyle.color` slot.
  final (bgOverride, fgOverride, borderOverride) = switch (state) {
    .pending => (
      merged.pendingBackgroundColor,
      merged.pendingLabelTextStyle?.color,
      merged.pendingBorderColor,
    ),
    .valid => (
      merged.validBackgroundColor,
      merged.validLabelTextStyle?.color,
      merged.validBorderColor,
    ),
    .invalid => (
      merged.invalidBackgroundColor,
      merged.invalidLabelTextStyle?.color,
      merged.invalidBorderColor,
    ),
  };

  // Per-state design-system default colours from the Core single source
  // (`CoreValidationBadgeStyle.defaultsByState[state]!`) — token-bound
  // `CoreColor`s whose alpha lives in the token `opacity`, so the value
  // flows through one source and dark-mode resolution survives. The Web
  // resolver reads the same map (layer-mapping.md single-source).
  final stateDefaults = CoreValidationBadgeStyle.defaultsByState[state]!;
  final backgroundCore = bgOverride ?? stateDefaults.backgroundColor;

  // Whether this state paints a fill. The surface material is a statement
  // about a filled box: handed to a chip whose fill is transparent, it
  // frosts a backdrop behind nothing and draws an edge band around a box
  // that is not there. The Web twin carries the surface marker on the same
  // answer.
  final hasFill = scheme.resolve(backgroundCore).toValue().a > 0;

  // Surface material at the content role. ValidationBadge draws its own
  // box rather than composing `OutlinedContainer` (its Web root is a
  // `<span>`, and wrapping it in the primitive's `<div>` breaks the inline
  // flow it sits in — #4358), so it reads the seat here, at this chip's
  // ambient nesting depth, and draws all of it: the share folded into the
  // fill below, and the frost, chroma, dimming, edge light and bend around
  // the box ([ResolvedValidationBadge.surfaceBlur] and its siblings).
  final material = hasFill
      ? theme.surfaceFor(.content, depth: SurfaceDepth.of(context))
      : null;
  final surfaceOpacity = material?.opacityIn(theme);

  /// Folds the active content-role material's opacity into [color]. The
  /// token's own alpha stays a factor: a state tint authored at 10% comes
  /// out at 10% of the share, not at the share.
  CoreColor materialFill(CoreColor color) =>
      surfaceOpacity == null ? color : color.scaleAlpha(surfaceOpacity);

  // Resolve each surface once — per-instance override wins, else the
  // state default. Routed through `scheme.resolve(x).toValue()` (Epic
  // #1603 C7 — no `Color(core.value)` / standalone `.toValue()`).
  final foregroundCore = scheme.resolve(
    fgOverride ?? stateDefaults.foregroundColor,
  );
  final backgroundColor = scheme
      .resolve(materialFill(backgroundCore))
      .toValue();
  final foregroundColor = foregroundCore.toValue();
  // The material's own edge treatment (when it states one) suppresses
  // this component's stroke colour — never its width. Only on a chip that
  // takes the material: one with no fill keeps its stroke, as its Web twin
  // does — it carries no surface marker for the style rule to clear.
  final authoredBorder = scheme
      .resolve(borderOverride ?? stateDefaults.borderColor)
      .toValue();
  final borderColor = material == null
      ? authoredBorder
      : resolveSurfaceStroke(theme, authoredBorder);

  // The rest of the material — the part `materialFill` cannot carry. A
  // nested chip (inside another surface) gets the nested token, whose
  // backdrop pass is dropped and whose edge stays.
  final surfaceBlur = material?.blurRadius;
  final surfaceSaturation = material?.saturation;
  final surfaceBackdropBrightness = material?.backdropBrightnessIn(theme);
  final surfaceSheen = material == null ? null : resolveSurfaceSheen(theme);

  // 3. Typography — the per-size token role (`labelMedium` for xs/sm,
  //    `bodySmall` for md) carrying the per-state colour default, then any
  //    per-instance `labelStyle` overlay, materialised through the single
  //    `.toValue(theme:, color:)` path. The `color:` argument forces the
  //    resolved per-state foreground so the label tracks the state colour
  //    (it wins over whatever colour rode in through the merge).
  final labelCore = tokens.labelStyle.merge(_stateLabelStyle(merged, state));
  final textStyle = labelCore.toValue(color: foregroundColor, theme: theme);

  // 4. Icon selection — widget override > Lucide default per state.
  final iconForState = switch (state) {
    .pending => pendingIcon,
    .valid => validIcon,
    .invalid => invalidIcon,
  };
  final icon = iconForState ?? _defaultValidationBadgeIcon(state);

  // Nested CoreGapStyle slot — merge the per-size default with the
  // per-instance override and forward raw (pre-scaling) to Gap, which
  // runs its own scaling step.
  final iconLabelGapStyle = tokens.iconLabelGapStyle.merge(
    merged.iconLabelGapStyle,
  );

  // Nested CoreIconStyle slot — base carries the per-size `size` token and
  // the resolved per-state foreground `color`; the per-instance override
  // (`merged.iconStyle`) wins on each non-null field. Forwarded raw (pre-
  // scaling) to Gap-style `Icon`, whose own resolver applies scaling.
  final iconStyle = CoreIconStyle(
    size: tokens.iconSize,
    color: foregroundCore,
  ).merge(merged.iconStyle);

  // Paint-ready `BorderRadius` (C9) — the per-size token default is a
  // platform-neutral logical-px `double`; convert via `CoreBorderRadius`
  // so the widget reads a Flutter `BorderRadius` directly. Synthesised
  // here (local var) so the return literal stays a bare mapping.
  final borderRadius =
      (CoreBorderRadius.all(
        tokens.borderRadius,
      ).toValue(geometry: theme.geometry)) *
      scaling;
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreValidationBadgeStyle.defaultBorderWidth,
    scaling: scaling,
  );

  final height = tokens.height * scaling;
  final verticalPadding =
      theme.geometry.space(tokens.verticalPadding) * scaling;
  final horizontalPadding =
      theme.geometry.space(tokens.horizontalPadding) * scaling;

  return ResolvedValidationBadge(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    borderColor: borderColor,
    height: height,
    verticalPadding: verticalPadding,
    horizontalPadding: horizontalPadding,
    iconLabelGapStyle: iconLabelGapStyle,
    borderRadius: borderRadius,
    borderWidth: borderWidth,
    iconStyle: iconStyle,
    textStyle: textStyle,
    icon: icon,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
  );
}

/// Returns the per-state label [CoreTextStyle] for [state] — the Core
/// per-state default (colour only; the role rides the per-size token this
/// is merged onto) with the caller's `xxxLabelTextStyle` overlay on top.
CoreTextStyle _stateLabelStyle(
  CoreValidationBadgeStyle merged,
  CoreValidationState state,
) => switch (state) {
  .pending => CoreValidationBadgeStyle.defaultPendingLabelTextStyle.merge(
    merged.pendingLabelTextStyle,
  ),
  .valid => CoreValidationBadgeStyle.defaultValidLabelTextStyle.merge(
    merged.validLabelTextStyle,
  ),
  .invalid => CoreValidationBadgeStyle.defaultInvalidLabelTextStyle.merge(
    merged.invalidLabelTextStyle,
  ),
};

// ═══════════════════════════════════════════════════
// File-private fallback helpers (C1 — not part of the public surface)
// ═══════════════════════════════════════════════════

/// Returns the default Lucide icon for [state] when a widget-level icon is
/// not provided.
IconName _defaultValidationBadgeIcon(CoreValidationState state) =>
    switch (state) {
      .pending => LucideIcons.clock,
      .valid => LucideIcons.check,
      .invalid => LucideIcons.x,
    };
