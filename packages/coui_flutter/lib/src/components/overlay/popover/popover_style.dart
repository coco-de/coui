import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show internal;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Popover`.
///
/// Widget tree (`co_popover.dart` reads this struct render-only):
///
/// ```text
/// {trigger sizing wrapper: IntrinsicWidth | none}
///   └─ trigger interaction wrapper (GestureDetector | MouseRegion | Focus)
/// {floating panel — built in `_buildPanel`}
///   └─ Popup (panelStyle)                            // single panel-box source
///        └─ content                                  // caller-supplied Widget
/// ```
///
/// Field grouping:
///
/// 1. **Paint-ready dimensional chrome** — [placementOffset] /
///    [viewportMargin] arrive with `theme.scaling` already applied (Epic
///    #1603 C11 — scaling resolves once, the widget never multiplies).
/// 2. **Panel chrome** — [panelStyle] forwards this popover's merged panel
///    tokens to the composed `Popup`, the single source of truth for the
///    floating box (background / border / radius / shadow / padding /
///    content colour). `Popup` runs `scheme.resolve` + scaling and
///    re-resolves against the live theme every call so a light↔dark toggle
///    while the popover is open re-paints the panel.
/// 3. **Behaviour values** — [openAnimationDuration] /
///    [closeAnimationDuration] / [triggerSizing] read by the overlay
///    handler and the trigger sizing wrapper.
/// 4. **Nested style slot** — [triggerStyle] forwarded to a
///    [Button] trigger via `Button(buttonStyle: …)`.
class ResolvedPopover {
  /// Creates a [ResolvedPopover].
  const ResolvedPopover({
    required this.placementOffset,
    required this.viewportMargin,
    required this.openAnimationDuration,
    required this.closeAnimationDuration,
    required this.triggerSizing,
    required this.panelStyle,
    required this.triggerStyle,
  });

  /// Trigger-to-panel placement offset (logical px, **scaling pre-applied**
  /// — `co_popover` forwards it straight to the placement offset axis).
  final double placementOffset;

  /// Viewport-edge margin enforced by the overlay handler when applying
  /// collision-shift (**scaling pre-applied**). Mirrors the Web floating
  /// engine's `padding` option — the panel won't paint within this much
  /// of the visible viewport edge regardless of placement.
  final EdgeInsets viewportMargin;

  /// Open (enter) animation duration.
  final Duration openAnimationDuration;

  /// Close (exit) animation duration.
  final Duration closeAnimationDuration;

  /// Trigger sizing (intrinsic / expand).
  final CorePopoverTriggerSizing triggerSizing;

  /// Panel chrome forwarded to the composed `Popup` — the popover panel
  /// box (background / border / radius / shadow / padding / content text
  /// colour) is a single source of truth in `Popup` / `CorePopupStyle`,
  /// not re-resolved here. Built from this popover's merged
  /// `CorePopoverStyle` panel tokens with `minWidth: 0` so the panel sizes
  /// to its content; `Popup`'s resolver applies `scheme.resolve` + scaling.
  final CorePopupStyle panelStyle;

  /// Nested trigger button style. Used when the trigger is a
  /// [Button] — caller pipes it via `Button(buttonStyle:
  /// resolved.triggerStyle, ...)` to apply chrome / dimensional overrides
  /// without leaking variant changes.
  final CoreButtonStyle? triggerStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedPopover] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CorePopoverStyle.default*)
///   → theme.coreComponentTheme.popover.style
///   → widget.popoverStyle
/// ```
///
/// Panel chrome is **not** resolved here — it forwards raw as a
/// [CorePopupStyle] ([ResolvedPopover.panelStyle]) to the composed
/// `Popup`, the single source of truth for the floating box (`Popup`'s
/// resolver runs `scheme.resolve` + scaling). Popover-specific layout
/// values follow `merged.X ?? CorePopoverStyle.defaultX`: dimensional
/// ones ([placementOffset] / [viewportPadding]) bake in `theme.scaling`
/// here so the widget reads paint-ready values; behaviour ones
/// (durations / `triggerSizing`) pass through unscaled.
ResolvedPopover resolvePopover(
  BuildContext context, {
  CorePopoverStyle? popoverStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final popoverTheme = theme.coreComponentTheme?.popover;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CorePopoverStyle(), [
    popoverTheme?.style,
    popoverStyle,
  ]);

  // ─── Engine config (paint-ready — scaling applied) ───
  final placementOffset =
      (merged.placementOffset ?? CorePopoverStyle.defaultPlacementOffset) *
      scaling;
  final viewportMargin =
      ((merged.viewportPadding ?? CorePopoverStyle.defaultViewportPadding)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final triggerSizing =
      merged.triggerSizing ?? CorePopoverStyle.defaultTriggerSizing;

  // ─── Behaviour values ─────────────────────────────────
  final openDuration = resolveMotionDuration(
    context,
    merged.openAnimationDuration ??
        CorePopoverStyle.defaultOpenAnimationDuration,
  );
  final closeDuration = resolveMotionDuration(
    context,
    merged.closeAnimationDuration ??
        CorePopoverStyle.defaultCloseAnimationDuration,
  );

  final panelStyle = CorePopoverStyle.defaultPanelStyle.merge(
    merged.panelStyle,
  );

  return ResolvedPopover(
    placementOffset: placementOffset,
    viewportMargin: viewportMargin,
    openAnimationDuration: openDuration,
    closeAnimationDuration: closeDuration,
    triggerSizing: triggerSizing,
    panelStyle: panelStyle,
    triggerStyle: merged.triggerStyle,
  );
}

/// Resolves the material used by the popover panel's morph transition.
///
/// Includes popup-theme defaults and the panel's explicit material override,
/// matching the panel chrome even when the surrounding page is opaque. Returns
/// null for internal overlays mounted without a CoUI theme.
@internal
ThemeData? resolvePopoverPanelTheme(
  BuildContext context,
  CorePopupStyle? panelStyle,
) {
  final theme = Theme.maybeOf(context);
  if (theme == null) return null;
  final merged = resolveStyleChain(const CorePopupStyle(), [
    theme.coreComponentTheme?.popup?.style,
    panelStyle,
  ]);
  return resolveSurfaceTheme(context, merged.surfaceStyle);
}
