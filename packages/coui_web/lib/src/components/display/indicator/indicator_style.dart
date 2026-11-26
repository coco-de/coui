// indicator transform origin / translate
// percentages are CSS layout primitives, not design tokens.

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

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Indicator`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // outer wrapper — relative + inline-block
///   ├─ caller-supplied child
///   └─ overlay (<div>)                  // absolute, anchored to edge / corner
///        └─ caller-supplied item
/// ```
///
/// `co_indicator.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only
/// `WebElementChrome` slots — no scalar / metadata / Component fields.
/// Semantic identifiers (`horizontalPosition`, `verticalPosition`) flow
/// in as widget props to the single resolver entry point; the resolved
/// overlay slot bakes the anchor / translate inline CSS for the chosen
/// position pair.
class ResolvedIndicator implements WebResolvedChrome {
  /// Creates a [ResolvedIndicator].
  const ResolvedIndicator({required this.root, required this.overlay});

  /// Paint-ready chrome for the outer wrapper `<div>` —
  /// `relative inline-block` so the absolutely-positioned overlay can
  /// anchor anywhere inside the bounding box. No inline-CSS chrome on
  /// the root.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the overlay `<div>` — `absolute
  /// inline-flex leading-none` className plus an inline `z-index`
  /// (local lift) and the anchor (`top` / `right` / `bottom` /
  /// `left`) and `translate(...)` inline CSS so the item lands on the
  /// chosen edge / corner.
  final WebElementChrome overlay;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedIndicator] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.indicator.style
///   → widget.indicatorStyle
/// ```
ResolvedIndicator resolveIndicator(
  BuildContext context, {
  required CoreIndicatorHorizontalPosition horizontalPosition,
  required CoreIndicatorVerticalPosition verticalPosition,
  CoreIndicatorStyle? indicatorStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.indicator;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreIndicatorStyle(), [
    coreTheme?.style,
    indicatorStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final effectiveOffset = merged.offset ?? CoreIndicatorStyle.defaultOffset;
  final ringWidth = merged.ringWidth ?? CoreIndicatorStyle.defaultRingWidth;
  final ringColor = (merged.ringColor ?? CoreIndicatorStyle.defaultRingColor)
      .toValue();
  final ringRadius =
      (merged.ringBorderRadius ?? CoreIndicatorStyle.defaultRingBorderRadius)
          .toValue();

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer wrapper `<div>` Tailwind className —
  /// `relative inline-block` so the absolutely-positioned overlay can
  /// anchor anywhere inside the bounding box.
  String buildRootClassName() => WebLayout.relativeInlineBlock;

  /// Composes the overlay `<div>` Tailwind className —
  /// `absolute inline-flex leading-none`. The lift above the badge's
  /// parent (avatar/root content) is an inline `z-index` (see
  /// [buildOverlayInlineStyles]) rather than a `z-` class — the local
  /// lift value isn't a registered `zIndex` scale step, and an
  /// arbitrary-value bracket class is blocked by the design-token
  /// guard. Per-corner translate / anchor offsets flow through the
  /// inline-CSS bundle below too.
  String buildOverlayClassName() =>
      '${WebLayout.absolute} ${WebLayout.inlineFlex} leading-none';

  /// Composes the overlay `<div>` inline-CSS bundle — `z-index`
  /// (local lift above sibling content, `CoreZIndex.z0 + 1`, a
  /// magnitude below the first named `CoreZIndex` rung) plus anchor
  /// (`top` / `right` / `bottom` / `left`) and `translate(...)`
  /// corrections so the item's centre lands on the anchor when it is
  /// on a centered edge (matches Flutter `Align(Alignment(h, v))`
  /// behaviour where `0` means centered).
  Styles buildOverlayInlineStyles() {
    final raw = <String, String>{'z-index': '${CoreZIndex.z0 + 1}'};
    // The ring is a shadow spread outside the item: the item's own corner
    // meets the child's corner and the ring overhangs it, so the ring never
    // moves the item (the Flutter twin pads the item and pulls the anchor
    // back by the same width).
    if (ringWidth > 0) {
      raw['border-radius'] = ringRadius;
      raw['box-shadow'] = '0 0 0 ${strokeWidthCss(ringWidth)} $ringColor';
    }
    final offset = '${effectiveOffset / kRemDivisor}rem';

    // Anchor.
    switch (horizontalPosition) {
      case .start:
        raw['left'] = offset;
      case .end:
        raw['right'] = offset;
      case .center:
        raw['left'] = '50%';
    }
    switch (verticalPosition) {
      case .top:
        raw['top'] = offset;
      case .bottom:
        raw['bottom'] = offset;
      case .middle:
        raw['top'] = '50%';
    }

    // Translate so the item's center lands on the anchor when it is on
    // the edge (center / middle case).
    final tx = horizontalPosition == .center ? '-50%' : '0';
    final ty = verticalPosition == .middle ? '-50%' : '0';
    if (tx != '0' || ty != '0') {
      raw['transform'] = 'translate($tx, $ty)';
    }
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedIndicator(
    root: WebElementChrome(className: buildRootClassName()),
    overlay: WebElementChrome(
      className: buildOverlayClassName(),
      inlineStyles: buildOverlayInlineStyles(),
    ),
  );
}
