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

/// Paint-ready chrome for Web `ResponsiveGrid`.
///
/// DOM shape:
///
/// ```text
/// (responsive == true)                       (responsive == false)
/// wrapper (<div>)                            root (<div>)        ← outermost
///   ├─ <style> with @container rules           └─ children
///   └─ root (<div>)                          // grid `<div>` — display:grid, repeat() cols
///        └─ children
/// ```
///
/// - `root` carries the always-present inner grid `<div>` chrome
///   (`display:grid`, `grid-template-columns`, `gap`).
/// - `wrapper` carries the outer container query wrapper chrome —
///   `null` when responsive breakpoints are disabled.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
///
/// No scalar metadata (columns / gap / responsive / breakpoints) and
/// no function references are exposed — the `co_responsive_grid`
/// widget reads only paint-ready chrome. The Category C scoped-CSS
/// `@container` rules are composed by the separate top-level
/// [resolveResponsiveGridCss] resolver (number_ticker / hover_card
/// separate-resolver pattern — behavioural/composed data stays off the
/// pure-chrome `ResolvedCo*`), which the widget calls at build time with
/// the runtime scope id.
class ResolvedResponsiveGrid implements WebResolvedChrome {
  /// Creates a [ResolvedResponsiveGrid].
  const ResolvedResponsiveGrid({
    required this.root,
    required this.wrapper,
  });

  /// Paint-ready chrome for the inner grid `<div>`. The className is
  /// `''` because the user passes their own `classes` directly; the
  /// inline styles are the `display:grid` /
  /// `grid-template-columns` / `gap` bundle.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the optional responsive-wrapper `<div>` —
  /// `null` when responsive breakpoints are disabled. The wrapper is
  /// the `@container` query root (`container-type: inline-size`), so
  /// breakpoints evaluate the wrapper's width.
  final WebElementChrome? wrapper;
}

/// Paint-ready chrome for Web `GridItem`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                         // grid cell wrapper
///   └─ child component
/// ```
class ResolvedGridItem implements WebResolvedChrome {
  /// Creates a [ResolvedGridItem].
  const ResolvedGridItem({required this.root});

  /// Paint-ready chrome for the grid-item `<div>` — empty className
  /// and inline-CSS bundle carrying the optional `grid-column: span
  /// N` / `grid-row: span N` declarations.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolvers
// ═══════════════════════════════════════════════════

/// Default breakpoint-to-column mapping used when no caller mapping is
/// supplied. Mirrors the Flutter default curve: 1 col below `md`, 2
/// cols below `lg`, full `columns` at `lg` and above.
Map<CoreBreakpoint, int> _defaultResponsiveBreakpoints(int columns) {
  const mobileCols = 1;
  const tabletCols = 2;
  return {
    CoreBreakpoint.xs: mobileCols,
    CoreBreakpoint.sm: mobileCols,
    CoreBreakpoint.md: tabletCols,
    CoreBreakpoint.lg: columns,
    CoreBreakpoint.xl: columns,
    CoreBreakpoint.xxl: columns,
  };
}

/// Resolves [ResolvedResponsiveGrid] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreResponsiveGridStyle.defaultX)
///   → theme.coreComponentTheme.responsiveGrid.style
///   → widget.responsiveGridStyle
///   → widget per-instance params ([columns] / [cellSpacing] / [responsive] / [breakpoints])
/// ```
ResolvedResponsiveGrid resolveResponsiveGrid(
  BuildContext context, {
  int? columns,
  double? cellSpacing,
  bool? responsive,
  Map<CoreBreakpoint, int>? breakpoints,
  CoreResponsiveGridStyle? responsiveGridStyle,
}) {
  final gridTheme = context.theme.coreComponentTheme?.responsiveGrid;

  // ─── Merge chain ──────────────────────────────────────
  // Widget per-instance params win over the style chain — packaged
  // last so `resolveStyleChain` folds them on top of the theme + slot.
  final widgetParamStyle = CoreResponsiveGridStyle(
    columns: columns,
    cellSpacing: cellSpacing,
    responsive: responsive,
    breakpoints: breakpoints,
  );
  final merged = resolveStyleChain(const CoreResponsiveGridStyle(), [
    gridTheme?.style,
    responsiveGridStyle,
    widgetParamStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth.
  final effectiveColumns =
      merged.columns ?? CoreResponsiveGridStyle.defaultColumns;
  final effectiveCellSpacing =
      merged.cellSpacing ?? CoreResponsiveGridStyle.defaultCellSpacing;
  final effectiveResponsive =
      merged.responsive ?? CoreResponsiveGridStyle.defaultResponsive;

  // ─── Local builders ───────────────────────────────────

  /// Composes the inner grid `<div>` inline CSS — `display: grid`,
  /// `grid-template-columns: repeat(var(--co-grid-cols, N), minmax(0,
  /// 1fr))`, `gap: Nrem`. The `var(--co-grid-cols, fallback)` lets
  /// the scoped `<style>` block own the authoritative column count
  /// via `@container` queries.
  ///
  /// `width: 100%; align-self: stretch` makes the grid claim the
  /// parent's full inline size even when the parent is a flex column
  /// with `align-items: center` (common in docs preview shells).
  Styles buildRootInlineStyles() => .new(
    raw: {
      'display': 'grid',
      'width': '100%',
      'align-self': 'stretch',
      'grid-template-columns':
          'repeat(var(--co-grid-cols, $effectiveColumns), '
          'minmax(0, 1fr))',
      'gap': spaceCss(effectiveCellSpacing),
    },
  );

  /// Composes the outer responsive-wrapper `<div>` inline CSS —
  /// `container-type: inline-size` turns the wrapper into a query
  /// container so `@container` rules read the wrapper's width.
  /// Returns `null` when responsive breakpoints are disabled.
  Styles? buildWrapperInlineStyles() {
    if (!effectiveResponsive) return null;
    return const Styles(
      raw: {
        'container-type': 'inline-size',
        'display': 'block',
        // `align-self: stretch` protects the direct-flex-parent case
        // (wrapper as a flex item under `align-items: center`).
        'align-self': 'stretch',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  // The wrapper claims the inline axis with the `w-full` CLASS (not an
  // inline `width: 100%`): `container-type: inline-size` makes the
  // wrapper contribute zero intrinsic width, so any content-sized
  // ancestor (a centred flex item) collapses it to 0 and every
  // `@container` query reads 0 → the grid sticks at the 1-column base.
  // Full-bleed CoUI components mark their root with `w-full` so
  // width-granting layers key off the class — the same convention lets
  // this wrapper be laid out at the real available width, matching the
  // geometry Flutter's `LayoutBuilder` sees.
  // The grid root itself also carries the `w-full` CLASS: Flutter's
  // `RenderGrid` always sizes to `constraints.maxWidth` (responsive or
  // not), and the non-responsive path renders the root without the
  // wrapper — inline `width: 100%` alone is invisible to class-keyed
  // width-granting layers, so a content-sized ancestor would shrink
  // and centre the grid instead of letting it fill.
  final wrapperInline = buildWrapperInlineStyles();
  return ResolvedResponsiveGrid(
    root: WebElementChrome(
      className: WebLayout.wFull,
      inlineStyles: buildRootInlineStyles(),
    ),
    wrapper: wrapperInline == null
        ? null
        : WebElementChrome(
            className: WebLayout.wFull,
            inlineStyles: wrapperInline,
          ),
  );
}

/// Resolves [ResolvedGridItem] for `GridItem`. Carries the
/// optional `grid-column` / `grid-row` span declarations as inline
/// CSS on the cell wrapper `<div>`.
ResolvedGridItem resolveGridItem({int? colSpan, int? rowSpan}) {
  // ─── Local builders ───────────────────────────────────

  /// Composes the grid-cell `<div>` inline-CSS bundle — emits the
  /// `grid-column` / `grid-row` span declarations when the caller
  /// requested a span > 1; returns `null` otherwise.
  Styles? buildRootInlineStyles() {
    final raw = <String, String>{};
    final effectiveCol = colSpan;
    if (effectiveCol != null && effectiveCol > 1) {
      raw['grid-column'] = 'span $effectiveCol / span $effectiveCol';
    }
    final effectiveRow = rowSpan;
    if (effectiveRow != null && effectiveRow > 1) {
      raw['grid-row'] = 'span $effectiveRow / span $effectiveRow';
    }
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedGridItem(
    root: WebElementChrome(
      className: '',
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// Scoped-CSS composers (Category C)
// ═══════════════════════════════════════════════════

/// Composes the scoped `@container` `<style>` block contents for
/// `ResponsiveGrid`, pinned to the supplied runtime scope [scopeId].
///
/// Behavioural/composed data (the breakpoint→column mapping) is resolved
/// here — a separate `resolveCo*` entry point from [resolveResponsiveGrid]
/// — so [ResolvedResponsiveGrid] stays pure paint-ready chrome (Epic
/// #1603 옵션 B 최종; number_ticker / hover_card separate-resolver
/// pattern). Walks the **same** merge chain as [resolveResponsiveGrid]
/// (`theme.responsiveGrid.style` → `widget.responsiveGridStyle` → widget
/// per-instance params) so the resolved `responsive` / `columns` /
/// `breakpoints` values are identical.
///
/// Emits the base `--co-grid-cols` rule for the smallest breakpoint plus
/// one `@container (min-width: …rem)` rule per remaining breakpoint.
/// Returns the empty string when responsive breakpoints are disabled or
/// there are no breakpoint entries to emit.
String resolveResponsiveGridCss(
  BuildContext context, {
  required String scopeId,
  int? columns,
  double? cellSpacing,
  bool? responsive,
  Map<CoreBreakpoint, int>? breakpoints,
  CoreResponsiveGridStyle? responsiveGridStyle,
}) {
  final gridTheme = context.theme.coreComponentTheme?.responsiveGrid;

  // ─── Merge chain ──────────────────────────────────────
  // Identical chain to `resolveResponsiveGrid` — widget per-instance
  // params win over the style chain (folded last).
  final widgetParamStyle = CoreResponsiveGridStyle(
    columns: columns,
    cellSpacing: cellSpacing,
    responsive: responsive,
    breakpoints: breakpoints,
  );
  final merged = resolveStyleChain(const CoreResponsiveGridStyle(), [
    gridTheme?.style,
    responsiveGridStyle,
    widgetParamStyle,
  ]);

  final effectiveResponsive =
      merged.responsive ?? CoreResponsiveGridStyle.defaultResponsive;
  if (!effectiveResponsive) return '';

  final effectiveColumns =
      merged.columns ?? CoreResponsiveGridStyle.defaultColumns;
  final effectiveBreakpoints =
      merged.breakpoints ?? _defaultResponsiveBreakpoints(effectiveColumns);

  final sorted = effectiveBreakpoints.entries.toList()
    ..sort((a, b) => a.key.minWidth.compareTo(b.key.minWidth));
  if (sorted.isEmpty) return '';
  final buffer = StringBuffer()
    // Base rule for the smallest breakpoint — overrides the inline
    // `--co-grid-cols` so the grid starts at the correct column count
    // before any container query fires.
    ..write('#$scopeId { --co-grid-cols: ${sorted.first.value}; }');
  for (final entry in sorted) {
    if (entry.key == .xs) continue;
    final minWidth = entry.key.minWidth;
    buffer.write(
      '@container (min-width: ${minWidth / kRemDivisor}rem) {'
      ' #$scopeId { --co-grid-cols: ${entry.value}; }'
      ' }',
    );
  }
  return buffer.toString();
}
