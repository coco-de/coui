library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ScrollViewInterceptor`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                      // co_scrollview_interceptor wraps the subtree in a transparent <div> so the wrapper id can be measured for nearest-scrollable lookup
///   └─ child                                        // caller-supplied Component, rendered as-is
/// ```
///
/// `co_scrollview_interceptor.dart` reads `resolved.root.className`
/// straight from the resolver — no merge / fallback / conversion in
/// the widget body.
///
/// Runtime tuning (`dragSpeed` / `maxScrollSpeed`) is NOT carried here —
/// those are behavioural identifiers read by the per-frame tick callback
/// (between builds), not paint chrome, so the widget reads them from the
/// merge chain via [resolveScrollViewInterceptorTuning] (the
/// number_ticker separate-resolver pattern).
class ResolvedScrollViewInterceptor implements WebResolvedChrome {
  /// Creates a [ResolvedScrollViewInterceptor].
  const ResolvedScrollViewInterceptor({required this.root});

  /// Paint-ready chrome for the root wrapper `<div>` element. The
  /// className flips to `cursor-all-scroll` while a middle-mouse
  /// hold-scroll gesture is active and is empty otherwise — the
  /// wrapper itself is layout-transparent.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedScrollViewInterceptor] for the given [context].
///
/// The root wrapper carries no design-system chrome — its only
/// paint-ready state is the `cursor-all-scroll` className flip driven by
/// the live [dragging] flag, so no merge chain is walked here. Behavioural
/// tuning flows through [resolveScrollViewInterceptorTuning].
ResolvedScrollViewInterceptor resolveScrollViewInterceptor(
  BuildContext context, {
  required bool dragging,
}) {
  // ─── Local builders ───────────────────────────────────
  // Closure captures `dragging` from the resolver signature — local to
  // the resolver, inaccessible from outside.

  /// Composes the root `<div>` Tailwind className.
  ///
  /// The wrapper is a layout-transparent passthrough — it must not
  /// introduce visual chrome. The `all-scroll` cursor is applied only
  /// while the middle-mouse hold-scroll gesture is active so the
  /// pointer reflects the autoscroll mode.
  String buildRootClassName() {
    return dragging ? 'cursor-all-scroll' : '';
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedScrollViewInterceptor(
    root: WebElementChrome(className: buildRootClassName()),
  );
}

/// Resolves the behavioural auto-scroll tuning for
/// `ScrollViewInterceptor` — the drag-speed multiplier and the maximum
/// scroll velocity cap consumed by the per-frame tick callback (between
/// builds), not paint chrome.
///
/// Walks the same merge chain as [resolveScrollViewInterceptor]
/// (design-system default → `CoreScrollViewInterceptorTheme.style` →
/// `widget.scrollViewInterceptorStyle`). Kept as a separate `resolveCo*`
/// entry point so [ResolvedScrollViewInterceptor] stays pure
/// paint-ready chrome (number_ticker separate-resolver pattern).
({double dragSpeed, double maxScrollSpeed}) resolveScrollViewInterceptorTuning(
  BuildContext context, {
  CoreScrollViewInterceptorStyle? scrollViewInterceptorStyle,
}) {
  final csTheme = context.theme.coreComponentTheme?.scrollViewInterceptor;
  final merged = resolveStyleChain(const CoreScrollViewInterceptorStyle(), [
    csTheme?.style,
    scrollViewInterceptorStyle,
  ]);
  return (
    dragSpeed:
        merged.dragSpeed ?? CoreScrollViewInterceptorStyle.defaultDragSpeed,
    maxScrollSpeed:
        merged.maxScrollSpeed ??
        CoreScrollViewInterceptorStyle.defaultMaxScrollSpeed,
  );
}
