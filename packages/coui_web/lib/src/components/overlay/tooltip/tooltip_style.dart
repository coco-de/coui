/// Style-slot single entry point for the Web `Tooltip`.
///
/// `resolveTooltip` walks the nested merge chain
/// (`CoreTooltipStyle.defaultX` → `theme.tooltip.style` →
/// `widget.tooltipStyle`) and ships back a [ResolvedTooltip] paint-ready
/// chrome bundle where every slot (root / trigger / label / panel /
/// bubble) is pre-composed as a `WebElementChrome` for the caller's
/// runtime placement + open state.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedTooltip — fully pre-composed chrome
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Tooltip`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                  // outer wrapper (id only)
///   ├─ trigger (<div inline-flex>)              // hover anchor — id + events
///   └─ panel (<div fixed z-70>)                 // placement transform (tooltip layer)
///        └─ bubble (<div role="tooltip">)       // chrome + motion classes
///             └─ label (<span>)                 // rendered only when there
///                                               // is a labelStyle override;
///                                               // wraps the message text or
///                                               // the tooltipChild alike
/// ```
///
/// Every slot ships pre-composed as a `WebElementChrome`. The resolver
/// takes the runtime placement (position + anchor rect) and motion
/// state (didEnter + activeDurationMs) and bakes them into the panel /
/// bubble chrome.
class ResolvedTooltip implements WebResolvedChrome {
  /// Creates a [ResolvedTooltip].
  const ResolvedTooltip({
    required this.root,
    required this.trigger,
    required this.panel,
    required this.bubble,
    required this.tail,
    required this.label,
  });

  /// Paint-ready chrome for the outermost wrapper `<div>` — the
  /// component returns this as its top-level element. Carries no chrome
  /// of its own (className/inlineStyles are empty); exists so the
  /// `co_tooltip` build reaches the root the same way every other Web
  /// component does (`resolved.root.className / inlineStyles`).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the trigger (hover anchor) `<div>` — the
  /// element that wraps the user's child + receives mouseenter /
  /// mouseleave events.
  final WebElementChrome trigger;

  /// Paint-ready chrome for the panel outer wrapper `<div fixed z-70>`
  /// (tooltip layer) — viewport-fixed placement (`top` / `left` /
  /// `transform`) translated from the tooltip's position + anchor rect.
  /// `inlineStyles` is
  /// `null` until the first hover frame populates the anchor rect; the
  /// panel renders with the bubble's `opacity-0` class during that
  /// one-frame window.
  final WebElementChrome panel;

  /// Paint-ready chrome for the bubble (content panel) `<div
  /// role="tooltip">`. Radius / padding always ship inline
  /// (`(merged.X ?? default).toValue()`, single-signature); the
  /// background colour + label typography role / foreground colour route
  /// through the emit family (`emitColor` / `emitTypography`) — token
  /// values stay on Tailwind classes (dark-mode reactive), raw overrides
  /// drop to inline so they win via CSS precedence.
  final WebElementChrome bubble;

  /// Paint-ready chrome for the tail `<div>` — a clip-path triangle
  /// filled with the bubble's own computed background (`inherit`; base
  /// `tailWidth` flush against the bubble, tip protruding `tailHeight`
  /// toward the trigger), absolutely positioned on the flip-resolved
  /// placement side. Rendered inside the bubble, which is
  /// `relative`-positioned for it. Null when either axis resolves to `0`:
  /// the default states no tail, and the widget draws no node for it.
  final WebElementChrome? tail;

  /// Paint-ready chrome for the nested label `<span>` — non-null only
  /// when the merged `labelStyle` carries an explicit scalar / raw
  /// colour overlay (`emitTypography`'s inline bundle), so the inline
  /// rules beat the bubble's Tailwind typography class via CSS
  /// specificity. When null the content renders bare and inherits the
  /// bubble's role + colour class. The wrapper is applied to whichever
  /// content the caller supplied — the `message` text or a
  /// `tooltipChild` — since inherited inline rules stay overridable by
  /// anything the child declares itself.
  final WebElementChrome? label;
}

// ════════════════════════════════════════════════════════════════
// resolveTooltip — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedTooltip] for the given [context] and the runtime
/// placement / motion state.
///
/// Walks the nested-merge chain and applies the
/// `CoreTooltipStyle.defaultX` static const fallback so the entry
/// reads only fully-resolved CSS-ready values:
///
/// ```text
/// CoreTooltipStyle.defaultPanelBackgroundColor / defaultLabelStyle.color
///   / defaultPanelPadding / defaultPanelBorderRadius / defaultPlacementOffset
///   → theme.coreComponentTheme.tooltip.style
///   → widget.tooltipStyle
/// ```
ResolvedTooltip resolveTooltip(
  BuildContext context, {
  required bool didEnter,
  required int activeDurationMs,
  required CorePopoverPlacement placement,
  double? left,
  double? top,
  CoreTooltipStyle? tooltipStyle,
}) {
  final tooltipTheme = context.theme.coreComponentTheme?.tooltip;

  // ─── Stage 1 RESOLVE — merge chain ────────────────────
  final merged = resolveStyleChain(const CoreTooltipStyle(), [
    tooltipTheme?.style,
    tooltipStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Border radius / padding are **always** emitted inline as
  // `(merged.X ?? default).toValue()` — never a radius / padding
  // Tailwind utility class. The default path and the override path share
  // one CSS surface so the resolved chrome reflects
  // `merged.panelBorderRadius` / `merged.panelPadding` directly (Epic
  // #1603 single-signature gate — radius / padding are always-inline).
  final borderRadius =
      (merged.panelBorderRadius ?? CoreTooltipStyle.defaultPanelBorderRadius)
          .toValue();
  final padding = (merged.panelPadding ?? CoreTooltipStyle.defaultPanelPadding)
      .toValue();
  final panelMaxWidth = merged.panelMaxWidth;
  final tailWidth = merged.tailWidth ?? CoreTooltipStyle.defaultTailWidth;
  final tailHeight = merged.tailHeight ?? CoreTooltipStyle.defaultTailHeight;
  final surfaceBlur = merged.surfaceBlur ?? context.theme.surfaceBlur;
  final surfaceOpacity = merged.surfaceOpacity ?? context.theme.surfaceOpacity;

  // ─── Stage 2 EMIT (Web, theme-free) ───────────────────
  // Colour / typography route through the emit family — a single
  // class-XOR-inline decision per design value. Token-bound values
  // (default or token override) emit Tailwind classes so they stay
  // dark-mode reactive via `var(--coui-X)`; raw overrides go inline. No
  // `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `if (override != null)` branches.
  //
  // `surfaceOpacity` is folded into the colour, not applied to the node.
  // Flutter does `bgColor.withValues(alpha: surfaceOpacity)` — the SURFACE
  // goes translucent and the label on top stays opaque. Web used to emit
  // `opacity` on the bubble instead, which dims the element and everything
  // inside it, so the same tooltip read as faded text on Web and crisp text
  // on Flutter. The field is named `surfaceOpacity`; the surface is what it
  // is about. Tailwind carries the alpha in the class itself
  // (`bg-{token}/{pct}`, `CoreColor.tailwindColor`), so this stays on the
  // class path and stays dark-mode reactive.
  final backgroundEmit = emitColor(
    surfaceOpacity == null
        ? merged.panelBackgroundColor
        : (merged.panelBackgroundColor ??
                  CoreTooltipStyle.defaultPanelBackgroundColor)
              .scaleAlpha(surfaceOpacity),
    CoreTooltipStyle.defaultPanelBackgroundColor,
    .background,
  );
  // Label typography — `emitTypography` materialises the `labelSmall`
  // role + foreground colour (`defaultLabelStyle.color = surface`) and
  // any caller overlay in one pass: the role + token-colour go on a
  // `text-{role} text-{colour}` class (on the bubble, inherited by the
  // label `<span>` + any `tooltipChild`), the explicit scalar / raw
  // colour overlay goes inline (on the label `<span>` so it beats the
  // bubble class via CSS specificity).
  final labelEmit = emitTypography(
    merged.labelStyle,
    CoreTooltipStyle.defaultLabelStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer wrapper `<div>` className. Currently empty —
  /// the wrapper is structural-only (groups trigger + panel), it
  /// carries no chrome of its own. Kept as a `WebElementChrome` slot
  /// so `co_tooltip.build` can reach the root uniformly.
  String buildRootClassName() => '';

  /// Composes the trigger anchor `<div>` className.
  ///
  /// `inline-flex` (instead of `inline-block`) — `inline-block` joins
  /// the surrounding line box and inherits the line-height descender,
  /// which inflates the wrapper's bounding rect a few px below the
  /// visible content. That extra strip would push the tooltip's
  /// `top: trigger.bottom + gap` down by the descender height, visibly
  /// widening the trigger ↔ panel gap. `inline-flex` sizes strictly
  /// to its child without participating in the text baseline.
  String buildTriggerClassName() => WebLayout.inlineFlex;

  /// Composes the nested label `<span>` inline-CSS bundle — the
  /// explicit typography overlay (`font-size` / weight / spacing / raw
  /// colour) from [labelEmit] on top of the role class. The role +
  /// token colour stay on the bubble className (inherited by this
  /// `<span>`). `null` when the merged label style is a pure role with
  /// no overlay, so `co_tooltip` falls back to a bare text node.
  Styles? buildLabelInlineStyles() {
    final inline = labelEmit.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the panel wrapper `<div>` className — viewport-fixed
  /// stacking context above ordinary in-flow content.
  String buildPanelClassName() =>
      '${WebLayout.fixed} z-${CoreZIndex.scale.z70}';

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

  /// Composes the bubble `<div role="tooltip">` Tailwind className.
  ///
  /// Radius / padding never appear here — they ship inline (single
  /// signature). Background colour ([backgroundEmit]) + label typography
  /// role / foreground colour ([labelEmit]) come from the emit family:
  /// token-bound values stay on Tailwind classes (dark-mode reactive),
  /// raw overrides contribute an empty class fragment and emit inline.
  String buildBubbleClassName() {
    final classList = [
      // Surface hook — a style preset targets this to give the bubble a
      // material, and forced colours to restore a shadow-drawn boundary.
      ...webSurfaceMarkerFor(CoreSurfaceRole.functional),
      backgroundEmit.className,
      // Label role + token-colour class (inherited by the inner `<span>`
      // and any `tooltipChild`). Empty when the merged label resolves to
      // a raw (token-less) style — then everything goes inline.
      labelEmit.className,
      WebLayout.relative,
      // Single-line unless a width ceiling says otherwise: keeping
      // `nowrap` under a `max-width` would overflow the ceiling instead
      // of wrapping at it, where the Flutter twin wraps.
      if (panelMaxWidth == null) WebLayout.whitespaceNowrap,
      WebLayout.pointerEventsNone,
      // Flutter `FixedTooltipOverlayHandler` uses `Curves.linear` for
      // the open animation; CSS `linear` is the matching keyword. The
      // close path is interval-shaped on Flutter, but with the
      // shortened `transition-duration` the same `linear` keyword
      // produces the right perceptual fade-out.
      'transition-all',
      'ease-linear',
      // Open-state vs closed-state class swap drives the CSS
      // `transition-all` enter / exit. Closed scale matches the
      // Flutter popover collapsed scale (0.9) — Tailwind's `scale-95`
      // (0.95) is too subtle and is visibly different from Flutter's
      // pop-out depth.
      if (didEnter) 'opacity-100 scale-100' else 'opacity-0 scale-90',
    ];

    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the bubble `<div role="tooltip">` inline-CSS bundle.
  ///
  /// Radius / padding are always emitted (single-signature inline); a raw
  /// background-colour override emits inline ([backgroundEmit.inline]);
  /// surface effects + the active transition duration round it out. A
  /// `panelMaxWidth` override adds the `max-width` ceiling here and drops
  /// `whitespace-nowrap` from the className, which is what lets the
  /// content wrap at it. (A raw colour/typography label overlay lands on
  /// the label `<span>`, not here — see [buildLabelInlineStyles].)
  Styles buildBubbleInlineStyles() {
    final raw = {
      'transition-duration': '${activeDurationMs}ms',
      // Always-inline radius / padding — `(merged.X ?? default).toValue()`
      // composed above. Default and override share this one surface.
      'border-radius': borderRadius,
      'padding': padding,
      // Emit-family inline fragment — populated only when the caller
      // passed a raw (token-less) background colour; a token override /
      // default stays on the class above and contributes nothing here.
      ...?backgroundEmit.inline,
    };
    if (panelMaxWidth != null) {
      raw['max-width'] = '${panelMaxWidth / kRemDivisor}rem';
    }
    if (surfaceBlur != null && surfaceBlur > 0) {
      raw['backdrop-filter'] = 'blur(${surfaceBlur.toInt()}px)';
    }
    raw.addAll(
      surfaceFillVar(
        merged.panelBackgroundColor ??
            CoreTooltipStyle.defaultPanelBackgroundColor,
      ),
    );
    return Styles(raw: raw);
  }

  /// Composes the tail `<div>` className. No background class: the
  /// tail inherits the bubble's computed fill (see
  /// [buildTailInlineStyles]).
  String buildTailClassName() => WebLayout.pointerEventsNone;

  /// Composes the tail `<div>` inline-CSS bundle — a clip-path
  /// triangle whose [tailWidth] base sits flush against the bubble
  /// edge facing the trigger and whose tip protrudes [tailHeight]
  /// beyond it, centred on the cross axis. The side derives from the
  /// flip-resolved [placement]; a `0` on either axis collapses it.
  Styles buildTailInlineStyles() {
    // The bubble edge the tail sits on — opposite of the pull side:
    // a panel placed above the trigger points down from its bottom.
    final edge = switch (placement) {
      .top || .topStart || .topEnd => 'bottom',
      .bottom || .bottomStart || .bottomEnd => 'top',
      .left || .leftStart || .leftEnd => 'right',
      .right || .rightStart || .rightEnd => 'left',
    };
    final vertical = edge == 'top' || edge == 'bottom';
    // Along a horizontal edge the base runs along x (div w×h =
    // width×height); along a vertical edge the axes swap.
    final baseCss = '${tailWidth / kRemDivisor}rem';
    final protrusionCss = '${tailHeight / kRemDivisor}rem';
    // The centring pull-back is half the tail's own size, not spacing.
    final centring = pinnedLengthCss(-tailWidth / 2);
    // Triangle tip points away from the bubble toward the trigger.
    final clipPath = switch (edge) {
      'bottom' => 'polygon(0 0, 100% 0, 50% 100%)',
      'top' => 'polygon(50% 0, 100% 100%, 0 100%)',
      'right' => 'polygon(0 0, 100% 50%, 0 100%)',
      _ => 'polygon(100% 0, 100% 100%, 0 50%)',
    };
    return Styles(
      raw: {
        'position': 'absolute',
        'width': vertical ? baseCss : protrusionCss,
        'height': vertical ? protrusionCss : baseCss,
        'clip-path': clipPath,
        edge: '-$protrusionCss',
        if (vertical) ...{
          'left': '50%',
          'margin-left': centring,
        } else ...{
          'top': '50%',
          'margin-top': centring,
        },
        // The bubble's computed fill, not its authored token. A material
        // preset restates the bubble's background at its share, and a
        // tail painted from the token stayed at full strength beside it —
        // the one silhouette in two materials. Inheriting also covers a
        // raw override (inline on the bubble) and the reduced-transparency
        // restore, with nothing restated here.
        'background-color': 'inherit',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  final labelInline = buildLabelInlineStyles();

  return ResolvedTooltip(
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
    tail: tailWidth > 0 && tailHeight > 0
        ? WebElementChrome(
            className: buildTailClassName(),
            inlineStyles: buildTailInlineStyles(),
          )
        : null,
    label: labelInline == null
        ? null
        : WebElementChrome(className: '', inlineStyles: labelInline),
  );
}

// ════════════════════════════════════════════════════════════════
// resolveTooltipTiming — behavior timing config (Category E)
// ════════════════════════════════════════════════════════════════

/// Resolved behavior timings for `Tooltip`. No DOM chrome — widget
/// behavior helper only: the hover-wait, linger and minimum-open timers
/// run between builds, so they cannot ride the paint-ready chrome
/// bundle.
class ResolvedTooltipTiming {
  /// Creates a [ResolvedTooltipTiming].
  const ResolvedTooltipTiming({
    required this.waitDurationMs,
    required this.showDurationMs,
    required this.minDurationMs,
  });

  /// Hover wait before the bubble opens, in milliseconds.
  final int waitDurationMs;

  /// Linger after the cursor leaves before the close starts, in
  /// milliseconds.
  final int showDurationMs;

  /// Floor on the open window measured from cursor arrival, in
  /// milliseconds.
  final int minDurationMs;
}

/// Resolves the hover timings for a `Tooltip` from the caller's
/// per-instance overrides, falling back to the shared
/// `CoreTooltipContract` defaults so the widget never carries a
/// `?? default` of its own.
///
/// Takes no [BuildContext] on purpose: these are behaviour values, not
/// chrome, so they live as `CoreTooltipContract` static consts (the
/// cross-platform single source Flutter reads too) rather than as
/// `CoreTooltipStyle` fields — there is no theme layer to walk. Adding a
/// context parameter would only advertise a merge chain that does not
/// exist.
ResolvedTooltipTiming resolveTooltipTiming({
  Duration? waitDuration,
  Duration? showDuration,
  Duration? minDuration,
}) {
  final waitDurationMs =
      (waitDuration ?? CoreTooltipContract.defaultWaitDuration).inMilliseconds;
  final showDurationMs =
      (showDuration ?? CoreTooltipContract.defaultShowDuration).inMilliseconds;
  final minDurationMs =
      (minDuration ?? CoreTooltipContract.defaultMinDuration).inMilliseconds;

  return ResolvedTooltipTiming(
    waitDurationMs: waitDurationMs,
    showDurationMs: showDurationMs,
    minDurationMs: minDurationMs,
  );
}

/// Resolves the `OverlayPositioner` inputs for the tooltip — the
/// [CorePopoverPlacement] (mapped from the semantic [position], centered
/// on the trigger) and the trigger↔panel gap (the merged
/// `placementOffset` override, falling back to the design-system
/// default). The controller's default collision policy ({flip, shift})
/// keeps the bubble inside the viewport.
({CorePopoverPlacement placement, double gap}) resolveTooltipConfig(
  BuildContext context, {
  required CoreTooltipPosition position,
  CoreTooltipStyle? tooltipStyle,
}) {
  final merged = resolveStyleChain(const CoreTooltipStyle(), [
    context.theme.coreComponentTheme?.tooltip?.style,
    tooltipStyle,
  ]);
  final placement = switch (position) {
    .top => CorePopoverPlacement.top,
    .bottom => CorePopoverPlacement.bottom,
    .left => CorePopoverPlacement.left,
    .right => CorePopoverPlacement.right,
  };
  final gap = merged.placementOffset ?? CoreTooltipStyle.defaultPlacementOffset;
  return (placement: placement, gap: gap);
}
