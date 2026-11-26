/// Style-slot single entry point for the Web `Popover`.
///
/// Mirrors the Flutter `popover_style.dart`: a `resolvePopover`
/// merge function that walks the nested merge chain
/// (`CorePopoverStyle.defaultX` → `theme.popover.style` →
/// `widget.popoverStyle`) and ships back a [ResolvedPopover] chrome
/// bundle. Every per-state slot — the panel position + anchor-relative
/// constraint, the inner bubble chrome, and the modal-mode backdrop —
/// folds into the bundle's `panel` / `bubble` / `backdrop` slots. The
/// open/close motion is not resolved here: `co_popover.dart` wraps the
/// bubble in a motion box driven by the shared `resolveOverlayMotion`
/// (`co-overlay-*` keyframes — the single Web overlay-motion source,
/// shared with the menu family). Positioning is owned by the unified
/// `OverlayPositioner`, which reports the flip/shift-resolved
/// `(left, top)` origin and the trigger rect declaratively; that runtime
/// state (`left` / `top` / anchor `width`/`height` / `widthConstraint` /
/// `heightConstraint`) flows in as resolver args so the `co_popover.dart`
/// build only reads `chrome.X.className / inlineStyles` and never
/// composes className / inline-CSS itself. The `OverlayPositioner` gap +
/// viewport padding are sourced via [resolvePopoverConfig].
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ════════════════════════════════════════════════════════════════
// ResolvedPopover — slot-only chrome bundle
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Popover`.
///
/// DOM shape:
///
/// ```text
/// root (<div scope inline-block>)              // gesture / a11y host
///   ├─ trigger (<div inline-flex|flex w-full>) // anchor wrapper
///   ├─ backdrop (<div fixed inset-0 z-40>)?    // rendered only when modal (overlay-backdrop layer)
///   └─ panel outer (<div fixed z-60>)?         // viewport-fixed placement (popover layer)
///        └─ panel inner / bubble (<div motion>)// chrome + open-state motion
/// ```
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome): `root` /
///   `trigger` / `panel` / `bubble` / `backdrop`.
/// * Cat 2 — the fully-merged [CorePopoverStyle] slot ([style]) whose
///   every field is non-null after the design-system default fallback.
///   `co_popover` reads the resolved layout / animation behaviour
///   (`placementOffset` / `openAnimationDuration` /
///   `closeAnimationDuration` / `triggerSizing`) plus the nested
///   `triggerStyle` off it — no raw scalar / meta fields leak onto the
///   resolved bundle.
///
/// All slot chromes are non-null. `co_popover` decides which optional
/// slots actually render based on `_isOpen` / `modal`.
class ResolvedPopover implements WebResolvedChrome {
  /// Creates a [ResolvedPopover].
  const ResolvedPopover({
    required this.root,
    required this.trigger,
    required this.panel,
    required this.bubble,
    required this.backdrop,
    required this.style,
  });

  /// Paint-ready chrome for the outermost wrapper `<div scope inline-
  /// block>` — the component returns this as its top-level element.
  /// Hosts the `_scopeId` id used by outside-click detection.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the trigger anchor `<div>` — branched
  /// once between `inline-flex` (intrinsic sizing) and `flex w-full`
  /// (expand sizing) so the runtime read is a single field access.
  final WebElementChrome trigger;

  /// Paint-ready chrome for the panel outer `<div fixed z-60>`
  /// (popover layer) — viewport-fixed placement (`top` / `left`, no
  /// self-translate) from the
  /// engine-resolved `left` / `top` args, plus the anchor-driven `width` /
  /// `height` constraints. `inlineStyles` is `null` until the first frame
  /// resolves the position (and there are no constraint declarations).
  /// Carries `id: _panelId` so the `OverlayPositioner` measures this
  /// stable, scale-free layout box rather than the scale-animated inner
  /// bubble.
  final WebElementChrome panel;

  /// Paint-ready chrome for the inner bubble (`<div>`) — the composed
  /// `Popup` box chrome (background / border / radius / padding / shadow)
  /// only. The open/close motion is **not** here: `co_popover` wraps this
  /// in a motion box driven by the shared `resolveOverlayMotion`
  /// (`co-overlay-enter` / `co-overlay-exit` keyframes), the single Web
  /// overlay-motion source shared with the menu family.
  final WebElementChrome bubble;

  /// Paint-ready chrome for the modal-mode backdrop
  /// (`<div fixed inset-0 z-40 bg-transparent>`). Always non-null —
  /// `co_popover` renders it only when `modal == true`.
  final WebElementChrome backdrop;

  /// Fully-merged [CorePopoverStyle] — every layout / animation field
  /// non-null after the design-system default fallback. `co_popover`
  /// reads `placementOffset` (collision calc),
  /// `openAnimationDuration` / `closeAnimationDuration` (enter/exit
  /// timing), `triggerSizing`, and the nested `triggerStyle` (piped
  /// into `Button(buttonStyle: …)`) off this slot so no raw scalar /
  /// meta field leaks onto the resolved bundle (Epic #1603 옵션 B
  /// 최종).
  final CorePopoverStyle style;
}

// ════════════════════════════════════════════════════════════════
// resolvePopover — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedPopover] for the given [context].
///
/// Walks the nested-merge chain (Epic #1302):
///
/// ```text
/// design system default for popover
///   → theme.coreComponentTheme.popover.style
///   → component.popoverStyle
/// ```
///
/// Runtime state (the engine-resolved `left` / `top` origin, anchor
/// `width`/`height`, `widthConstraint` / `heightConstraint`) flows in as
/// resolver args so the `panel` + `bubble` + `backdrop` slots ship
/// paint-ready alongside `root` / `trigger`. The open/close motion is not
/// resolved here — `co_popover` applies the shared `resolveOverlayMotion`
/// (keyframes) to a motion box wrapping the bubble, reading the durations
/// off [ResolvedPopover.style]. The `OverlayPositioner` gap + viewport
/// padding are sourced separately via [resolvePopoverConfig].
ResolvedPopover resolvePopover(
  BuildContext context, {
  double? left,
  double? top,
  double? anchorWidth,
  double? anchorHeight,
  CorePopoverConstraint widthConstraint = .flexible,
  CorePopoverConstraint heightConstraint = .flexible,
  CorePopoverStyle? popoverStyle,
}) {
  final popoverTheme = context.theme.coreComponentTheme?.popover;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CorePopoverStyle(), [
    popoverTheme?.style,
    popoverStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final placementOffset =
      merged.placementOffset ?? CorePopoverStyle.defaultPlacementOffset;
  final viewportPadding =
      merged.viewportPadding ?? CorePopoverStyle.defaultViewportPadding;

  // ─── Bubble box chrome — composed `Popup` (single source) ──
  // The popover bubble box is a `Popup`: run its resolver on the merged
  // panel style (popover-divergent `defaultPanelStyle` ← per-instance
  // override) so the box bg / border / radius / padding / shadow / content
  // colour emit lives in one place — not re-implemented by reaching into
  // `CorePopupStyle.defaultX` field-by-field. The bubble overlays only the
  // open/close scale + opacity animation on top of `popupChrome.root`,
  // matching the Flutter `Popover` (which composes the `Popup` widget:
  // clip + column + chrome).
  final popupChrome = resolvePopup(
    context,
    direction: .vertical,
    popupStyle: CorePopoverStyle.defaultPanelStyle.merge(merged.panelStyle),
  );
  final triggerSizing =
      merged.triggerSizing ?? CorePopoverStyle.defaultTriggerSizing;

  final openDuration =
      merged.openAnimationDuration ??
      CorePopoverStyle.defaultOpenAnimationDuration;
  final closeDuration =
      merged.closeAnimationDuration ??
      CorePopoverStyle.defaultCloseAnimationDuration;

  // Fully-filled style forwarded to `co_popover` (Cat 2) so the widget
  // reads layout / animation behaviour off a single non-null slot. The
  // bubble box is the fully-resolved `CorePopupStyle` the popup resolver
  // already produced (`popupChrome.style`) — no second hand-built copy.
  final resolvedStyle = CorePopoverStyle(
    panelStyle: popupChrome.style,
    placementOffset: placementOffset,
    viewportPadding: viewportPadding,
    triggerSizing: triggerSizing,
    openAnimationDuration: openDuration,
    closeAnimationDuration: closeDuration,
    triggerStyle: merged.triggerStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer scope `<div>` Tailwind className — the
  /// container hosts the trigger + the floating panel as siblings.
  ///
  /// The scope follows the resolved [CorePopoverTriggerSizing]: with
  /// `expand` it must be block-level `w-full`, otherwise the default
  /// `inline-block` shrink-wraps to the trigger's intrinsic width and the
  /// trigger wrapper's own `w-full` resolves against that shrink-wrapped
  /// box — silently defeating `expand` (full-width input triggers like
  /// DatePicker / PhoneInput stayed intrinsic-width).
  String buildRootClassName() => triggerSizing == .expand
      ? '${WebLayout.relative} ${WebLayout.wFull}'
      : WebLayout.relativeInlineBlock;

  /// Composes the trigger anchor `<div>` Tailwind className.
  ///
  /// Trigger wrapper sizing follows the resolved
  /// [CorePopoverTriggerSizing] (mirrors `CoreCardSizing` design):
  ///
  ///   - `intrinsic` (default): `inline-flex` — wrapper sizes to
  ///     trigger content. Right for inline triggers (color swatch,
  ///     icon button) where the popover anchors a small element.
  ///   - `expand`: `flex w-full` — wrapper fills the parent's
  ///     inline axis. Right for form-style triggers (DatePicker,
  ///     Select) that act as full-width input fields.
  ///
  /// Either way the wrapper owns the event listeners + ARIA
  /// attributes and is the anchor for `getBoundingClientRect()`.
  ///
  /// `inline-flex` (vs `inline-block`) — `inline-block` joins the
  /// surrounding line box and inherits the line-height descender,
  /// which inflates the wrapper's bounding rect a few px below the
  /// visible content. That extra strip would push the panel's
  /// `top: trigger.bottom + placementOffset` down by the descender
  /// height, visibly widening the trigger ↔ panel gap.
  ///
  /// `align-top` — the wrapper sits in the scope's line box, which is an
  /// inline formatting context with the surrounding body line height as its
  /// strut. On the baseline, a trigger with no text of its own (an empty
  /// swatch) has its baseline on its bottom edge and the strut's descent
  /// hangs below it, so the scope came out a few px taller than the trigger.
  /// Top-aligned, the line box is exactly the trigger's height.
  String buildTriggerClassName() => triggerSizing == .expand
      ? WebLayout.flexFull
      : WebLayout.inlineFlexAlignTop;

  /// Composes the panel wrapper `<div>` Tailwind className — viewport-
  /// fixed stacking context above ordinary in-flow content.
  String buildPanelClassName() =>
      '${WebLayout.fixed} z-${CoreZIndex.scale.z60}';

  /// Resolves the constraint policy into width / height inline
  /// declarations. Returns an empty map when both axes use `flexible`
  /// or `intrinsic`.
  Map<String, String> buildConstraintStyles() {
    final raw = <String, String>{};
    final aw = anchorWidth;
    final ah = anchorHeight;
    if (aw != null) {
      final width = '${aw / kRemDivisor}rem';
      switch (widthConstraint) {
        case .anchorFixedSize:
          raw['width'] = width;
        case .anchorMaxSize:
          raw['max-width'] = width;
        case .anchorMinSize:
          raw['min-width'] = width;
        case .flexible || .intrinsic:
          break;
      }
    }
    if (ah != null) {
      final height = '${ah / kRemDivisor}rem';
      switch (heightConstraint) {
        case .anchorFixedSize:
          raw['height'] = height;
        case .anchorMaxSize:
          raw['max-height'] = height;
        case .anchorMinSize:
          raw['min-height'] = height;
        case .flexible || .intrinsic:
          break;
      }
    }
    return raw;
  }

  /// Composes the panel wrapper inline-CSS bundle — the flip/shift-
  /// resolved viewport-space `(left, top)` origin computed by the unified
  /// `OverlayPositioner` (positioner + collision) and fed back into the
  /// component's state declaratively, plus the anchor-driven `width` /
  /// `height` constraints. No `transform`: the positioner returns the
  /// panel's final top-left, so the panel is placed by `top` / `left`
  /// alone (the inner bubble owns the scale-motion transform). Returns
  /// `null` until the first frame resolves the position **and** there are
  /// no constraint declarations (the constraints can apply on their own
  /// once `onAnchorMeasured` reports the trigger size).
  Styles? buildPanelInlineStyles() {
    final constraintRaw = buildConstraintStyles();
    final l = left;
    final t = top;
    if (l == null || t == null) {
      return constraintRaw.isEmpty ? null : Styles(raw: constraintRaw);
    }
    return Styles(
      raw: {
        'top': '${t / kRemDivisor}rem',
        'left': '${l / kRemDivisor}rem',
        ...constraintRaw,
      },
    );
  }

  /// Composes the bubble `<div>` Tailwind className — the composed
  /// `Popup` box chrome (`popupChrome.root.className`: flex column, clip,
  /// background / border / foreground token classes) + `outline-none`. The
  /// open/close motion is **not** here — `co_popover` wraps this bubble in
  /// a motion box driven by the shared `resolveOverlayMotion` keyframes
  /// (the single Web overlay-motion source, shared with the menu family).
  String buildBubbleClassName() {
    return [
      popupChrome.root.className,
      'outline-none',
    ].where((c) => c.isNotEmpty).join(' ');
  }

  /// Composes the bubble `<div>` inline-CSS bundle — the composed `Popup`
  /// box inline chrome (`popupChrome.root.inlineStyles`: border / radius /
  /// shadow / padding / min-width + any raw colour overrides). No motion
  /// CSS (see [buildBubbleClassName]).
  Styles? buildBubbleInlineStyles() => popupChrome.root.inlineStyles;

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedPopover(
    root: WebElementChrome(className: buildRootClassName()),
    trigger: WebElementChrome(className: buildTriggerClassName()),
    panel: WebElementChrome(
      className: buildPanelClassName(),
      inlineStyles: buildPanelInlineStyles(),
    ),
    bubble: WebElementChrome(
      className: buildBubbleClassName(),
      inlineStyles: buildBubbleInlineStyles(),
    ),
    backdrop: WebElementChrome(
      // `CoreZIndex.z40` (overlay backdrops) sits one named rung below
      // the popover panel's `z60` (popovers) — see `CoreZIndex`'s doc
      // comment for the full page-level ladder.
      className:
          '${WebLayout.fixed} ${WebLayout.insetZero} '
          'z-${CoreZIndex.scale.z40} bg-transparent',
    ),
    style: resolvedStyle,
  );
}

/// Resolves the `OverlayPositioner` inputs that the popover's preferred
/// [CorePopoverPlacement] does not already carry: the trigger↔panel
/// `gap` (the merged `placementOffset` override, falling back to the
/// design-system default), the `viewportPadding` used by the shift
/// collision math, and the resolved [collision] set (the caller's
/// `component.collision` override falling back to
/// `CorePopoverStyle.defaultCollision`). Walks the same nested-merge
/// chain as [resolvePopover] so the engine and the chrome read one
/// source of truth — the widget never re-applies a `?? default` fallback
/// itself. The placement itself flows straight from `component.placement`
/// (a semantic identifier prop), so it is not re-derived here.
///
/// The viewport padding is spacing — the Flutter twin's inset conversion
/// moves it with the theme density — but the engine reads it as a number in
/// its collision math, where no spacing variable can reach. So it is moved
/// here, by the [density] the document carries when the panel opens (the
/// popover reads it at that moment, and a density switched while closed is
/// the one the next open sees). The trigger↔panel gap is a position offset
/// and stays as stated, as on Flutter.
({
  double gap,
  CoreEdgeInsets viewportPadding,
  Set<CorePopoverCollision> collision,
})
resolvePopoverConfig(
  BuildContext context, {
  Set<CorePopoverCollision>? collision,
  CoreDensity density = CoreDensity.defaultDensity,
  CorePopoverStyle? popoverStyle,
}) {
  final merged = resolveStyleChain(const CorePopoverStyle(), [
    context.theme.coreComponentTheme?.popover?.style,
    popoverStyle,
  ]);
  final gap = merged.placementOffset ?? CorePopoverStyle.defaultPlacementOffset;
  final viewportPadding = const CoreSurfaceGeometryConstraint()
      .atDensity(density)
      .insets(
        merged.viewportPadding ?? CorePopoverStyle.defaultViewportPadding,
      );
  // guard-nested-override: collision — `collision` is a CorePopoverContract
  // semantic/behavior prop (not a CorePopoverStyle chrome field); the override
  // reaches via the resolver arg (component.collision), not merged.collision.
  final resolvedCollision = collision ?? CorePopoverStyle.defaultCollision;
  return (
    gap: gap,
    viewportPadding: viewportPadding,
    collision: resolvedCollision,
  );
}
