import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedNavigationMenu
// ═══════════════════════════════════════════════════

/// Resolver output for [NavigationMenu].
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has had the nested-merge chain applied plus the
/// `CoreNavigationMenuStyle.defaultX` / `defaultsByVariant` static const
/// fallback and Flutter type conversion:
///
/// ```text
/// CoreNavigationMenuStyle.defaultX                 // design system default
///   → theme.coreComponentTheme.navigationMenu.style
///   → theme.coreComponentTheme.navigationMenu.variantStyles[variant]
///   → widget.navigationMenuStyle
/// ```
///
/// The dropdown panel box is a composed [Popup]: its chrome is
/// raw-forwarded through [panelStyle] (the popup resolver finishes the
/// merge + default fallback + scheme / scaling), so this struct carries
/// the panel only as that single [CorePopupStyle] slot.
class ResolvedNavigationMenu {
  /// Creates a [ResolvedNavigationMenu].
  const ResolvedNavigationMenu({
    required this.triggerPadding,
    required this.triggerBorderRadius,
    required this.triggerHoverColor,
    required this.triggerButtonStyle,
    required this.contentTriggerButtonStyle,
    required this.openTriggerButtonStyle,
    required this.triggerSpacing,
    required this.triggerTextStyle,
    required this.chevronIconStyle,
    required this.panelStyle,
    required this.menuOffset,
    required this.duration,
    required this.closeDelay,
    required this.panelSwitchDuration,
  });

  /// Effective padding of each top-level trigger (scaling applied).
  final EdgeInsets triggerPadding;

  /// Effective corner radius of a top-level trigger.
  final BorderRadius triggerBorderRadius;

  /// Effective hover / active background colour of a trigger.
  final Color triggerHoverColor;

  /// Nested [CoreButtonStyle] raw-forwarded to a top-level trigger that
  /// shows no chevron (a link or an action) — `defaultTriggerButtonStyle`
  /// merged with the per-instance override. Composed into
  /// `Button(variant: menubar)`, whose resolver owns the resting fill,
  /// scaling and the resolution of every colour; this is the single source
  /// for the trigger's button chrome (no resolver-side assembly).
  final CoreButtonStyle triggerButtonStyle;

  /// [triggerButtonStyle] plus what a trigger that owns a dropdown (and so
  /// shows a chevron) changes: its directional inset.
  final CoreButtonStyle contentTriggerButtonStyle;

  /// [contentTriggerButtonStyle] plus what the trigger whose dropdown is
  /// open changes: it keeps the hover fill. The widget selects this one
  /// for the open trigger instead of handing the `Button` an ambient
  /// selected state — the `menubar` variant's selected fill is a different
  /// surface step.
  final CoreButtonStyle openTriggerButtonStyle;

  /// Effective spacing between adjacent top-level triggers in the bar
  /// (logical px, scaling applied). Flows directly into `Row.spacing`
  /// (Flutter native paint-API). The label → chevron gap is the trigger
  /// Button's own `iconLabelGapStyle`.
  final double triggerSpacing;

  /// Paint-ready top-level trigger label text style — the `labelLarge`
  /// typography role overlaid with the design-system medium weight
  /// (`defaultTriggerTextStyle`) and the per-instance `triggerTextStyle`
  /// slot, with the resolved `onSurface` foreground colour bound. Read
  /// straight by `co_navigation_menu` via `Text(style:)` (no widget-side
  /// `theme.typography.labelLarge.copyWith(...)`).
  final TextStyle triggerTextStyle;

  /// Chevron disclosure icon style of a content trigger — raw-forwarded
  /// to `Icon`, which runs its own resolver (scaling / colour
  /// resolution are `Icon`'s responsibility, so this slot is not
  /// pre-scaled here).
  final CoreIconStyle chevronIconStyle;

  /// Nested panel-box style raw-forwarded to the composed `Popup` — the
  /// variant-independent panel chrome ([CoreNavigationMenuStyle
  /// .defaultPanelStyle]) merged with the variant background / border
  /// colours and the per-instance override. The popup resolver fills the
  /// rest and applies scheme / scaling. Carries the panel background /
  /// border / radius / padding / shadow / min-width.
  final CorePopupStyle panelStyle;

  /// Effective vertical gap between the trigger bar and a dropdown
  /// panel (logical px, scaling applied).
  final double menuOffset;

  /// Effective open / close colour-transition duration.
  final Duration duration;

  /// Effective grace period between the pointer leaving the menu and the
  /// panel closing.
  ///
  /// Deliberately **not** routed through `resolveMotionDuration`: this is
  /// a pointer-intent grace period, not motion. Collapsing it to zero
  /// under reduced-motion would snap the panel shut while the pointer is
  /// still crossing the gap between the trigger and the panel — a
  /// usability regression for exactly the users the setting protects.
  final Duration closeDelay;

  /// Effective duration of the panel's slide when the open menu moves
  /// from one trigger to another (reduced-motion aware).
  final Duration panelSwitchDuration;
}

// ═══════════════════════════════════════════════════
// resolveNavigationMenu — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedNavigationMenu] for the given [context].
///
/// Walks the nested-merge chain and applies the
/// `CoreNavigationMenuStyle.defaultX` / `defaultsByVariant` static const
/// fallback so the widget reads only fully-resolved Flutter-typed
/// values (the panel is raw-forwarded as a [CorePopupStyle]).
ResolvedNavigationMenu resolveNavigationMenu(
  BuildContext context, {
  required CoreNavigationMenuVariant variant,
  CoreNavigationMenuStyle? navigationMenuStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final menuTheme = theme.coreComponentTheme?.navigationMenu;

  // Per-variant panel colours — defaultsByVariant single source of truth.
  final variantPanel = CoreNavigationMenuStyle.defaultsByVariant[variant]!;

  // 3-stage merge chain — theme.style → theme.variantStyles[variant]
  // → widget.navigationMenuStyle.
  final merged = resolveStyleChain(const CoreNavigationMenuStyle(), [
    menuTheme?.style,
    menuTheme?.variantStyles?[variant],
    navigationMenuStyle,
  ]);

  // ─── Panel box chrome — raw-forwarded to the composed `Popup` ─────
  // Variant-independent chrome (`defaultPanelStyle`) merged with the
  // variant background / border colours, then the per-instance override.
  // No scheme.resolve / `* scaling` here — the popup resolver owns that
  // (rule 2.2 nested-slot raw-forward).
  final panelStyle = CoreNavigationMenuStyle.defaultPanelStyle
      .merge(variantPanel)
      .merge(merged.panelStyle);

  // ─── Trigger label typography (paint-ready TextStyle) ─────
  // EMIT Stage 2 (Flutter) — overlay the design-system default
  // (`labelLarge` role + medium weight + `onSurface` colour) with the
  // per-instance `triggerTextStyle` slot, then materialise via the single
  // `toValue(theme:)` primitive: the token role resolves against the
  // active typography scale and the merged style's own `onSurface` colour
  // resolves through the scheme so dark mode tracks. Open / hover state
  // never touches the label style, so this is a pure static composition.
  final triggerTextStyle = CoreNavigationMenuStyle.defaultTriggerTextStyle
      .merge(merged.triggerTextStyle)
      .toValue(theme: theme);

  // ─── Colour resolution (paint-ready local vars) ───────────
  final triggerHoverColor = scheme
      .resolve(
        merged.triggerHoverColor ??
            CoreNavigationMenuStyle.defaultTriggerHoverColor,
      )
      .toValue();

  // Nested Button style — raw-forward the Core slot (no assembly): the
  // `Button` resolver owns the resting / hover / selected fill + scaling.
  final triggerButtonStyle = CoreNavigationMenuStyle.defaultTriggerButtonStyle
      .merge(merged.triggerButtonStyle);
  // A trigger that owns a dropdown starts from the same defaults plus its
  // own inset; the per-instance `triggerButtonStyle` still reaches it, then
  // the content-specific override wins. The open one adds its fill last.
  final contentTriggerButtonStyle = CoreNavigationMenuStyle
      .defaultTriggerButtonStyle
      .merge(CoreNavigationMenuStyle.defaultContentTriggerButtonStyle)
      .merge(merged.triggerButtonStyle)
      .merge(merged.contentTriggerButtonStyle);
  final openTriggerButtonStyle = contentTriggerButtonStyle
      .merge(CoreNavigationMenuStyle.defaultOpenTriggerButtonStyle)
      .merge(merged.openTriggerButtonStyle);

  // ─── Nested Style slot — raw-forward (Icon self-resolves) ─────
  final chevronIconStyle =
      merged.chevronIconStyle ??
      CoreNavigationMenuStyle.defaultChevronIconStyle;

  // ─── Behaviour / non-scaled scalars ───────────────────────
  final duration = resolveMotionDuration(
    context,
    merged.duration ?? CoreNavigationMenuStyle.defaultDuration,
  );
  // Pointer-intent grace period — see `ResolvedNavigationMenu.closeDelay`
  // for why this one bypasses `resolveMotionDuration`.
  final closeDelay =
      merged.closeDelay ?? CoreNavigationMenuStyle.defaultCloseDelay;
  final panelSwitchDuration = resolveMotionDuration(
    context,
    merged.panelSwitchDuration ??
        CoreNavigationMenuStyle.defaultPanelSwitchDuration,
  );

  // ─── Dimensional props — paint-ready local vars (scaling applied) ─────
  final triggerPadding =
      (merged.triggerPadding ?? CoreNavigationMenuStyle.defaultTriggerPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final triggerBorderRadius =
      (merged.triggerBorderRadius ??
              CoreNavigationMenuStyle.defaultTriggerBorderRadius)
          .toValue(geometry: theme.geometry);
  final triggerSpacing =
      theme.geometry.space(
        merged.triggerSpacing ?? CoreNavigationMenuStyle.defaultTriggerSpacing,
      ) *
      scaling;
  final menuOffset =
      (merged.menuOffset ?? CoreNavigationMenuStyle.defaultMenuOffset) *
      scaling;

  return ResolvedNavigationMenu(
    triggerPadding: triggerPadding,
    triggerBorderRadius: triggerBorderRadius,
    triggerHoverColor: triggerHoverColor,
    triggerButtonStyle: triggerButtonStyle,
    contentTriggerButtonStyle: contentTriggerButtonStyle,
    openTriggerButtonStyle: openTriggerButtonStyle,
    triggerSpacing: triggerSpacing,
    triggerTextStyle: triggerTextStyle,
    chevronIconStyle: chevronIconStyle,
    panelStyle: panelStyle,
    menuOffset: menuOffset,
    duration: duration,
    closeDelay: closeDelay,
    panelSwitchDuration: panelSwitchDuration,
  );
}
