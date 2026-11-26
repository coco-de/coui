import 'dart:math';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `StageContainer`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                       // outer wrapper, observed by ResizeObserver
///   └─ box (<div>)                   // receives the resolved per-axis padding
///        └─ builder(context, padding) child
/// ```
///
/// - `root` carries the outer wrapper's `w-full` className — kept inset-
///   free so the ResizeObserver's content-rect stays equal to the
///   parent's width on every rebuild.
/// - `box` carries the inner wrapper's per-axis padding chrome —
///   `w-full` className plus the `padding` shorthand inline CSS computed
///   from the runtime parent width via the breakpoint redistribution
///   math.
///
/// The runtime `measuredWidth` argument flows into [resolveStageContainer]
/// — the resolver bakes the padding into the box chrome on every build.
/// When `measuredWidth == null` (first frame before the ResizeObserver
/// fires) the resolver falls back to the resolved base padding so the
/// box chrome doesn't render with the fallback for an extra frame.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — [WebElementChrome] slots (paint-ready chrome).
///
/// The effective breakpoint strategy and the resolved per-axis padding
/// value handed to the `builder` callback are NOT exposed here — they
/// are behavioural / composed data consumed by the stateful widget
/// (and its builder callback), not paint chrome. The widget reads the
/// padding off the merge chain via [resolveStageContainerPadding]
/// (the number_ticker separate-resolver pattern). The breakpoint stays
/// internal to the resolver (used only by the redistribution math).
class ResolvedStageContainer implements WebResolvedChrome {
  /// Creates a [ResolvedStageContainer].
  const ResolvedStageContainer({
    required this.root,
    required this.box,
  });

  /// Paint-ready chrome for the outer observed `<div>` (`w-full`, no
  /// inline-style chrome). The ResizeObserver content-rect stays equal
  /// to the parent's width because padding lives on the inner [box].
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the inner `<div>` — `w-full` Tailwind
  /// className plus the `padding` shorthand inline-CSS bundle computed
  /// from the resolved 4-side effective padding.
  final WebElementChrome box;
}

// ═══════════════════════════════════════════════════
// Resolver — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStageContainer] for [StageContainer] — single
/// entry point.
///
/// Priority (per-field): widget value > `widget.stageContainerStyle` >
/// `CoreStageContainerTheme.style` > design-system default.
///
/// [measuredWidth] is the runtime parent width observed via the
/// browser's `ResizeObserver` (CSS pixels). When provided, the
/// resolver runs the breakpoint redistribution math (same equation as
/// the Flutter widget) to expand the per-axis padding so the
/// builder's content stays centred inside the configured breakpoint
/// extents. When `null` (first frame), the resolver falls back to the
/// resolved base padding so the very first paint matches the eventual
/// post-measurement layout instead of jumping.
ResolvedStageContainer resolveStageContainer(
  BuildContext context, {
  CoreStageBreakpoint? breakpoint,
  CoreEdgeInsets? padding,
  double? measuredWidth,
  CoreStageContainerStyle? stageContainerStyle,
}) {
  // ─── Resolved chrome values ───────────────────────────
  // Same merge + breakpoint redistribution that the builder-facing
  // padding resolver runs, so the box chrome and the value handed to
  // the `builder` callback stay byte-identical.
  final effectivePadding = resolveStageContainerPadding(
    context,
    breakpoint: breakpoint,
    padding: padding,
    measuredWidth: measuredWidth,
    stageContainerStyle: stageContainerStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the inner box `<div>` Tailwind className — `w-full`.
  String buildBoxClassName() => WebLayout.wFull;

  /// Composes the inner box `<div>` inline CSS — the `padding`
  /// shorthand emitted from the resolved 4-side `effectivePadding`.
  Styles buildBoxInlineStyles() => .new(
    raw: {
      'padding': effectivePadding.toValue(),
    },
  );

  return ResolvedStageContainer(
    root: const WebElementChrome(className: WebLayout.wFull),
    box: WebElementChrome(
      className: buildBoxClassName(),
      inlineStyles: buildBoxInlineStyles(),
    ),
  );
}

/// Resolves the effective per-axis [CoreEdgeInsets] padding handed to the
/// `StageContainer` `builder` callback — the base padding folded with
/// the breakpoint-driven remaining-width redistribution for the runtime
/// [measuredWidth].
///
/// Walks the same merge chain as [resolveStageContainer]
/// (design-system default → `CoreStageContainerTheme.style` →
/// `widget.stageContainerStyle`), with the per-instance widget
/// [breakpoint] / [padding] props taking precedence. When [measuredWidth]
/// is `null` (first frame before the ResizeObserver fires) the base
/// padding is returned unchanged. Kept as a separate `resolveCo*` entry
/// point so [ResolvedStageContainer] stays pure paint-ready chrome
/// (number_ticker separate-resolver pattern) — the resolved padding is
/// behavioural data consumed by the builder callback, not paint chrome.
CoreEdgeInsets resolveStageContainerPadding(
  BuildContext context, {
  CoreStageBreakpoint? breakpoint,
  CoreEdgeInsets? padding,
  double? measuredWidth,
  CoreStageContainerStyle? stageContainerStyle,
}) {
  final themeStyle = context.theme.coreComponentTheme?.stageContainer?.style;

  final merged = resolveStyleChain(const CoreStageContainerStyle(), [
    themeStyle,
    stageContainerStyle,
  ]);

  final effectiveBreakpoint =
      breakpoint ??
      merged.breakpoint ??
      CoreStageContainerStyle.defaultBreakpoint;

  final basePadding =
      padding ?? merged.padding ?? CoreStageContainerStyle.defaultPadding;

  return measuredWidth == null
      ? basePadding
      : _redistributePadding(
          measuredWidth,
          base: basePadding,
          breakpoint: effectiveBreakpoint,
        );
}

// ═══════════════════════════════════════════════════
// Internal helpers
// ═══════════════════════════════════════════════════

/// Runs the exact same breakpoint math as the Flutter implementation
/// so callers get identical padding for any given parent [width].
///
/// Below `breakpoint.minSize` the horizontal insets collapse to 0
/// (the content stretches edge-to-edge). Above `breakpoint.maxSize`
/// the surplus width is split equally between the left and right
/// insets so the content stays at the cap. In between, the left/right
/// insets are inflated so the content tracks the next-lower breakpoint
/// step (`getMinWidth(width)`).
CoreEdgeInsets _redistributePadding(
  double width, {
  required CoreEdgeInsets base,
  required CoreStageBreakpoint breakpoint,
}) {
  final top = base.top;
  final bottom = base.bottom;
  var left = base.left;
  var right = base.right;

  if (width < breakpoint.minSize) {
    return CoreEdgeInsets.only(top: top, bottom: bottom);
  }

  if (width > breakpoint.maxSize) {
    final remaining = (width - breakpoint.maxSize) / 2;
    left = max(0, left + remaining);
    right = max(0, right + remaining);
    return CoreEdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  final minWidth = breakpoint.getMinWidth(width);
  final remaining = (width - minWidth) / 2;
  left = max(0, left + remaining);
  right = max(0, right + remaining);
  return CoreEdgeInsets.only(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
}
