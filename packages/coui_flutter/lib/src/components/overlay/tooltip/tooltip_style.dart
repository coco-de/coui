import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedTooltip
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Tooltip`.
///
/// Widget tree (`co_tooltip.dart` decides which optional branches render):
///
/// ```text
/// Padding (gap — trigger ↔ tooltip offset)
///   └─ optional SurfaceBlur (surfaceBlur, when > 0)
///        └─ optional ConstrainedBox (panelMaxWidth, when non-null)
///             └─ Container (backgroundColor + surfaceOpacity, borderRadius)
///                  └─ Padding (padding)
///                       └─ DefaultTextStyle.merge (labelTextStyle)
///                            └─ tooltipChild | Text (message)
/// ```
///
/// Both content paths sit under one `DefaultTextStyle.merge`, so a
/// `tooltipChild` inherits the label style as a *default* and still wins
/// with any style it states itself.
///
/// Every field is paint-ready: the widget hands Flutter framework
/// widgets their native type (`Color`, `BorderRadius`, `EdgeInsets`,
/// `TextStyle`, `double`). Scaling is pre-applied so the widget does not
/// multiply by `theme.scaling` itself. The label `TextStyle` is fully
/// composed here via the single-primitive
/// `CoreTooltipStyle.defaultLabelStyle.merge(merged.labelStyle)
/// .toValue(theme:)` path (typography role + foreground colour + slot
/// overlay in one pass) — the widget never touches `theme.typography`.
class ResolvedTooltip {
  /// Creates a [ResolvedTooltip].
  const ResolvedTooltip({
    required this.backgroundColor,
    required this.borderRadius,
    required this.panelMaxWidth,
    required this.padding,
    required this.gap,
    required this.tailWidth,
    required this.tailHeight,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.surfaceOpacity,
    required this.labelTextStyle,
  });

  // ── Chrome (token-fallback applied, scaling pre-applied) ──

  /// Effective panel background fill colour (design-system default +
  /// per-instance override). `surfaceOpacity` is applied later by the
  /// widget because the alpha multiplier is a behaviour value, not a
  /// pre-composable colour.
  final Color backgroundColor;

  /// Effective panel border radius (override else
  /// [CoreTooltipStyle.defaultPanelBorderRadius], scaling pre-applied).
  final BorderRadius borderRadius;

  /// Effective maximum panel width (logical px, scaling pre-applied), or
  /// `null` to leave the bubble unconstrained. Non-null makes the bubble
  /// wrap its content at this ceiling.
  final double? panelMaxWidth;

  /// Effective panel content padding (override else
  /// [CoreTooltipStyle.defaultPanelPadding], scaling pre-applied).
  final EdgeInsets padding;

  /// Effective overlay placement offset (logical px, scaling pre-applied)
  /// between the trigger anchor and the floating panel — design-system
  /// default unless `placementOffset` overrode it.
  final double gap;

  /// Effective tail base width (logical px, scaling pre-applied) — the
  /// triangle edge flush against the bubble side facing the trigger.
  /// `0` collapses the tail.
  final double tailWidth;

  /// Effective tail protrusion height (logical px, scaling pre-applied)
  /// — how far the tip extends beyond the bubble edge toward the
  /// trigger.
  final double tailHeight;

  /// Optional backdrop blur sigma applied behind the panel (behaviour
  /// value, **not** scaled).
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

  /// Optional panel surface opacity multiplier (0.0 – 1.0) — applied to
  /// [backgroundColor] by the widget (behaviour value).
  final double? surfaceOpacity;

  // ── Nested slot typography (paint-ready) ──────

  /// Paint-ready label (message text) [TextStyle] — typography base
  /// (the `labelSmall` role) composed with the resolved
  /// foreground colour and the `labelStyle` slot's overrides
  /// (colour / font size / weight). The widget feeds this straight to
  /// `DefaultTextStyle.merge`.
  final TextStyle labelTextStyle;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTooltip] for the given [context].
///
/// Single entry point — reads [CoreTooltipTheme] from
/// `Theme.of(context).coreComponentTheme` itself so callers never touch
/// `coreComponentTheme` directly.
///
/// Merge chain (chrome defaults + nested label slot in one pass):
///
/// ```text
/// CoreTooltipStyle (static const default*)
///   → theme.coreComponentTheme.tooltip.style
///   → widget.tooltipStyle
/// ```
ResolvedTooltip resolveTooltip(
  BuildContext context, {
  CoreTooltipStyle? tooltipStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final tooltipTheme = theme.coreComponentTheme?.tooltip;

  // ─── Stage 1 RESOLVE — merge chain ────────────────────
  final merged = resolveStyleChain(const CoreTooltipStyle(), [
    tooltipTheme?.style,
    tooltipStyle,
  ]);

  // ─── Stage 2 EMIT (Flutter — theme-dependent) ─────────
  // Colour: `scheme.resolve(token).toValue()`. Dimensional: domain
  // `.toValue()` then the `* scaling` size axis. Typography: the
  // single-primitive `default.merge(override).toValue(theme:)` — it
  // materialises the `labelSmall` role, overlays the slot's explicit
  // fields, and resolves the foreground colour
  // (`defaultLabelStyle.color = surface`, overridable) through the
  // active scheme so dark mode tracks. The widget never touches
  // `theme.typography`.
  final backgroundColor = scheme
      .resolve(
        merged.panelBackgroundColor ??
            CoreTooltipStyle.defaultPanelBackgroundColor,
      )
      .toValue();
  final borderRadius =
      (merged.panelBorderRadius ?? CoreTooltipStyle.defaultPanelBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  // Scaled inside the null check so "unconstrained" survives the size
  // axis — `(x ?? 0) * scaling` would turn it into a zero-width ceiling.
  final panelMaxWidth = merged.panelMaxWidth != null
      ? merged.panelMaxWidth! * scaling
      : null;
  final padding =
      (merged.panelPadding ?? CoreTooltipStyle.defaultPanelPadding).toValue(
        geometry: theme.geometry,
      ) *
      scaling;
  final gap =
      (merged.placementOffset ?? CoreTooltipStyle.defaultPlacementOffset) *
      scaling;
  final tailWidth =
      (merged.tailWidth ?? CoreTooltipStyle.defaultTailWidth) * scaling;
  final tailHeight =
      (merged.tailHeight ?? CoreTooltipStyle.defaultTailHeight) * scaling;
  final labelTextStyle = CoreTooltipStyle.defaultLabelStyle
      .merge(merged.labelStyle)
      .toValue(theme: theme);
  // Theme-axis fallback — see the note in `dialog_style.dart`; the
  // same gap left tooltips opaque under a material preset.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = theme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceBlur = merged.surfaceBlur ?? material?.blurRadius;
  // The same fallback the blur above already had. Only half of the pair
  // was carried, so a preset blurred behind a fill it never made
  // translucent.
  final surfaceOpacity = merged.surfaceOpacity ?? material?.opacityIn(theme);

  return ResolvedTooltip(
    backgroundColor: backgroundColor,
    borderRadius: borderRadius,
    panelMaxWidth: panelMaxWidth,
    padding: padding,
    gap: gap,
    tailWidth: tailWidth,
    tailHeight: tailHeight,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: material?.saturation,
    surfaceBackdropBrightness: material?.backdropBrightnessIn(theme),
    surfaceSheen: resolveSurfaceSheen(theme, role: CoreSurfaceRole.functional),
    surfaceOpacity: surfaceOpacity,
    labelTextStyle: labelTextStyle,
  );
}
