import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `HoverCard`.
///
/// Widget tree (`co_hover_card` builds the floating panel on hover):
///
/// ```text
/// MouseRegion (trigger anchor)
///   └─ GestureDetector (long-press fallback)
///        └─ trigger                              // caller-supplied Widget
///
/// (floating overlay, shown while hovered)
/// MouseRegion (keeps panel open while pointer is over it)
///   └─ Popup (panelStyle)                        // single panel-box source
///        └─ content                              // caller-supplied Widget
/// ```
///
/// Field grouping:
///
/// 1. **Panel chrome** — [panelStyle] forwards this hover card's merged panel
///    tokens to the composed `Popup`, the single source of truth for the
///    floating box (background / border / radius / shadow / padding / width
///    bounds / content colour). `Popup` runs `scheme.resolve` + scaling on
///    the slot itself, so the chrome stays as `coui_core` domain types here
///    (no widget-side `scheme.resolve`) and a light↔dark toggle while the
///    card is open re-paints the panel.
/// 2. **Layout dimension (scaling pre-applied)** — [panelOffset]: paint-ready
///    logical-px value the widget feeds to the overlay handler. Scaling is
///    baked in here (single materialise per surface) so the widget reads it
///    as-is without touching `theme.scaling`.
/// 3. **Timing values** — [openDelay] / [closeDelay] /
///    [transitionDuration]: consumed by the pointer / Timer handlers
///    that fire between builds.
class ResolvedHoverCard {
  /// Creates a [ResolvedHoverCard].
  const ResolvedHoverCard({
    required this.panelStyle,
    required this.panelOffset,
    required this.openDelay,
    required this.closeDelay,
    required this.transitionDuration,
  });

  /// Nested [CorePopupStyle] slot — forwarded to `Popup(popupStyle: …)` for
  /// the panel box. The hover card's `defaultPanelStyle` (content-sized under
  /// a ceiling) with any per-instance overrides flowing in from
  /// `widget.hoverCardStyle` merged on top; every other field is left for
  /// `Popup`'s own resolver to fill from `CorePopupStyle`'s defaults, which
  /// also applies scaling — so the widths stay pre-scaling here.
  final CorePopupStyle panelStyle;

  /// Paint-ready placement offset (scaling pre-applied) — the placement-
  /// axis offset between the trigger edge and the floating panel
  /// projected onto the placement axis. The widget passes this straight
  /// to the overlay handler's `offset`.
  final Offset panelOffset;

  /// Effective open delay (pointer enter → card visible).
  final Duration openDelay;

  /// Effective close delay (pointer exit → card hidden).
  final Duration closeDelay;

  /// Effective panel enter/exit transition duration.
  final Duration transitionDuration;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedHoverCard] for [HoverCard].
///
/// Single entry point — reads [CoreHoverCardTheme] from
/// `Theme.of(context).coreComponentTheme` itself so callers never touch
/// `coreComponentTheme` directly. The semantic [placement] flows in as a
/// resolver arg so the placement-axis [ResolvedHoverCard.panelOffset]
/// ships paint-ready.
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreHoverCardStyle.default*)
///   → theme.coreComponentTheme.hoverCard.style
///   → widget.openDelay / widget.closeDelay
///   → widget.hoverCardStyle
/// ```
ResolvedHoverCard resolveHoverCard(
  BuildContext context, {
  required CorePopoverPlacement placement,
  Duration? widgetOpenDelay,
  Duration? widgetCloseDelay,
  CoreHoverCardStyle? hoverCardStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final coreTheme = theme.coreComponentTheme?.hoverCard;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreHoverCardStyle(), [
    coreTheme?.style,
    hoverCardStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Widget-level openDelay / closeDelay win over the style chain, then
  // fall back to the design-system default.
  final openDelay =
      widgetOpenDelay ??
      merged.openDelay ??
      CoreHoverCardStyle.defaultOpenDelay;
  final closeDelay =
      widgetCloseDelay ??
      merged.closeDelay ??
      CoreHoverCardStyle.defaultCloseDelay;
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreHoverCardStyle.defaultTransitionDuration,
  );

  // ─── Nested panel-box slot (child-slot forward) ───────
  // The panel box is a composed `Popup`: the hover card states only its own
  // divergence (`defaultPanelStyle`) and forwards the slot raw, so `Popup`'s
  // resolver fills the rest from `CorePopupStyle`'s defaults and runs
  // colour / radius / scaling on it.
  final panelStyle = CoreHoverCardStyle.defaultPanelStyle.merge(
    merged.panelStyle,
  );

  // ─── Layout dimension (scaling pre-applied) ───────────
  // The placement-axis offset between the trigger edge and the floating
  // panel is projected onto the placement axis here so the widget feeds
  // the resolved `Offset` straight to the overlay handler.
  final placementOffset =
      merged.placementOffset ?? CoreHoverCardStyle.defaultPlacementOffset;
  final scaledPlacementOffset = placementOffset * scaling;
  final panelOffset = switch (placement) {
    .top || .topStart || .topEnd => Offset(0, -scaledPlacementOffset),
    .bottom || .bottomStart || .bottomEnd => Offset(0, scaledPlacementOffset),
    .left || .leftStart || .leftEnd => Offset(-scaledPlacementOffset, 0),
    .right || .rightStart || .rightEnd => Offset(scaledPlacementOffset, 0),
  };

  return ResolvedHoverCard(
    panelStyle: panelStyle,
    panelOffset: panelOffset,
    openDelay: openDelay,
    closeDelay: closeDelay,
    transitionDuration: transitionDuration,
  );
}
