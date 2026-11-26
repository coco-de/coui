import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedRefreshTrigger
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `RefreshTrigger`.
///
/// Widget tree (`co_refresh_trigger.dart` decides which stage branch
/// renders):
///
/// ```text
/// Center
///   └─ OutlinedContainer (containerStyle — fill, radius, material for role:functional)
///        └─ Padding (indicatorPadding | pullingPadding)
///             └─ CrossFadedTransition
///                  └─ Row (Gap(gapStyle: indicatorGapStyle))   // per stage:
///                       ├─ idle      : Text (idleTextStyle)
///                       ├─ refreshing: Text (refreshingTextStyle) + Loading
///                       ├─ completed : Text (completedTextStyle)
///                       │              + Icon check (completedIconStyle)
///                       └─ pulling   : Icon (arrowIconStyle)
///                                      + Text (idleTextStyle) + Icon
/// ```
///
/// Field grouping:
///
/// 1. **State-independent chrome** — [containerStyle] carries pre-EMIT
///    Core values for the composed `OutlinedContainer` (mirrors `Alert`'s
///    panel box); [indicatorPadding] / [pullingPadding] are paint-ready
///    `EdgeInsets` with `theme.scaling` already baked in, so the widget
///    reads them straight (Epic #1603 C12 — scaling resolved in one
///    place).
/// 2. **Per-stage label styles** — paint-ready [TextStyle] composed in
///    the resolver (typography slot + per-instance `labelStyle` override
///    + per-stage foreground colour). The widget never re-composes
///    typography or resolves a stage colour (Epic #1603 C11 — colour /
///    label composition lives in the resolver).
/// 3. **Nested style slot** — [CoreIconStyle] for the pulling-stage
///    arrow, forwarded straight into `Icon(iconStyle: …)` so the icon
///    runs its own `scheme.resolve` (Epic #1603 C8 — child slot forward,
///    no Flutter-`Color` → `CoreColor` round-trip).
class ResolvedRefreshTrigger {
  /// Creates a [ResolvedRefreshTrigger].
  const ResolvedRefreshTrigger({
    required this.containerStyle,
    required this.indicatorPadding,
    required this.pullingPadding,
    required this.indicatorGapStyle,
    required this.idleTextStyle,
    required this.refreshingTextStyle,
    required this.completedTextStyle,
    required this.completedIconStyle,
    required this.arrowIconStyle,
    required this.animationDuration,
  });

  // ── State-independent chrome ─────────────────────────────────

  /// Child-component contract slot for the composed `OutlinedContainer`,
  /// which owns the indicator pill — fill, radius, and whatever material
  /// the active style states for `role: .functional` (the pull-to-refresh
  /// indicator floats over the content it refreshes).
  ///
  /// Carries *pre-EMIT* Core values on purpose — same reasoning as
  /// `ResolvedAlert.containerStyle`: `OutlinedContainer` runs its own
  /// `scheme.resolve` / scaling, so handing it finished Flutter values
  /// would bend them twice.
  final CoreOutlinedContainerStyle containerStyle;

  /// Resolved indicator content padding for the resting state
  /// (scaling pre-applied).
  final EdgeInsets indicatorPadding;

  /// Resolved indicator content padding for the compact `pulling`
  /// state (scaling pre-applied).
  final EdgeInsets pullingPadding;

  /// Nested [CoreGapStyle] slot forwarded to the `Gap` siblings
  /// rendered between the indicator row children — already merged
  /// against the per-instance override so the widget can pass it
  /// straight to `Gap(gapStyle: …)` without further fallback logic.
  final CoreGapStyle indicatorGapStyle;

  // ── Per-stage label styles (paint-ready) ────────────────────

  /// Paint-ready label style for the `idle` / `pulling` stages
  /// (typography + override + idle foreground colour).
  final TextStyle idleTextStyle;

  /// Paint-ready label style for the `refreshing` stage.
  final TextStyle refreshingTextStyle;

  /// Paint-ready label style for the `completed` stage.
  final TextStyle completedTextStyle;

  /// Nested icon style for the completed-stage check glyph — forwarded
  /// to `Icon(iconStyle: …)` so the icon resolves its own colour
  /// (mirrors the Web twin's `Icon(LucideIcons.check)`).
  final CoreIconStyle completedIconStyle;

  // ── Nested style slot (CoreXxxStyle) ────────────────────────

  /// Nested icon style for the pulling-stage arrow — forwarded to
  /// `Icon(iconStyle: …)` so the icon resolves its own colour.
  final CoreIconStyle arrowIconStyle;

  /// Resolved slide / cross-fade animation duration.
  final Duration animationDuration;
}

// ═══════════════════════════════════════════════════
// resolveRefreshTrigger — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedRefreshTrigger] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreRefreshTriggerStyle.defaultX)
///   → theme.coreComponentTheme.refreshTrigger.style
///   → widget.refreshTriggerStyle
/// ```
///
/// Walks the nested-merge chain, applies the
/// `CoreRefreshTriggerStyle.defaultX` static const fallback, bakes
/// `theme.scaling` into the dimensional chrome, and composes the
/// per-stage label styles so the widget reads only fully-resolved,
/// paint-ready values.
ResolvedRefreshTrigger resolveRefreshTrigger(
  BuildContext context, {
  CoreRefreshTriggerStyle? refreshTriggerStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final refreshTriggerTheme = theme.coreComponentTheme?.refreshTrigger;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreRefreshTriggerStyle(), [
    refreshTriggerTheme?.style,
    refreshTriggerStyle,
  ]);

  // ─── Stage1 RESOLVE — merged override else static const default ──
  final bgCore =
      merged.indicatorBackgroundColor ??
      CoreRefreshTriggerStyle.defaultIndicatorBackgroundColor;
  final radiusCore =
      merged.indicatorBorderRadius ??
      CoreRefreshTriggerStyle.defaultIndicatorBorderRadius;
  final paddingCore =
      merged.indicatorPadding ??
      CoreRefreshTriggerStyle.defaultIndicatorPadding;
  final pullingPaddingCore =
      merged.pullingPadding ?? CoreRefreshTriggerStyle.defaultPullingPadding;
  // Per-stage text style slots — each carries the `labelLarge` role
  // token plus the stage foreground colour. Merged on top of the
  // design-system default (raw per-stage `*TextColor` fields replaced
  // by these nested `CoreTextStyle` slots).
  final idleTextStyleSlot = CoreRefreshTriggerStyle.defaultIdleTextStyle.merge(
    merged.idleTextStyle,
  );
  final refreshingTextStyleSlot = CoreRefreshTriggerStyle
      .defaultRefreshingTextStyle
      .merge(merged.refreshingTextStyle);
  final completedTextStyleSlot = CoreRefreshTriggerStyle
      .defaultCompletedTextStyle
      .merge(merged.completedTextStyle);
  final idleColorCore =
      idleTextStyleSlot.color ??
      CoreRefreshTriggerStyle.defaultIdleTextStyle.color!;
  final refreshingColorCore =
      refreshingTextStyleSlot.color ??
      CoreRefreshTriggerStyle.defaultRefreshingTextStyle.color!;
  final completedColorCore =
      completedTextStyleSlot.color ??
      CoreRefreshTriggerStyle.defaultCompletedTextStyle.color!;

  // Per-stage paint-ready label styles — each per-stage slot supplies
  // the role token, the per-instance `labelStyle` overlays typography
  // only, and the stage foreground colour is forced via the `color:`
  // arg (single primitive — `default.merge(override).toValue(theme:,
  // color:)`, no hand-rolled `applyCoreTextStyle` /
  // `resolveTypographyRole` assembly). Mirrors the badge resolver.
  final idleLabelCore = idleTextStyleSlot.merge(merged.labelStyle);
  final refreshingLabelCore = refreshingTextStyleSlot.merge(merged.labelStyle);
  final completedLabelCore = completedTextStyleSlot.merge(merged.labelStyle);

  // The indicator pill is composed, not drawn here — `OutlinedContainer`
  // owns it, the way `Alert`'s panel does. Passing Core values (not
  // resolved ones) is what keeps the scheme-resolve / geometry / scaling
  // bend applied exactly once: that component runs those steps itself.
  // Composing is also what gets this surface the `role: .functional`
  // material a glass style states for a floating indicator, which it
  // drew none of while it owned its own `DecoratedBox`.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: bgCore,
    borderRadius: radiusCore,
    borderWidth: 0,
  );

  // ─── Stage2 EMIT (Flutter) — theme-resolved Flutter values ──────
  final indicatorPadding =
      (paddingCore.toValue(geometry: theme.geometry)) * scaling;
  final pullingPaddingValue =
      (pullingPaddingCore.toValue(geometry: theme.geometry)) * scaling;
  final idleColor = scheme.resolve(idleColorCore).toValue();
  final refreshingColor = scheme.resolve(refreshingColorCore).toValue();
  final completedColor = scheme.resolve(completedColorCore).toValue();
  final idleTextStyle = idleLabelCore.toValue(color: idleColor, theme: theme);
  final refreshingTextStyle = refreshingLabelCore.toValue(
    color: refreshingColor,
    theme: theme,
  );
  final completedTextStyle = completedLabelCore.toValue(
    color: completedColor,
    theme: theme,
  );

  // Nested `CoreGapStyle` slot — merge the design-system default with
  // the per-instance override and forward the resulting slot straight
  // to the `Gap` siblings rendered between the indicator row
  // children (child slot raw-forward; `Gap` runs its own scaling).
  final indicatorGapStyle = CoreRefreshTriggerStyle.defaultIndicatorGapStyle
      .merge(merged.indicatorGapStyle);

  // Arrow icon colour forwarded as a CoreColor slot (idle stage tone)
  // — `Icon` runs its own `scheme.resolve`, so no Color → CoreColor
  // round-trip here.
  final arrowIconStyle = CoreIconStyle(color: idleColorCore);
  final completedIconStyle = CoreIconStyle(color: completedColorCore);

  final animationDuration = resolveMotionDuration(
    context,
    merged.animationDuration ??
        CoreRefreshTriggerStyle.defaultAnimationDuration,
  );

  return ResolvedRefreshTrigger(
    containerStyle: containerStyle,
    indicatorPadding: indicatorPadding,
    pullingPadding: pullingPaddingValue,
    indicatorGapStyle: indicatorGapStyle,
    idleTextStyle: idleTextStyle,
    refreshingTextStyle: refreshingTextStyle,
    completedTextStyle: completedTextStyle,
    completedIconStyle: completedIconStyle,
    arrowIconStyle: arrowIconStyle,
    animationDuration: animationDuration,
  );
}
