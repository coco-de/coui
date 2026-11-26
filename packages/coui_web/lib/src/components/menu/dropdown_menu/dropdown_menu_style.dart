/// Style-slot single entry point for the Web `DropdownMenu`.
///
/// The dropdown panel composes the unified `Menu` (box + rows + dividers +
/// shortcuts all resolve inside `Menu`), so this resolver produces the
/// host-overlay chrome (outer scope wrapper, trigger wrapper, panel
/// positioning wrapper, panel animation durations) and raw-forwards the
/// merged [CoreMenuStyle] to the inner `Menu`. The placement gap flows
/// through [resolveDropdownMenuConfig].
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedDropdownMenu
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `DropdownMenu`.
///
/// DOM shape:
///
/// ```text
/// root (<div relative inline-block>)            // outer scope wrapper
///   ├─ trigger (<div role="button" inline-flex>) // user-supplied widget host
///   └─ <div fixed z-10 id=panel>                 // panel positioning wrapper
///        │                                         // (engine measures THIS box;
///        │                                         //  unified OverlayPositioner
///        │                                         //  emits top/left; flip/shift)
///        └─ Menu (<div role="menu">)            // composed Menu (box + rows)
/// ```
///
/// The panel is a composed `Menu`, which owns the box / rows / dividers /
/// shortcuts (its own resolver paints them). This output carries the
/// host-overlay [root] / [trigger] / [panelPosition] [WebElementChrome], the
/// panel [panel] (read for its animation durations), and the merged
/// [menuStyle] raw-forwarded to the inner `Menu`.
class ResolvedDropdownMenu implements WebResolvedChrome {
  /// Creates a [ResolvedDropdownMenu].
  const ResolvedDropdownMenu({
    required this.root,
    required this.trigger,
    required this.panelPosition,
    required this.panel,
    required this.menuStyle,
  });

  /// Paint-ready chrome for the outer `<div>` scope wrapper —
  /// `relative inline-block` so the panel can be positioned beneath
  /// the trigger without overflowing.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the trigger `<div role="button">` wrapper
  /// hosting the user-supplied widget.
  final WebElementChrome trigger;

  /// Paint-ready chrome for the panel positioning wrapper
  /// `<div fixed z-10>` — the stable, scale-free layout box the unified
  /// `OverlayPositioner` measures and positions. `inlineStyles` carries
  /// the flip/shift-resolved viewport-space `(top, left)` origin (rem)
  /// fed back declaratively from the positioner's `onPosition`.
  final WebElementChrome panelPosition;

  /// Resolved popup-panel chrome — read only for its open / close
  /// animation durations (the composed `Menu` paints the actual box).
  final ResolvedPopup panel;

  /// Merged [CoreMenuStyle] (`CoreMenuTheme.style` ←
  /// `CoreDropdownMenuTheme.style.menuStyle` ← `component.dropdownMenuStyle
  /// .menuStyle`) raw-forwarded to the composed `Menu`'s `menuStyle` slot;
  /// `null` leaves the inner `Menu` at its design-system defaults.
  final CoreMenuStyle? menuStyle;
}

// ════════════════════════════════════════════════════════════════
// resolveDropdownMenu — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedDropdownMenu] for the given [context].
///
/// Folds `CoreDropdownMenuTheme.style` over the design-system defaults and
/// the per-instance [dropdownMenuStyle]; the panel chrome delegates to
/// `resolvePopup` on the merged [CoreMenuStyle.popupStyle] (for the
/// animation durations). [left] / [top] are the flip/shift-resolved
/// viewport-space origin reported by the unified `OverlayPositioner`
/// (`onPosition`), baked into [ResolvedDropdownMenu.panelPosition].
ResolvedDropdownMenu resolveDropdownMenu(
  BuildContext context, {
  CoreDropdownMenuStyle? dropdownMenuStyle,
  double? left,
  double? top,
}) {
  // ─── Merge chain ──────────────────────────────────────
  final menuTheme = context.theme.coreComponentTheme?.dropdownMenu;
  final merged = resolveStyleChain(const CoreDropdownMenuStyle(), [
    menuTheme?.style,
    dropdownMenuStyle,
  ]);

  // Panel durations come from the forwarded menu panel style (the inner
  // `Menu` paints the box; this only needs the open/close durations).
  final panel = resolvePopup(
    context,
    direction: .vertical,
    popupStyle: merged.menuStyle?.popupStyle,
  );

  /// Composes the outer `<div>` scope wrapper Tailwind className —
  /// `relative inline-block` so the panel can be absolutely positioned
  /// beneath the trigger without overflowing the surrounding layout.
  String buildRootClassName() => WebLayout.relativeInlineBlock;

  /// Composes the trigger `<div role="button">` Tailwind className —
  /// `inline-flex cursor-pointer` so the user-supplied widget hosts
  /// click without extra layout chrome.
  String buildTriggerClassName() => '${WebLayout.inlineFlex} cursor-pointer';

  /// Composes the panel positioning wrapper `<div>` className —
  /// `fixed z-${CoreZIndex.scale.z10}` (dropdown-menu layer) stacks it
  /// above ordinary in-flow content. The
  /// mounted-but-unplaced flash is suppressed by the INNER motion box's
  /// closed-state `opacity-0` + `pointer-events-none`, so no `invisible`
  /// is needed here.
  String buildPanelPositionClassName() =>
      '${WebLayout.fixed} z-${CoreZIndex.scale.z10}';

  /// Composes the panel positioning wrapper inline-CSS bundle — the
  /// flip/shift-resolved viewport-space `(top, left)` origin (rem)
  /// reported by the `OverlayPositioner`. Returns `null` until the first
  /// frame resolves the position.
  Styles? buildPanelPositionInlineStyles() {
    if (left == null || top == null) return null;
    return Styles(
      raw: {
        'top': '${top / kRemDivisor}rem',
        'left': '${left / kRemDivisor}rem',
      },
    );
  }

  // Menu slot — the design-system partial (which diverges from `Menu`'s own
  // chrome in nothing) with the merged per-instance slot folded on, then
  // raw-forwarded. `Menu`'s resolver still fills every field neither side
  // set, so this stays a partial and never a copy of `Menu`'s defaults.
  final menuStyle = CoreDropdownMenuStyle.defaultMenuStyle.merge(
    merged.menuStyle,
  );

  return ResolvedDropdownMenu(
    root: WebElementChrome(className: buildRootClassName()),
    trigger: WebElementChrome(className: buildTriggerClassName()),
    panelPosition: WebElementChrome(
      className: buildPanelPositionClassName(),
      inlineStyles: buildPanelPositionInlineStyles(),
    ),
    panel: panel,
    menuStyle: menuStyle,
  );
}

// ════════════════════════════════════════════════════════════════
// resolveDropdownMenuConfig — OverlayPositioner inputs
// ════════════════════════════════════════════════════════════════

/// Resolves the `OverlayPositioner` inputs for the dropdown panel — the
/// fixed [CorePopoverStyle.defaultDropdownPlacement] placement (the panel
/// opens below the trigger, start-aligned) and the trigger↔panel gap (the
/// merged `menuOffset` override, falling back to the design-system
/// default). Mirrors `resolveMenubarConfig` so the gap flows through the
/// style chain (user-overridable via `CoreDropdownMenuTheme.style.menuOffset`)
/// instead of a hardcoded token; the engine's default collision policy
/// ({flip, shift}) keeps the panel inside the viewport.
({CorePopoverPlacement placement, double gap}) resolveDropdownMenuConfig(
  BuildContext context, {
  CoreDropdownMenuStyle? dropdownMenuStyle,
}) {
  final merged = resolveStyleChain(const CoreDropdownMenuStyle(), [
    context.theme.coreComponentTheme?.dropdownMenu?.style,
    dropdownMenuStyle,
  ]);
  final gap = merged.menuOffset ?? CoreDropdownMenuStyle.defaultMenuOffset;
  // guard-nested-override: dropdownPlacement — a fixed positioning default (the
  // dropdown opens bottomStart by design; OverlayPositioner flips on collision),
  // consumed as a plain OverlayPositioner-config value, not overridable chrome.
  return (placement: CorePopoverStyle.defaultDropdownPlacement, gap: gap);
}
