import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `HoverCard`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                  // outer wrapper (id only)
///   ├─ trigger (<div inline-flex>)              // hover anchor — id + events
///   └─ panel (<div fixed z-60>)                 // viewport-fixed placement (popover layer)
///        └─ motion (<div transition-all>)       // enter/exit motion host
///             └─ bubble (<div>)                 // composed `Popup` box chrome
/// ```
///
/// `co_hover_card.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body. All slot chromes are non-null. The widget
/// decides whether to render the `panel` / `motion` / `bubble` slots based
/// on `_isOpen` — chrome resolution itself runs unconditionally so the
/// build path is one straight line of `resolved.X.className /
/// inlineStyles` reads.
///
/// The resolver carries:
/// * Cat A — `WebElementChrome` slots (paint-ready chrome). The `bubble`
///   slot is the composed `Popup`'s own root chrome — the panel box
///   (background / border / radius / padding / shadow / width bounds /
///   content colour) is a single source of truth in `Popup`, run through its
///   resolver on this hover card's merged `panelStyle`, not re-implemented
///   here (the same composition `Popover` makes).
///
/// Timing values (`openDelay` / `closeDelay` / `transitionDuration`) are
/// NOT carried here — they are behavioural identifiers read by the
/// stateful pointer / Timer handlers, not paint chrome, so the widget
/// reads them from the merge chain via [resolveHoverCardTiming] (the
/// number_ticker separate-resolver pattern).
class ResolvedHoverCard implements WebResolvedChrome {
  /// Creates a [ResolvedHoverCard].
  const ResolvedHoverCard({
    required this.root,
    required this.trigger,
    required this.panel,
    required this.motion,
    required this.bubble,
  });

  /// Paint-ready chrome for the outermost wrapper `<div>` — the
  /// component returns this as its top-level element. Carries no chrome
  /// of its own (className/inlineStyles are empty); exists so the
  /// `co_hover_card` build reaches the root the same way every other
  /// Web component does (`resolved.root.className / inlineStyles`).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the trigger (hover anchor) `<div>` — the
  /// element that wraps the user's child + receives mouseenter /
  /// mouseleave events.
  final WebElementChrome trigger;

  /// Paint-ready chrome for the panel outer `<div fixed z-60>` (popover
  /// layer) —
  /// carries the viewport-fixed `top` / `left` origin computed by the
  /// `OverlayPositioner` (flip/shift collision) and fed back via the
  /// resolver `left` / `top` args. No `transform` — the positioner
  /// returns the final top-left. `inlineStyles` is `null` until the
  /// first frame resolves the position.
  final WebElementChrome panel;

  /// Paint-ready chrome for the motion host `<div>` — structural only
  /// (whitespace). The enter/exit motion is **not** here:
  /// `co_hover_card` combines the shared `resolveOverlayMotion`
  /// (`co-overlay-enter` / `co-overlay-exit` keyframes — the single Web
  /// overlay-motion source, shared with `Popover` + the menu family) onto
  /// this slot's structural classes.
  final WebElementChrome motion;

  /// Paint-ready chrome for the inner bubble `<div>` — the composed `Popup`
  /// box chrome (background / border / radius / padding / shadow / width
  /// bounds) only. The open/close motion is not here (see [motion]).
  final WebElementChrome bubble;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedHoverCard] for the given [context].
///
/// Single entry point — reads [CoreHoverCardTheme] from
/// `context.theme.coreComponentTheme` itself so callers never touch
/// `coreComponentTheme` directly. Runtime state (`left` / `top`) flows in
/// as resolver args so the `panel` + `motion` slots ship paint-ready
/// alongside `root` / `trigger`. The open/close motion is not resolved
/// here — `co_hover_card` combines the shared `resolveOverlayMotion`
/// (keyframes) onto the `motion` slot. The flip/shift-resolved
/// `(left, top)` origin is computed by the `OverlayPositioner` and fed
/// back declaratively.
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreHoverCardStyle.default*)
///   → theme.coreComponentTheme.hoverCard.style
///   → widget.hoverCardStyle
/// ```
ResolvedHoverCard resolveHoverCard({
  required BuildContext context,
  double? left,
  double? top,
  CoreHoverCardStyle? hoverCardStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.hoverCard;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreHoverCardStyle(), [
    coreTheme?.style,
    hoverCardStyle,
  ]);

  // ─── Bubble box chrome — composed `Popup` (single source) ──
  // The hover-card bubble box is a `Popup`: run its resolver on the merged
  // panel style (the hover card's divergent `defaultPanelStyle` ← per-instance
  // override) so the box bg / border / radius / padding / shadow / width
  // bounds / content colour emit lives in one place — not re-implemented by
  // reaching into `CorePopupStyle.defaultX` field-by-field. The enter/exit
  // motion is overlaid by `co_hover_card` on top, matching the Flutter
  // `HoverCard` (which composes the `Popup` widget).
  final popupChrome = resolvePopup(
    context,
    direction: .vertical,
    popupStyle: CoreHoverCardStyle.defaultPanelStyle.merge(merged.panelStyle),
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the outer wrapper `<div>` className. Currently empty —
  /// the wrapper is structural-only (groups trigger + panel), it
  /// carries no chrome of its own. Kept as a `WebElementChrome` slot
  /// so `co_hover_card.build` can reach the root uniformly.
  String buildRootClassName() => '';

  /// Composes the trigger anchor `<div>` className.
  ///
  /// `inline-flex` (not `inline-block`) — `inline-block` joins the
  /// surrounding line box and inherits the line-height descender,
  /// which inflates the wrapper's bounding rect a few px below the
  /// visible content. That extra strip would push the panel's
  /// `top: trigger.bottom + placementOffset` down by the descender
  /// height, visibly widening the trigger ↔ panel gap. `inline-flex`
  /// sizes strictly to its child without participating in the text
  /// baseline. The trigger is an interactive affordance (hover opens
  /// the card), so the component owns the pointer cursor and opts its
  /// text out of selection — mirroring the Flutter twin's click
  /// cursor + SelectionContainer.disabled.
  String buildTriggerClassName() =>
      '${WebLayout.inlineFlex} cursor-pointer select-none';

  /// Composes the panel wrapper `<div>` className — viewport-fixed
  /// stacking context above ordinary in-flow content.
  String buildPanelClassName() =>
      '${WebLayout.fixed} z-${CoreZIndex.scale.z60}';

  /// Composes the panel wrapper inline-CSS bundle — the flip/shift-
  /// resolved viewport-space `(left, top)` origin computed by the
  /// `OverlayPositioner` (positioner + collision) and fed back into the
  /// component's state declaratively. No `transform`: the positioner
  /// returns the panel's final top-left, so the panel is placed by
  /// `top` / `left` alone. Returns `null` until the first frame resolves
  /// the position.
  Styles? buildPanelInlineStyles() {
    if (left == null || top == null) return null;
    return Styles(
      raw: {
        'top': '${top / kRemDivisor}rem',
        'left': '${left / kRemDivisor}rem',
      },
    );
  }

  /// Composes the motion wrapper `<div>` Tailwind className — structural
  /// only (whitespace). The enter/exit motion is combined onto this by
  /// `co_hover_card` via the shared `resolveOverlayMotion` keyframes; chrome
  /// (including the width ceiling) is the composed `Popup`'s, see
  /// [buildBubbleClassName].
  String buildMotionClassName() => WebLayout.whitespaceNormal;

  /// Composes the bubble `<div>` Tailwind className — the composed `Popup`
  /// box chrome (`popupChrome.root.className`: flex column, clip, surface
  /// marker, background / border / foreground token classes). The open/close
  /// motion is **not** here — `co_hover_card` wraps this bubble in a motion
  /// box driven by the shared `resolveOverlayMotion` keyframes.
  String buildBubbleClassName() => popupChrome.root.className;

  /// Composes the bubble `<div>` inline-CSS bundle — the composed `Popup`
  /// box inline chrome (`popupChrome.root.inlineStyles`: border / radius /
  /// shadow / padding / min-width / max-width + any raw colour overrides).
  Styles? buildBubbleInlineStyles() => popupChrome.root.inlineStyles;

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedHoverCard(
    root: WebElementChrome(className: buildRootClassName()),
    trigger: WebElementChrome(className: buildTriggerClassName()),
    panel: WebElementChrome(
      className: buildPanelClassName(),
      inlineStyles: buildPanelInlineStyles(),
    ),
    motion: WebElementChrome(className: buildMotionClassName()),
    bubble: WebElementChrome(
      className: buildBubbleClassName(),
      inlineStyles: buildBubbleInlineStyles(),
    ),
  );
}

/// Resolves the `OverlayPositioner` inputs for the hover card — the
/// trigger↔panel gap (the merged `placementOffset` override, falling
/// back to the design-system default). The semantic
/// [CorePopoverPlacement] is handed straight to the positioner by
/// `co_hover_card` (it is already a `CorePopoverPlacement`, so no mapping
/// is needed), and the controller's default collision policy
/// ({flip, shift}) keeps the panel inside the viewport.
({double gap}) resolveHoverCardConfig(
  BuildContext context, {
  CoreHoverCardStyle? hoverCardStyle,
}) {
  final merged = resolveStyleChain(const CoreHoverCardStyle(), [
    context.theme.coreComponentTheme?.hoverCard?.style,
    hoverCardStyle,
  ]);
  final gap =
      merged.placementOffset ?? CoreHoverCardStyle.defaultPlacementOffset;
  return (gap: gap);
}

/// Resolves the behavioural timing for `HoverCard` — the open / close
/// delays and the enter/exit transition duration consumed by the
/// stateful pointer / Timer handlers (between builds), not paint chrome.
///
/// Walks the same merge chain as [resolveHoverCard]
/// (design-system default → `CoreHoverCardTheme.style` →
/// `widget.hoverCardStyle`), with the per-instance widget delay props
/// ([widgetOpenDelay] / [widgetCloseDelay]) taking precedence. Kept as a
/// separate `resolveCo*` entry point so [ResolvedHoverCard] stays pure
/// paint-ready chrome (number_ticker separate-resolver pattern).
({Duration openDelay, Duration closeDelay, Duration transitionDuration})
resolveHoverCardTiming(
  BuildContext context, {
  Duration? widgetOpenDelay,
  Duration? widgetCloseDelay,
  CoreHoverCardStyle? hoverCardStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.hoverCard;
  final merged = resolveStyleChain(const CoreHoverCardStyle(), [
    coreTheme?.style,
    hoverCardStyle,
  ]);
  return (
    openDelay:
        widgetOpenDelay ??
        merged.openDelay ??
        CoreHoverCardStyle.defaultOpenDelay,
    closeDelay:
        widgetCloseDelay ??
        merged.closeDelay ??
        CoreHoverCardStyle.defaultCloseDelay,
    transitionDuration:
        merged.transitionDuration ??
        CoreHoverCardStyle.defaultTransitionDuration,
  );
}
