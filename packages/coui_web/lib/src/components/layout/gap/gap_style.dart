library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output — Gap
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Gap`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                     // flex-basis spacer; cross-axis stretch / explicit
/// ```
///
/// `co_gap.dart` reads `resolved.root.className` +
/// `resolved.root.inlineStyles` straight — no merge / fallback /
/// conversion in the widget body.
class ResolvedGap implements WebResolvedChrome {
  /// Creates a [ResolvedGap].
  const ResolvedGap({required this.root});

  /// Paint-ready chrome for the root `<div>` element.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolved output — MaxGap
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `MaxGap`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                                     // flex-basis + flex-grow:1 / flex-shrink:1 + max-* cap
/// ```
class ResolvedMaxGap implements WebResolvedChrome {
  /// Creates a [ResolvedMaxGap].
  const ResolvedMaxGap({required this.root});

  /// Paint-ready chrome for the root `<div>` element.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolved output — SliverGap
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `SliverGap`.
///
/// Web has no sliver protocol, so this renders as a `Gap`-equivalent
/// flex spacer (`flex-basis` + `align-self: stretch`).
class ResolvedSliverGap implements WebResolvedChrome {
  /// Creates a [ResolvedSliverGap].
  const ResolvedSliverGap({required this.root});

  /// Paint-ready chrome for the root `<div>` element.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — Gap entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedGap] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreGapStyle.defaultSize)
///   → theme.coreComponentTheme.gap.style
///   → widget.gapStyle
/// ```
ResolvedGap resolveGap(BuildContext context, {CoreGapStyle? gapStyle}) {
  final coreTheme = context.theme.coreComponentTheme?.gap;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreGapStyle(), [
    coreTheme?.style,
    gapStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final size = merged.size ?? CoreGapStyle.defaultSize;
  final crossAxisExtent = merged.crossAxisExtent;
  final color = merged.color;

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` Tailwind className. Gap has no
  /// Tailwind utilities — every rule flows through inline CSS so the
  /// flex-basis stays in lockstep with Flutter logical pixels.
  String buildRootClassName() => '';

  /// Composes the root `<div>` inline-CSS bundle — `flex-basis` for
  /// the main axis, `flex-shrink: 0` to pin against neighbour shrink,
  /// `align-self: stretch` when the cross-axis is implicit, and an
  /// optional background colour for visible / debug gaps.
  ///
  /// The main axis is spacing, so it rides `spaceCss` and the spacing
  /// variable a density re-maps — the Flutter twin moves the same value
  /// through `theme.geometry.space`. The cross axis is the extent of a
  /// painted rectangle, not spacing, and stays a literal on both.
  Styles buildRootInlineStyles() {
    final raw = {
      'flex-basis': spaceCss(size),
      'flex-shrink': '0',
      if (crossAxisExtent == null) 'align-self': 'stretch',
      if (crossAxisExtent != null)
        'min-width': '${crossAxisExtent / kRemDivisor}rem',
      if (crossAxisExtent != null)
        'min-height': '${crossAxisExtent / kRemDivisor}rem',
      // both key & value map entry
      if (color != null) 'background-color': color.toValue(),
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedGap(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// Resolver — MaxGap entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMaxGap] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreGapStyle.defaultSize)
///   → theme.coreComponentTheme.maxGap.style
///   → widget.gapStyle
/// ```
///
/// MaxGap mirrors `Flexible(flex: 1, fit: loose)` around `Gap`:
/// `flex-grow: 1` claims remaining space, `flex-shrink: 1` yields it
/// back when the parent runs out, and `max-width` / `max-height`
/// caps the painted extent at `size` so the gap never exceeds its
/// requested main-axis length.
ResolvedMaxGap resolveMaxGap(
  BuildContext context, {
  CoreGapStyle? gapStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.maxGap;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreGapStyle(), [
    coreTheme?.style,
    gapStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final size = merged.size ?? CoreGapStyle.defaultSize;
  final crossAxisExtent = merged.crossAxisExtent;
  final color = merged.color;

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` Tailwind className. MaxGap, like
  /// `Gap`, emits no Tailwind utilities.
  String buildRootClassName() => '';

  /// Composes the root `<div>` inline-CSS bundle — the cap is the same
  /// spacing value as the basis, so both ride `spaceCss` together.
  Styles buildRootInlineStyles() {
    final raw = {
      'flex-basis': spaceCss(size),
      'flex-shrink': '1',
      'flex-grow': '1',
      'max-width': spaceCss(size),
      'max-height': spaceCss(size),
      if (crossAxisExtent == null) 'align-self': 'stretch',
      if (crossAxisExtent != null)
        'min-width': '${crossAxisExtent / kRemDivisor}rem',
      if (crossAxisExtent != null)
        'min-height': '${crossAxisExtent / kRemDivisor}rem',
      // both key & value map entry
      if (color != null) 'background-color': color.toValue(),
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedMaxGap(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// Resolver — SliverGap entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSliverGap] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreGapStyle.defaultSize)
///   → theme.coreComponentTheme.sliverGap.style
///   → widget.gapStyle
/// ```
///
/// `CoreGapStyle.crossAxisExtent` is intentionally ignored — the
/// sliver protocol on Flutter dictates the cross axis, and the Web
/// rendering matches `Gap` for symmetry.
ResolvedSliverGap resolveSliverGap(
  BuildContext context, {
  CoreGapStyle? gapStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.sliverGap;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreGapStyle(), [
    coreTheme?.style,
    gapStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final size = merged.size ?? CoreGapStyle.defaultSize;
  final color = merged.color;

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` Tailwind className.
  String buildRootClassName() => '';

  /// Composes the root `<div>` inline-CSS bundle.
  Styles buildRootInlineStyles() {
    final raw = {
      'flex-basis': spaceCss(size),
      'flex-shrink': '0',
      'align-self': 'stretch',
      // both key & value map entry
      if (color != null) 'background-color': color.toValue(),
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSliverGap(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}
