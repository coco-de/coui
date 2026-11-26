library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `AspectRatioBox`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // relative w-full — positioning ctx
///   ├─ spacer (<div>)                   // block w-full + padding-top:%
///   └─ content (<div>)                  // absolute inset-0 — wraps child
/// ```
///
/// `co_aspect_ratio_box.dart` reads each slot's `className` +
/// `inlineStyles` straight from `resolved.<slot>` — no merge / fallback
/// / conversion in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only
/// `WebElementChrome` slots — `AspectRatioBox` is a pure layout
/// primitive with no chrome / nested-style slots.
class ResolvedAspectRatioBox implements WebResolvedChrome {
  /// Creates a [ResolvedAspectRatioBox].
  const ResolvedAspectRatioBox({
    required this.root,
    required this.spacer,
    required this.content,
  });

  /// Paint-ready chrome for the outer wrapper `<div>` — `relative
  /// w-full` className only. Provides the positioning context the
  /// absolutely positioned content layer resolves against.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the invisible spacer `<div>` — `block
  /// w-full` className plus the `padding-top:<percentage>%` inline CSS
  /// that holds the resolved aspect ratio open.
  final WebElementChrome spacer;

  /// Paint-ready chrome for the absolutely-positioned content `<div>`
  /// pinned to the wrapper (`absolute inset-0 coui-aspect-fill`) so
  /// the child stretches to fill the ratio-constrained box
  /// (tight-constraints parity with Flutter's `AspectRatio`).
  final WebElementChrome content;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAspectRatioBox] for the given [context].
///
/// Ratio resolution chain:
///
/// ```text
/// CoreAspectRatioBoxStyle.defaultDefaultRatio
///   → theme.coreComponentTheme.aspectRatioBox.style.defaultRatio
///   → widget.ratio (when finite and > 0)
/// ```
ResolvedAspectRatioBox resolveAspectRatioBox(
  BuildContext context, {
  required double ratio,
}) {
  final coreTheme = context.theme.coreComponentTheme?.aspectRatioBox;

  // ─── Resolved chrome values ───────────────────────────
  // Per-field fallback: widget > theme > design-system default. Every
  // value feeding the local builders below is non-null after this
  // block.
  final widgetRatio = ratio.isFinite && ratio > 0 ? ratio : null;
  final themeRatio = coreTheme?.style?.defaultRatio;
  final resolvedRatio =
      widgetRatio ?? themeRatio ?? CoreAspectRatioBoxStyle.defaultDefaultRatio;
  final paddingTopPercentage =
      (_kRatioBase / resolvedRatio * _kPercentageMultiplier).toStringAsFixed(
        _kPercentageDecimals,
      );

  // ─── Local builders ───────────────────────────────────
  // Closures capture the resolved chrome values above — local to the
  // resolver, inaccessible from outside.

  /// Composes the outer wrapper `<div>` Tailwind className —
  /// `relative` so the absolutely-positioned content layer pins to it,
  /// `w-full` so the spacer's percentage padding has a deterministic
  /// containing-block width.
  String buildRootClassName() => WebLayout.relativeFull;

  /// Composes the spacer `<div>` Tailwind className. The
  /// `padding-top` percentage is emitted inline (see
  /// [buildSpacerInlineStyles]).
  String buildSpacerClassName() => '${WebLayout.block} ${WebLayout.wFull}';

  /// Composes the spacer `<div>` inline-CSS bundle — the resolved
  /// ratio is encoded as `padding-top: <percentage>%`. Percentage
  /// padding always resolves against the containing block's width, so
  /// this is the canonical CSS hack for preserving an aspect ratio.
  Styles buildSpacerInlineStyles() =>
      .new(raw: {'padding-top': '$paddingTopPercentage%'});

  /// Composes the content `<div>` Tailwind className — `absolute
  /// inset-0` pins the child to fill the wrapping `relative` box.
  /// `inset-0` is the Tailwind positional reset
  /// (top/right/bottom/left=0), a CSS layout sentinel rather than a
  /// design-system spacing value, so it does not need to flow through
  /// a contract default.
  ///
  /// `coui-aspect-fill`: hook for the global child-stretch rule
  /// mounted at the `CoUIWeb` root (`.coui-aspect-fill > * { width /
  /// height: 100% }`) — the CSS mirror of the tight constraints
  /// Flutter's `AspectRatio` passes to its child. A fit-content child
  /// (e.g. `Card`'s `w-fit` root) would otherwise render at its
  /// intrinsic size inside the ratio box instead of filling it, and no
  /// parent-side class can override the child's own sizing without a
  /// child selector.
  String buildContentClassName() =>
      '${WebLayout.absoluteFull} coui-aspect-fill';

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedAspectRatioBox(
    root: WebElementChrome(className: buildRootClassName()),
    spacer: WebElementChrome(
      className: buildSpacerClassName(),
      inlineStyles: buildSpacerInlineStyles(),
    ),
    content: WebElementChrome(className: buildContentClassName()),
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (small pure functions, short signatures)
// ═══════════════════════════════════════════════════

/// CSS rounding precision (decimal places) used when converting the
/// resolved ratio into the `padding-top` percentage that holds the
/// aspect-ratio open while the content layer is absolutely positioned.
const int _kPercentageDecimals = 4;

/// Sentinel used to flip a `width:height` ratio into the
/// `height / width` percentage CSS needs for the padding-top trick.
const int _kRatioBase = 1;

/// `padding-top` is the canonical CSS padding hack that preserves the
/// requested aspect ratio because percentage padding always resolves
/// against the containing block's *width*.
const int _kPercentageMultiplier = 100;
