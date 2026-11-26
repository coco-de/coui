import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `FadeScroll`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // relative overflow-hidden wrapper
///   ├─ <style>                              // co_fade_scroll renders only when showScrollbar = false
///   └─ viewport (<div>)                     // axis-specific overflow + mask-image fade
///        └─ child                           // caller-supplied Component
/// ```
///
/// `co_fade_scroll.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion in
/// the widget body. The scoped `<style>` element (its content depends on
/// the runtime-generated viewport id) is composed in `co_fade_scroll`.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
///
/// There are no nested `CoreXxxStyle` slots — no child unified widget
/// renders inside the fade-scroll DOM tree (the caller-supplied `child`
/// is inserted as-is). No scalar metadata is exposed — the resolved
/// gradient stops and offsets are baked into the viewport `mask-image`
/// inline style inside the resolver.
class ResolvedFadeScroll implements WebResolvedChrome {
  /// Creates a [ResolvedFadeScroll].
  const ResolvedFadeScroll({required this.root, required this.viewport});

  /// Paint-ready chrome for the outer wrapper `<div>` — `relative
  /// overflow-hidden h-full w-full min-w-0` className. No inline-style
  /// chrome.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the inner scroll viewport `<div>` —
  /// axis-specific overflow className plus the `mask-image` /
  /// `scrollbar-width` inline CSS bundle.
  ///
  /// `mask-image` mixes the resolved gradient stops with runtime edge
  /// progress. Native scroll timelines select a live private carrier;
  /// unsupported engines retain the original `--co-fade-start-alpha` /
  /// `--co-fade-end-alpha` fallback as the viewport approaches a boundary.
  final WebElementChrome viewport;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedFadeScroll] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.fadeScroll.style
///   → widget.fadeScrollStyle
/// ```
ResolvedFadeScroll resolveFadeScroll(
  BuildContext context, {
  required CoreFadeScrollDirection direction,
  required bool showScrollbar,
  CoreFadeScrollStyle? fadeScrollStyle,
}) {
  final fadeScrollTheme = context.theme.coreComponentTheme?.fadeScroll;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFadeScrollStyle(), [
    fadeScrollTheme?.style,
    fadeScrollStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final startOffset =
      merged.startOffset ?? CoreFadeScrollStyle.defaultStartOffset;
  final endOffset = merged.endOffset ?? CoreFadeScrollStyle.defaultEndOffset;
  final gradient = merged.gradient ?? CoreFadeScrollStyle.defaultGradient;
  final startColorCss = gradient.first.toValue();
  final endColorCss = gradient.last.toValue();

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer wrapper `<div>` Tailwind className —
  /// `position: relative; overflow: hidden` so the inner scroll
  /// viewport can apply a `mask-image` without affecting adjacent
  /// layout. `w-full` is required when the wrapper is rendered inside
  /// a flex container — otherwise flex sizing defers to the child's
  /// intrinsic width.
  String buildRootClassName() =>
      '${WebLayout.relative} ${WebLayout.overflowHidden} '
      '${WebLayout.hFull} ${WebLayout.wFull} ${WebLayout.minWZero}';

  /// Composes the inner scrollable viewport `<div>` Tailwind className
  /// — axis-specific overflow (vertical → `overflow-y-auto
  /// overflow-x-hidden`; horizontal → `overflow-x-auto
  /// overflow-y-hidden`).
  String buildViewportClassName() => switch (direction) {
    .vertical =>
      '${WebLayout.hFull} ${WebLayout.overflowYAuto} '
          '${WebLayout.overflowXHidden}',
    .horizontal =>
      '${WebLayout.wFull} ${WebLayout.overflowXAuto} '
          '${WebLayout.overflowYHidden}',
  };

  /// Composes the inner scrollable viewport `<div>` inline CSS —
  /// emits the `mask-image` gradient + edge-alpha CSS variables.
  ///
  /// The gradient stops use `calc(1 - var(--co-fade-*-alpha, …))` so
  /// that when the `FadeScrollMeasurer` writes `0` (boundary reached)
  /// the edge becomes opaque (no fade) and when it writes `1` (away
  /// from boundary) the edge becomes transparent (full fade ramp).
  ///
  /// Until the measurer runs, the fallbacks draw the viewport at rest the
  /// way Flutter's settled `FadeScroll` draws it: a viewport always first
  /// paints at its start, so the leading edge does not fade (`0`), and the
  /// trailing edge fades (`1`) — the state of a viewport whose content
  /// runs past its end, which is what a fade scroll is for. Content that
  /// fits loses that trailing fade as soon as the measurer reads it.
  Styles buildViewportInlineStyles() {
    final isHorizontal = direction == .horizontal;
    final axis = isHorizontal ? 'right' : 'bottom';
    final start =
        'color-mix(in srgb, $startColorCss '
        'calc((1 - var(--co-fade-start-alpha, 0)) * 100%), transparent)';
    final end =
        'color-mix(in srgb, $endColorCss '
        'calc((1 - var(--co-fade-end-alpha, 1)) * 100%), transparent)';
    final opaqueStop = startColorCss;
    final gradientCss =
        'linear-gradient(to $axis,'
        ' $start 0,'
        ' $opaqueStop ${startOffset}px,'
        ' $opaqueStop calc(100% - ${endOffset}px),'
        ' $end 100%)';
    // Keep the legacy expression above as the SSR/unsupported fallback. The
    // native timeline path selects this live carrier at runtime, so rebuilt
    // Core gradients and animated progress are resolved outside keyframes.
    final timelineStart =
        'color-mix(in srgb, $startColorCss '
        'calc((1 - var(--co-fade-timeline-start, 0)) * 100%), $endColorCss)';
    final timelineEnd =
        'color-mix(in srgb, $startColorCss '
        'calc((1 - var(--co-fade-timeline-end, 1)) * 100%), $endColorCss)';
    final timelineGradient =
        'linear-gradient(to $axis,'
        ' $timelineStart 0,'
        ' $opaqueStop ${startOffset}px,'
        ' $opaqueStop calc(100% - ${endOffset}px),'
        ' $timelineEnd 100%)';
    final mask =
        'var(--co-fade-timeline-mask, '
        'var(--co-fade-timeline-gradient, $gradientCss))';
    return Styles(
      raw: {
        '--co-fade-scroll-gradient': timelineGradient,
        '-webkit-mask-image': mask,
        'mask-image': mask,
        if (!showScrollbar) 'scrollbar-width': 'none',
        if (!showScrollbar) '-ms-overflow-style': 'none',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedFadeScroll(
    root: WebElementChrome(className: buildRootClassName()),
    viewport: WebElementChrome(
      className: buildViewportClassName(),
      inlineStyles: buildViewportInlineStyles(),
    ),
  );
}
