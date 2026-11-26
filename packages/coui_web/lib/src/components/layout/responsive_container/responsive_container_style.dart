library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ResponsiveContainer`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)              // horizontally-centred max-width wrapper
///   └─ child                // caller-supplied content
/// ```
///
/// `co_responsive_container.dart` reads `resolved.root.className` +
/// `resolved.root.inlineStyles` straight back into
/// `Component.element(...)` — no merge / fallback / conversion in the
/// widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only the
/// `WebElementChrome` slot (paint-ready chrome). No scalar metadata
/// (`maxWidth` / `centered` / `horizontalPadding`) is exposed — those
/// are folded into the `root` chrome's inline CSS here.
class ResolvedResponsiveContainer implements WebResolvedChrome {
  /// Creates a [ResolvedResponsiveContainer].
  const ResolvedResponsiveContainer({required this.root});

  /// Paint-ready chrome for the outer `<div>` — `w-full` className
  /// plus the inline-CSS for `max-width` / horizontal centring /
  /// horizontal padding.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedResponsiveContainer] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.responsiveContainer.style
///   → widget.responsiveContainerStyle
/// ```
///
/// The flat widget props ([maxWidth] / [centered] / [padding]) take
/// precedence over the merged style chain (legacy convenience props).
///
/// [responsiveMaxWidth] (widget param wins over
/// `CoreResponsiveContainerStyle.responsiveMaxWidth` — same
/// widget-first convention as [maxWidth]/[centered]/[padding])
/// is Story H's non-breaking extension: when the merged map is
/// non-null, the current [CoreBreakpointTier] (observed once via the
/// existing `resolveBreakpoint` — Story B/C, no new measurement
/// logic) selects the effective preset, individually falling back to
/// the static [maxWidth] resolution for any tier missing from the
/// map. When the merged map is `null` this branch is skipped
/// entirely — a caller that never sets [responsiveMaxWidth] takes the
/// exact pre-existing code path (no breakpoint observation, no
/// behaviour change).
ResolvedResponsiveContainer resolveResponsiveContainer(
  BuildContext context, {
  required CoreResponsiveContainerMaxWidth? maxWidth,
  Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>? responsiveMaxWidth,
  required bool? centered,
  required CoreEdgeInsets? padding,
  CoreResponsiveContainerStyle? responsiveContainerStyle,
}) {
  final themeStyle =
      context.theme.coreComponentTheme?.responsiveContainer?.style;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreResponsiveContainerStyle(), [
    themeStyle,
    responsiveContainerStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finishes its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final resolvedMaxWidth =
      maxWidth ??
      merged.maxWidth ??
      CoreResponsiveContainerStyle.defaultMaxWidth;

  // Widget param wins over the merged style slot (same convention as
  // maxWidth/centered/padding above).
  final effectiveResponsiveMaxWidth =
      responsiveMaxWidth ?? merged.responsiveMaxWidth;

  // `resolvedMaxWidth` is reused unchanged as the static value AND as
  // the per-tier fallback when a tier is missing from the map. The
  // null-aware index (`?[]`) short-circuits — `resolveBreakpoint` is
  // never called when `effectiveResponsiveMaxWidth` is null, so a
  // caller that never sets `responsiveMaxWidth` takes the exact
  // pre-existing code path (no breakpoint observation performed).
  final effectiveMaxWidth =
      effectiveResponsiveMaxWidth?[resolveBreakpoint(context).tier] ??
      resolvedMaxWidth;
  final effectiveCentered =
      centered ??
      merged.centered ??
      CoreResponsiveContainerStyle.defaultCentered;
  final effectiveHorizontalPadding =
      padding ??
      merged.horizontalPadding ??
      CoreResponsiveContainerStyle.defaultHorizontalPadding;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer `<div>` Tailwind className.
  ///
  /// Fixed to `'w-full'` — the responsive sizing and centring live in
  /// the inline CSS emitted by [buildRootInlineStyles] because the
  /// max-width breakpoint values and the centring margins fall outside
  /// this project's Tailwind utility set (see [buildRootInlineStyles]).
  String buildRootClassName() => WebLayout.wFull;

  /// Composes the outer `<div>` inline CSS.
  ///
  /// Why so much of the responsive-container chrome lives inline
  /// instead of in Tailwind classes:
  ///
  /// - `max-width` breakpoint values (640/768/1024/1280/1536 px) fall
  ///   outside the `CoreSpace`/`CoreSize` scales, so `--coui-*` CSS
  ///   variables can't substitute. A rem escape-hatch is used
  ///   (`max-width: 100%` for the `full` preset).
  /// - `margin-left: auto; margin-right: auto` is written directly
  ///   rather than via `mx-auto` because this project's Tailwind
  ///   config re-defines the `margin` scale from scratch (see
  ///   `tailwind.config.extend.spacing`) and doesn't emit a
  ///   `.mx-auto` utility.
  /// - Horizontal padding is emitted via `CoreEdgeInsets.toValue()`
  ///   (the shared `core_to_css` adapter) so the conversion stays in
  ///   one place — matching the PoC button / card padding pattern.
  Styles buildRootInlineStyles() {
    final raw = {'max-width': _maxWidthCss(effectiveMaxWidth)};
    if (effectiveCentered) {
      raw['margin-left'] = 'auto';
      raw['margin-right'] = 'auto';
    }
    raw['padding'] = effectiveHorizontalPadding.toValue();
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedResponsiveContainer(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (small pure functions, short signatures)
// ═══════════════════════════════════════════════════

/// Maps a [CoreResponsiveContainerMaxWidth] preset to its CSS
/// `max-width` value.
///
/// The breakpoint widths (640/768/1024/1280/1536 px) fall outside the
/// `CoreSpace` / `CoreSize` token scales, so they use the rem
/// escape-hatch (`${px / kRemDivisor}rem`). The `full` preset opts out
/// of the constraint entirely via `100%`.
String _maxWidthCss(CoreResponsiveContainerMaxWidth maxWidth) {
  final px = maxWidth.maxWidth;
  if (px == null) return '100%';
  return '${px / kRemDivisor}rem';
}
