/// Resolves Join chrome and child rules with legacy and Element selectors.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/element_scope.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Join`.
///
/// DOM shape:
///
/// ```text
/// root (<div id=$scopeId>)              // inline-flex strip container
///   ├─ <style> (scoped)                 // child-radius override rules
///   │                                   //   pinned to `#$scopeId` —
///   │                                   //   composed by [resolveJoinCss]
///   ├─ items[i] (<div>)                 // per-child wrapper — position-aware radius + clip
///   │    └─ children[i]                 // caller-supplied Component
///   └─ ...
/// ```
///
/// `co_join.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.root` / `resolved.items[i]` — no merge /
/// fallback / conversion in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only
/// `WebElementChrome` slots. The per-item corner-radius mapping
/// depends on the item's position in the strip (`index` / `count`)
/// and the layout direction; the resolver closes over those build-time
/// inputs and bakes each item's `border-radius` shorthand + `overflow`
/// clip into [ResolvedJoin.items] — no raw `CoreBorderRadius`
/// value or `vertical` flag is exposed (single entry point, render-only
/// widget).
class ResolvedJoin implements WebResolvedChrome {
  /// Creates a [ResolvedJoin].
  const ResolvedJoin({required this.root, required this.items})
    : _ruleScope = const WebElementChrome(className: '');

  const ResolvedJoin._scoped({
    required this.root,
    required this.items,
    required WebElementChrome ruleScope,
  }) : _ruleScope = ruleScope;

  /// The Element-owned class the root carries so the scoped child rules
  /// ([resolveJoinElementCss]) select this strip and no other. Empty on a
  /// hand-built [ResolvedJoin], which keeps the legacy id selector.
  final WebElementChrome _ruleScope;

  /// Paint-ready chrome for the outer strip `<div>` — `inline-flex
  /// flex-row` (horizontal) or `inline-flex flex-col` (vertical).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for each per-child item wrapper `<div>` — one
  /// entry per child in input order. Each entry carries the
  /// position-aware `border-radius` shorthand plus the `overflow:
  /// hidden` clip so the child's own corners are masked outside the
  /// join radius.
  final List<WebElementChrome> items;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedJoin] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.join.style
///   → widget.joinStyle
/// ```
///
/// Closes over the per-build [vertical] / [count] inputs so every
/// per-item corner-radius bundle is baked into [ResolvedJoin.items]
/// entry:
///
/// - `count == 1`: full radius on all corners.
/// - First item (`index == 0`): radius on the leading side (left/top).
/// - Last item (`index == count - 1`): radius on the trailing side
///   (right/bottom).
/// - Middle item: no radius.
ResolvedJoin resolveJoin(
  BuildContext context, {
  required bool vertical,
  required int count,
  CoreJoinStyle? joinStyle,
}) {
  final themeStyle = context.theme.coreComponentTheme?.join?.style;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreJoinStyle(), [
    themeStyle,
    joinStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Border radius is always emitted inline (`(merged ?? default)
  // .toValue()` / `.edgeFlushValue(...)`) — never a Tailwind radius
  // utility class. Default and override share the same CSS surface so
  // the resolved chrome reflects `merged.borderRadius` directly (Epic
  // #1603 single-signature gate — radius is always-inline).
  final borderRadius = merged.borderRadius ?? CoreJoinStyle.defaultBorderRadius;
  // A line width, so it goes out through the stroke variable like the
  // children's own borders — a surface style's stroke floor moves both.
  final itemOverlap = merged.itemOverlap ?? CoreJoinStyle.defaultItemOverlap;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer strip `<div>` Tailwind className —
  /// `inline-flex flex-row` (horizontal) or `inline-flex flex-col`
  /// (vertical).
  String buildRootClassName() => vertical
      ? '${WebLayout.inlineFlex} ${WebLayout.flexCol}'
      : '${WebLayout.inlineFlex} ${WebLayout.flexRow}';

  /// Composes the item `<div>` `border-radius` shorthand for the
  /// item at [index].
  ///
  /// The per-corner zeroing flows through the shared `core_to_css`
  /// converters — `CoreBorderRadius.toValue()` for the full radius and
  /// `CoreBorderRadius.edgeFlushValue(edge)` for the edge that docks
  /// against its neighbour (its corner pair squared) — so there is no
  /// per-corner reach-in here (Epic #1603 chaining gate).
  String buildItemRadius(int index) {
    if (count == 1) {
      // Single item: full radius on all corners.
      return borderRadius.toValue();
    }
    if (index == 0) {
      // First item: rounded on the start side, square against the next
      // item (right edge horizontally / bottom edge vertically).
      return borderRadius.edgeFlushValue(vertical ? 'bottom' : 'right');
    }
    if (index == count - 1) {
      // Last item: rounded on the end side, square against the previous
      // item (left edge horizontally / top edge vertically).
      return borderRadius.edgeFlushValue(vertical ? 'top' : 'left');
    }
    // Middle item: square on all corners.
    return CoreBorderRadius.zero.toValue();
  }

  /// Composes the item `<div>` inline-CSS bundle — position-aware
  /// `border-radius`, the `overflow: hidden` clip that hides the item's
  /// own corners outside the join radius, and, after the first item, the
  /// negative margin that pulls it back over its neighbour by
  /// [CoreJoinStyle.itemOverlap] so two bordered children share one
  /// border at the seam (the Flutter twin moves the laid-out children).
  /// The horizontal margin is the inline-start one, so a right-to-left
  /// strip overlaps toward its own start as well.
  Styles buildItemInlineStyles(int index) => .new(
    raw: {
      'border-radius': buildItemRadius(index),
      'overflow': 'hidden',
      if (index > 0 && itemOverlap != 0)
        vertical ? 'margin-top' : 'margin-inline-start':
            'calc(${strokeWidthCss(itemOverlap)} * -1)',
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  final ruleScopeClass = elementScopeId(context, prefix: 'co-join-rule');
  return ResolvedJoin._scoped(
    root: WebElementChrome(
      className: '${buildRootClassName()} $ruleScopeClass',
    ),
    items: [
      for (var i = 0; i < count; i++)
        WebElementChrome(
          className: '',
          inlineStyles: buildItemInlineStyles(i),
        ),
    ],
    ruleScope: WebElementChrome(className: ruleScopeClass),
  );
}

// ═══════════════════════════════════════════════════
// Scoped-CSS resolver (Category C)
// ═══════════════════════════════════════════════════

/// Resolves the scoped `<style>` block that flattens each child's own
/// border radius to the strip position, pinned to [scopeId].
///
/// The per-item wrapper's `overflow: hidden` clip only crops pixels
/// outside the wrapper — a child that paints its own rounded corners
/// (e.g. a `Button`) would still show them as notches at the seams.
/// These rules override the direct child's `border-radius` with the
/// same position-aware values the wrappers carry, so the children
/// genuinely paint flush seams. Unified children emit their radius as
/// an inline style, which no selector specificity can beat — the
/// rules carry `!important` because the join owns the strip geometry
/// (the same replacement semantic the Flutter twin expresses through
/// the ambient `JoinItemData`).
///
/// Walks the **same** merge chain as [resolveJoin] so the radius
/// values stay identical to the wrapper clip.
String resolveJoinCss(
  BuildContext context, {
  required String scopeId,
  required bool vertical,
  required int count,
  CoreJoinStyle? joinStyle,
}) => _resolveJoinCss(
  context,
  rootSelector: '#$scopeId',
  vertical: vertical,
  count: count,
  joinStyle: joinStyle,
);

/// Keeps the existing DOM id selector while isolating the owning Element.
///
/// The zero-specificity guard preserves every legacy rule's specificity.
/// A manually constructed [ResolvedJoin] retains the legacy selector path.
String resolveJoinElementCss(
  BuildContext context, {
  required ResolvedJoin join,
  required String scopeId,
  required bool vertical,
  required int count,
  CoreJoinStyle? joinStyle,
}) {
  final guard = join._ruleScope.className;
  return _resolveJoinCss(
    context,
    rootSelector: guard.isEmpty ? '#$scopeId' : '#$scopeId:where(.$guard)',
    vertical: vertical,
    count: count,
    joinStyle: joinStyle,
  );
}

String _resolveJoinCss(
  BuildContext context, {
  required String rootSelector,
  required bool vertical,
  required int count,
  CoreJoinStyle? joinStyle,
}) {
  final themeStyle = context.theme.coreComponentTheme?.join?.style;
  final merged = resolveStyleChain(const CoreJoinStyle(), [
    themeStyle,
    joinStyle,
  ]);
  final borderRadius = merged.borderRadius ?? CoreJoinStyle.defaultBorderRadius;

  // Cross-axis fill equalises the items — the wrapper stretches to
  // the strip's cross size (flex default) but an inline-flex child
  // inside it would keep its intrinsic size, so a vertical strip's
  // buttons would vary with their label's glyph width (the Flutter
  // twin equalises through cross-axis stretch inside an intrinsic
  // box). `min-*` rather than `width`/`height: 100%` so a Button's
  // size-token `h-*` / `w-*` still decides the used size.
  final crossAxisFill = vertical ? 'min-width: 100%;' : 'min-height: 100%;';

  // A single-item strip has no neighbour to paint over it, but its
  // wrapper still clips, so the ring still needs letting out.
  if (count == 1) {
    return '$rootSelector > div > * { '
        'border-radius: ${borderRadius.toValue()} !important; '
        '$crossAxisFill }'
        // The focus ring is an outline on the child, and it lies OUTSIDE
        // the child's box, so the wrapper's `overflow: hidden` (which clips
        // descendant painting, outlines included) erases it entirely. Two
        // declarations are needed and neither alone is enough:
        //
        //   `overflow: visible` lets the ring out of the wrapper, and
        //   `!important` is not optional — the wrapper carries `overflow`
        //   INLINE (`buildItemInlineStyles`), which no selector specificity
        //   can beat. The same reason the radius rules above carry it.
        //
        //   `position: relative` + `z-index` lift the focused item over its
        //   next sibling, which would otherwise paint across the band on the
        //   shared seam. A z-index on a statically positioned box does
        //   nothing, so the position must come with it.
        //
        // `:focus-within` is the browser-native counterpart of the Flutter
        // twin's `Focus(onFocusChange:)` — no Dart state, no re-render.
        '$rootSelector > div:focus-within { '
        'overflow: visible !important; '
        'position: relative; '
        'z-index: 1; }';
  }

  final firstRadius = borderRadius.edgeFlushValue(
    vertical ? 'bottom' : 'right',
  );
  final lastRadius = borderRadius.edgeFlushValue(vertical ? 'top' : 'left');

  // Generic squared rule first; the positional rules share its
  // specificity and win by source order.
  return '$rootSelector > div > * { '
      'border-radius: ${CoreBorderRadius.zero.toValue()} !important; '
      '$crossAxisFill }'
      '$rootSelector > div:first-of-type > * { '
      'border-radius: $firstRadius !important; }'
      '$rootSelector > div:last-of-type > * { '
      'border-radius: $lastRadius !important; }'
      // The focus ring is an outline on the child, and it lies OUTSIDE
      // the child's box, so the wrapper's `overflow: hidden` (which clips
      // descendant painting, outlines included) erases it entirely. Two
      // declarations are needed and neither alone is enough:
      //
      //   `overflow: visible` lets the ring out of the wrapper, and
      //   `!important` is not optional — the wrapper carries `overflow`
      //   INLINE (`buildItemInlineStyles`), which no selector specificity
      //   can beat. The same reason the radius rules above carry it.
      //
      //   `position: relative` + `z-index` lift the focused item over its
      //   next sibling, which would otherwise paint across the band on the
      //   shared seam. A z-index on a statically positioned box does
      //   nothing, so the position must come with it.
      //
      // `:focus-within` is the browser-native counterpart of the Flutter
      // twin's `Focus(onFocusChange:)` — no Dart state, no re-render.
      '$rootSelector > div:focus-within { '
      'overflow: visible !important; '
      'position: relative; '
      'z-index: 1; }';
}
