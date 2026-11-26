library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Hover`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                  // always renders the wrapper
///   └─ child (caller-supplied Component)        // co_hover skips when null
/// ```
///
/// `co_hover.dart` reads `resolved.root.inlineStyles` straight through —
/// no merge / fallback / conversion in the widget body. The chrome
/// captures the effect-specific `transform` / `opacity` / `filter` (brightness /
/// drop-shadow) plus the matching `transition` rule, both driven by the
/// immediate [pointer-inside] state.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only Cat 1
/// (`WebElementChrome` slots). Cat E (behaviour timings) flow through
/// the sibling [resolveHoverTiming] — the widget reads them in the
/// pointer event handler so a live `CoreHoverTheme.style` change is
/// honoured without a rebuild.
class ResolvedHover implements WebResolvedChrome {
  /// Creates a [ResolvedHover].
  const ResolvedHover({required this.root});

  /// Paint-ready chrome for the outermost `<div>` wrapper element —
  /// `display: inline-block` plus the effect-specific `transition` and
  /// the resolved `transform` / `opacity` / `filter` (brightness / drop-shadow).
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedHover] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreHoverStyle.defaultX)
///   → CoreHoverTheme.style
///   → widget.hoverStyle
/// ```
///
/// [effect] is the widget's semantic prop — it threads through to pick
/// the per-state CSS rules here. The theme cannot override it (Epic
/// #1603 옵션 B 최종 — semantic identifiers are widget-only).
///
/// [pointerInside] is the immediate pointer-over state (no timing
/// delay) so the effect reacts the instant the pointer enters —
/// matching the Flutter `Hover` which applies the effect from its
/// `_pointerInside` flag.
ResolvedHover resolveHover(
  BuildContext context, {
  required CoreHoverEffect effect,
  required bool pointerInside,
  CoreHoverStyle? hoverStyle,
}) {
  final hoverTheme = context.theme.coreComponentTheme?.hover;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreHoverStyle(), [
    hoverTheme?.style,
    hoverStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builder
  // below runs from a single source of truth (closure captures these
  // directly).
  final effectDurationMs =
      (merged.effectDuration ?? CoreHoverStyle.defaultEffectDuration)
          .inMilliseconds;
  final scaleUpFactor =
      merged.scaleUpFactor ?? CoreHoverStyle.defaultScaleUpFactor;
  final scaleDownFactor =
      merged.scaleDownFactor ?? CoreHoverStyle.defaultScaleDownFactor;
  final fadeOpacity = merged.fadeOpacity ?? CoreHoverStyle.defaultFadeOpacity;
  final brightenFactor =
      merged.brightenFactor ?? CoreHoverStyle.defaultBrightenFactor;
  final shadowBoxShadow =
      merged.shadowBoxShadow ?? CoreHoverStyle.defaultShadowBoxShadow;
  // Shadow base colour — `merged.shadowBaseColor` override wins, else the
  // design-system default `CoreColor.token(shadow)`. Web emits token
  // names only and the browser resolves `--coui-*` at runtime, so
  // `.toValue()` is called directly (no `scheme.resolve` — that step is a
  // no-op on Web). `.toValue()` emits `rgb(var(--coui-shadow))` for the
  // token or `rgb(...)` for a raw ARGB override. Epic #1603 coverage
  // gate — `shadowBaseColor` is reflected here.
  final shadowBase =
      (merged.shadowBaseColor ?? CoreHoverStyle.defaultShadowBaseColor)
          .toValue();

  // ─── Local builders ───────────────────────────────────
  // Closure captures every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the root `<div>` inline-CSS bundle.
  ///
  /// Always emits `display: inline-block`. For non-`none` effects,
  /// emits the matching `transition` rule plus the resolved active /
  /// idle CSS property the effect animates (`transform` / `opacity` /
  /// `filter` — brightness / drop-shadow).
  Styles buildRootInlineStyles() {
    final raw = {'display': 'inline-block'};
    // Token-routed so the easing and `--coui-duration-*` stay the single
    // source a future systemic override would retime — a literal curve or
    // `${ms}ms` has no variable for that override to reach.
    //
    // The *alias*, not a raw scale key. This named `ease` directly, which
    // is a curve the vocabulary has no name for — so the Flutter twin had
    // nothing to match and defaulted to linear, and the two hovers moved
    // in three different shapes between them. `move` is the alias every
    // other chrome transition in the kit uses, on both platforms.
    final duration = durationMsCss(effectDurationMs);
    final easing = CoreEasing.move.toVarCss();

    switch (effect) {
      case .none:
        break;
      case .scaleUp:
        raw['transition'] = 'transform $duration $easing';
        raw['transform'] = pointerInside ? 'scale($scaleUpFactor)' : 'scale(1)';
      case .scaleDown:
        raw['transition'] = 'transform $duration $easing';
        raw['transform'] = pointerInside
            ? 'scale($scaleDownFactor)'
            : 'scale(1)';
      case .fade:
        raw['transition'] = 'opacity $duration $easing';
        raw['opacity'] = pointerInside ? '$fadeOpacity' : '1';
      case .brighten:
        raw['transition'] = 'filter $duration $easing';
        raw['filter'] = pointerInside
            ? 'brightness($brightenFactor)'
            : 'brightness(1)';
      case .shadow:
        // `filter: drop-shadow()` (not `box-shadow`) so the shadow
        // follows the child's rendered shape — a rounded child (e.g. a
        // `Card`) casts a rounded shadow with no wrapper `border-radius`.
        // `box-shadow` would follow the wrapper's square border-box and
        // show sharp corners behind the rounded child.
        //
        // A stack with an inset layer cannot take that path at all:
        // `drop-shadow()` has no inset, so those layers would simply not
        // be drawn. Falling back to `box-shadow` renders the whole stack
        // on the wrapper's geometry — visibly squarer, but a shadow in
        // the wrong shape is something a reviewer notices, whereas a
        // missing one reads as "that preset just has no hover".
        if (shadowBoxShadow.hasInset) {
          raw['transition'] = 'box-shadow $duration $easing';
          raw['box-shadow'] = pointerInside
              ? emitShadow(shadowBoxShadow, base: shadowBase)
              : 'none';
        } else {
          raw['transition'] = 'filter $duration $easing';
          // Routed through `emitDropShadowFilter` (not
          // `.toDropShadowValue()` directly) so a scale-step stack like
          // the default `CoreShadow.lg` reaches a surface style's
          // `--shadow-*-filter` bend instead of baking the un-bent
          // literal — see that function's doc comment.
          raw['filter'] = pointerInside
              ? emitDropShadowFilter(shadowBoxShadow, base: shadowBase)
              : 'none';
        }
    }

    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedHover(
    root: WebElementChrome(
      className: '',
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

/// Resolves the effective hover-state timings for a `Hover` —
/// Category E (behaviour timings).
///
/// Returns a record of millisecond delays consumed by the stateful
/// `mouseenter` / `mouseleave` Timer handlers (between builds), not paint
/// chrome — kept as a separate `resolveCo*` entry point so
/// [ResolvedHover] stays pure paint-ready chrome (number_ticker
/// separate-resolver pattern, Epic #1603 옵션 B 최종).
///
/// Merge chain (later layer wins, so the widget parameter has the
/// highest precedence):
///
/// ```text
/// design-system default (CoreHoverStyle.defaultX)
///   → CoreHoverTheme.style
///   → widget timing parameters (folded into a CoreHoverStyle layer)
/// ```
///
/// The widget timing parameters are folded into a `CoreHoverStyle`
/// layer so the resolution runs through the same
/// `merged.X ?? CoreHoverStyle.defaultX` surface the chrome path uses —
/// keeping the 1:1:1:1 contract / default / merged mapping intact for
/// the timing fields (Epic #1603 chaining + coverage gates).
({int waitDurationMs, int showDurationMs, int minDurationMs})
resolveHoverTiming({
  required BuildContext context,
  required Duration? waitDuration,
  required Duration? showDuration,
  required Duration? minDuration,
}) {
  final hoverTheme = context.theme.coreComponentTheme?.hover;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreHoverStyle(), [
    hoverTheme?.style,
    CoreHoverStyle(
      waitDuration: waitDuration,
      showDuration: showDuration,
      minDuration: minDuration,
    ),
  ]);

  return (
    waitDurationMs: (merged.waitDuration ?? CoreHoverStyle.defaultWaitDuration)
        .inMilliseconds,
    showDurationMs: (merged.showDuration ?? CoreHoverStyle.defaultShowDuration)
        .inMilliseconds,
    minDurationMs: (merged.minDuration ?? CoreHoverStyle.defaultMinDuration)
        .inMilliseconds,
  );
}
