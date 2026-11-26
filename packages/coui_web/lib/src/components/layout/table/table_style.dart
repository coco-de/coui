library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Styles for the `role="row"` wrapper `<div>` grouping a row's cells for
/// the accessibility tree (`co_table.dart` / `co_resizable_table.dart`).
/// `display: contents` removes the wrapper from CSS Grid track placement
/// — its children lay out exactly as if they were direct grid children —
/// while ARIA structure (and the browser's accessibility-tree walk) still
/// sees it as a `row` grouping its cells. A structural, non-token,
/// zero-variance value (no color/spacing/variant surface), so it lives
/// here as a plain constant rather than a `CoreTableStyle` field.
const kTableRowGroupStyles = Styles(raw: {'display': 'contents'});

// ═══════════════════════════════════════════════════
// Per-build descriptors (widget → resolver inputs)
// ═══════════════════════════════════════════════════

/// Per-cell descriptor flowing from `Table` / `ResizableTable` into
/// [resolveTable]. The resolver pre-composes a [WebElementChrome] for
/// each entry — the widget reads `resolved.cells[i].*` straight back
/// into the matching `div(...)`.
typedef CoreTableCellDescriptor = ({
  CoreTableRowKind rowKind,
  bool selected,
  bool hovered,
  bool enabled,
  bool clickable,
  bool isLastRow,
  bool bodyRowEven,
  int columnSpan,
  int rowSpan,
  double? frozenLeft,
  double? frozenTop,
  bool positionRelative,
});

/// Per-resizer-handle descriptor flowing from `ResizableTable` into
/// [resolveTable]. The resolver pre-composes a [WebElementChrome] for
/// each entry — the widget reads `resolved.resizers[i].*` straight
/// back into the matching `div(...)`.
typedef CoreTableResizerDescriptor = ({
  bool vertical,
  bool hovered,
  bool dragging,
});

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Table` / `ResizableTable`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // CSS Grid container
///   ├─ cells[i] (<div>)                     // per cell — one entry per flat cell
///   └─ resizers[j] (<div>)                  // ResizableTable only — drag handles
/// ```
///
/// All slot chromes are non-null. `co_table` / `co_resizable_table`
/// read each entry's `className` + `inlineStyles` straight off — no
/// per-cell merging or fallback in the widget body. Runtime per-cell
/// / per-resizer state (hovered / selected / frozen positions / drag)
/// flows into [resolveTable] via the [cells] / [resizers]
/// descriptor lists; the resolver folds it into the matching slot.
///
/// [root] carries the `surface:content` marker + published fill
/// (`webSurfaceMarkerFor` / `surfaceFillVar`) only once the table paints a
/// background of its own — the table states none by design, so the pair
/// is gated on the same `CoreColor` that decides whether `background-color`
/// is emitted at all.
class ResolvedTable implements WebResolvedChrome {
  /// Creates a [ResolvedTable].
  const ResolvedTable({
    required this.root,
    required this.cells,
    required this.resizers,
  });

  /// Paint-ready chrome for the outer CSS Grid `<div>` — Tailwind
  /// className plus inline-CSS bundle (grid tracks, optional
  /// background / border / radius overrides, optional `overflow:
  /// clip` for scroll viewports).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for each cell `<div>` — one entry per flat
  /// cell in the same order as the [CoreTableCellDescriptor] list
  /// passed to [resolveTable].
  final List<WebElementChrome> cells;

  /// Paint-ready chrome for each resizer handle `<div>` —
  /// `ResizableTable` only; `Table` callers pass an empty
  /// descriptor list and this list comes back empty.
  final List<WebElementChrome> resizers;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTable] for the given [context] — single entry
/// point.
///
/// Merge chain (Epic #1302 nested-merge):
/// `CoreTableTheme.style` → `widgetTheme.style` → `tableStyle`.
///
/// The widget passes the precomputed grid tracks ([columnTemplate] /
/// [rowTemplate]), the effective [clipBehavior] flag, its own scroll
/// [horizontalOffset] / [verticalOffset] (so the resolver can decide
/// whether the table sits inside a scroll viewport — combined with the
/// merge-chain `viewportWidth` / `viewportHeight`), the
/// [disableScrollViewport] switch (`ResizableTable` always lays out
/// fixed-px tracks and opts out of the fit-content sizing), the
/// [useRowBackgroundFallback] switch (controls whether body-frozen
/// cells borrow the row background override when no explicit table
/// background is set — `true` for `Table`, `false` for
/// `ResizableTable`), and the flat lists of [cells] / [resizers]
/// descriptors. The resolver folds those into the className +
/// inline-CSS pair on every slot so the widget reads `resolved.<slot>.*`
/// straight back into `div(...)`.
ResolvedTable resolveTable(
  BuildContext context, {
  required String columnTemplate,
  required String rowTemplate,
  required bool clipBehavior,
  required bool useRowBackgroundFallback,
  required List<CoreTableCellDescriptor> cells,
  double? horizontalOffset,
  double? verticalOffset,
  bool disableScrollViewport = false,
  List<CoreTableResizerDescriptor> resizers = const [],
  CoreTableTheme? widgetTheme,
  CoreTableStyle? tableStyle,
}) {
  final cs = context.theme.colorScheme;
  final coreTheme = context.theme.coreComponentTheme?.table;

  final merged = resolveStyleChain(const CoreTableStyle(), [
    coreTheme?.style,
    widgetTheme?.style,
    tableStyle,
  ]);

  // When the caller provides a scroll offset or a viewport extent the
  // table lives inside a scroll container and should expand to its
  // natural grid size (`w-max`) so overflow can be scrolled. Otherwise
  // keep `w-full` so flex tracks fill the parent. `ResizableTable`
  // opts out entirely (fixed-px tracks) via [disableScrollViewport].
  final fitContentWidth =
      !disableScrollViewport &&
      (horizontalOffset != null ||
          verticalOffset != null ||
          merged.viewportWidth != null ||
          merged.viewportHeight != null);

  // ─── Resolved chrome values ───────────────────────────
  final borderWidth = merged.borderWidth ?? CoreTableStyle.defaultBorderWidth;
  // The outer box reads its own width; the row separators keep
  // `borderWidth`. No box at all when it is 0.
  final outerBorderWidth =
      merged.outerBorderWidth ?? CoreTableStyle.defaultOuterBorderWidth;
  // Table radius is **always** emitted inline as the full four-corner
  // shorthand (`(merged ?? default).toValue()`) — no Tailwind radius
  // class and no per-corner reach-in. Keeps the override path and the
  // default path on the same CSS surface so the resolved chrome reflects
  // `merged.borderRadius` directly (Epic #1603 single-signature gate —
  // radius is always-inline, card model).
  final borderRadius =
      (merged.borderRadius ?? CoreTableStyle.defaultBorderRadius).toValue();
  // A clear header (the design-system default) has no fill of its own to
  // keep a frozen header row opaque, so a frozen header cell takes the
  // frozen-cell base like a frozen body cell — Flutter's
  // `frozenHeaderBackgroundColor`.
  final headerCore =
      merged.headerBackgroundColor ??
      CoreTableStyle.defaultHeaderBackgroundColor;
  final headerIsClear = headerCore.token == null && headerCore.alpha == 0;
  final headerCellPadding =
      merged.headerPadding ?? CoreTableStyle.defaultHeaderPadding;
  final bodyCellPadding =
      merged.cellPadding ?? CoreTableStyle.defaultCellPadding;
  final resizerThickness =
      merged.resizerThickness ?? CoreTableStyle.defaultResizerThickness;
  // Header / body row min-height — design has no default (the grid track
  // sizing from `CoreTableSize` drives the layout height), so these stay
  // `null` unless the caller sets `headerHeight` / `rowHeight`. When set,
  // the cell emits a `min-height` rem rule (Epic #1603 coverage gate —
  // `headerHeight` / `rowHeight` are reflected here, 1:1 with Flutter's
  // resolved slots).
  final headerHeight = merged.headerHeight;
  final rowHeight = merged.rowHeight;
  final backgroundColorOverride = merged.backgroundColor == null
      ? null
      : cs.resolve(merged.backgroundColor!).toValue();
  final rowBackgroundColorOverride = merged.rowBackgroundColor == null
      ? null
      : cs.resolve(merged.rowBackgroundColor!).toValue();
  // Zebra-stripe even-body-row background — override only (no default).
  // The cell builder layers it under hover / selection (Epic #1603
  // coverage gate — `rowAlternateBackgroundColor` is reflected here).
  final rowAlternateOverride = merged.rowAlternateBackgroundColor == null
      ? null
      : cs.resolve(merged.rowAlternateBackgroundColor!).toValue();
  final borderColorOverride = merged.borderColor == null
      ? null
      : cs.resolve(merged.borderColor!).toValue();
  final headerBgOverride = merged.headerBackgroundColor == null
      ? null
      : cs.resolve(merged.headerBackgroundColor!).toValue();
  final footerBgOverride = merged.footerBackgroundColor == null
      ? null
      : cs.resolve(merged.footerBackgroundColor!).toValue();
  final frozenCellBgOverride = merged.frozenCellBackgroundColor == null
      ? null
      : cs.resolve(merged.frozenCellBackgroundColor!).toValue();
  final rowHoverOverride = merged.rowHoverColor == null
      ? null
      : cs.resolve(merged.rowHoverColor!).toValue();
  final rowSelectedOverride = merged.rowSelectedColor == null
      ? null
      : cs.resolve(merged.rowSelectedColor!).toValue();
  final resizerHoverColorOverride =
      merged.resizerHoverColor ?? merged.resizerColor;
  final resizerHoverOverride = resizerHoverColorOverride == null
      ? null
      : cs.resolve(resizerHoverColorOverride).toValue();
  final resizerDragColorOverride =
      merged.resizerDragColor ?? merged.resizerColor;
  final resizerDragOverride = resizerDragColorOverride == null
      ? null
      : cs.resolve(resizerDragColorOverride).toValue();
  // Nested text-style slots — the design-system role (`labelMedium` for
  // the header, `labelLarge` for body / footer) rides its role class and
  // the per-instance slot's explicit overlays layer on top inline, all
  // through `emitTypography` so the role is read from the same
  // `CoreTableStyle.default*TextStyle` Flutter reads.
  final headerTextStyle = merged.headerTextStyle;
  final cellTextStyle = merged.cellTextStyle;
  final cellTypography = emitTypography(
    cellTextStyle,
    CoreTableStyle.defaultCellTextStyle,
  );
  // Header foreground — `defaultHeaderTextStyle` carries its own colour, so
  // the header's colour rides `emitTypography` too, on the same chain
  // Flutter resolves: `slot.color ?? flat colour ?? default style colour`
  // for an enabled cell, `slot.color ?? disabled colour` for a disabled one.
  // The chosen colour replaces the default's rather than stacking on it, so
  // the cell carries a class (token) or an inline value (raw), never both.
  // Body / footer cells carry no default colour and inherit.
  CoreTextStyle? headerSlotWith(CoreColor? colour) =>
      headerTextStyle?.color != null || colour == null
      ? headerTextStyle
      : (headerTextStyle ?? const CoreTextStyle()).copyWith(color: colour);
  final headerTypography = emitTypography(
    headerSlotWith(merged.foregroundColor),
    CoreTableStyle.defaultHeaderTextStyle,
  );
  final headerDisabledTypography = emitTypography(
    headerSlotWith(
      merged.disabledForegroundColor ??
          CoreTableStyle.defaultDisabledForegroundColor,
    ),
    CoreTableStyle.defaultHeaderTextStyle,
  );

  // ── Default chrome classes (Stage 2 EMIT, theme-free) ───────────────
  // Each design-system fallback colour routes through `emitColor(null,
  // default, target)` so the SAME `CoreTableStyle.defaultX` token drives
  // both platforms (no raw `cs.<token>` interpolation). The defaults are
  // token-backed, so `emitColor` returns the Tailwind class
  // (`border-outline`, `bg-surface-container`, `bg-primary/12`, …) — the
  // class side; overrides above stay inline and win by specificity.
  final defaultBorderClass = emitColor(
    null,
    CoreTableStyle.defaultBorderColor,
    .border,
  ).className;
  final defaultHeaderBgClass = emitColor(
    null,
    CoreTableStyle.defaultHeaderBackgroundColor,
    .background,
  ).className;
  final defaultFooterBgClass = emitColor(
    null,
    CoreTableStyle.defaultFooterBackgroundColor,
    .background,
  ).className;
  final defaultFrozenBgClass = emitColor(
    merged.frozenCellBackgroundColor,
    CoreTableStyle.defaultFrozenCellBackgroundColor,
    .background,
  ).className;
  final defaultRowSelectedClass = emitColor(
    null,
    CoreTableStyle.defaultRowSelectedColor,
    .background,
  ).className;
  final defaultRowHoverClass = emitColor(
    null,
    CoreTableStyle.defaultRowHoverColor,
    .background,
  ).className;
  // Per-state resizer fallback classes — the hover and the drag tint each
  // read their own `CoreTableStyle.default*` (both name
  // `defaultResizerColor`, so the emitted class is the same `bg-primary`
  // today) so a per-state override of the design default reaches Web
  // without the resolver re-deciding which state gets which token.
  final defaultResizerHoverClass = emitColor(
    null,
    CoreTableStyle.defaultResizerHoverColor,
    .background,
  ).className;
  final defaultResizerDragClass = emitColor(
    null,
    CoreTableStyle.defaultResizerDragColor,
    .background,
  ).className;

  // Body frozen cells borrow either the explicit table background or the
  // row background override (whichever the caller set). `ResizableTable`
  // opts out of the row fallback because it has no frozen cells today,
  // matching the pre-migration widget-level rule.
  final containerBgOverride = useRowBackgroundFallback
      ? (backgroundColorOverride ?? rowBackgroundColorOverride)
      : backgroundColorOverride;

  // surface:content — a face in the content layer alongside cards and body
  // panels (the sticky header rides inside the table's own scroll
  // container rather than floating over the page, so it stays content —
  // reverified). The table states no fill of its own by design, so the
  // marker/fill pair only applies once a caller actually paints one — the
  // same `CoreColor` that decides [containerBgOverride] above, read before
  // it resolves to a CSS string so [surfaceFillVar] can see its token.
  final containerFillCore = useRowBackgroundFallback
      ? (merged.backgroundColor ?? merged.rowBackgroundColor)
      : merged.backgroundColor;

  // ─── Local builders — root container ──────────────────

  /// Composes the outer CSS Grid container `<div>` Tailwind className.
  String buildRootClassName() {
    final parts = [
      WebLayout.grid,
      kControlShadowRestMarker,
      // Only once the table paints a fill of its own — an unmarked grid
      // with no background has nothing for a preset to make translucent,
      // and marking it anyway risks inheriting a marked ancestor's
      // published `--coui-surface-rgb` through CSS custom-property
      // inheritance (paired with the fill published below).
      if (containerFillCore != null) ...webSurfaceMarkerFor(.content),
    ];
    parts.add(fitContentWidth ? WebLayout.wMax : WebLayout.wFull);
    // The outer box exists only when its width is above 0; its colour is
    // the separator colour (class here, inline override below).
    if (outerBorderWidth > 0 && borderColorOverride == null) {
      parts.add(defaultBorderClass);
    }
    if (clipBehavior && !fitContentWidth) parts.add(WebLayout.overflowHidden);
    return parts.join(' ');
  }

  /// Composes the outer CSS Grid container `<div>` inline CSS.
  Styles buildRootInlineStyles() {
    final raw = {
      'grid-template-columns': columnTemplate,
      'grid-template-rows': rowTemplate,
    };
    if (clipBehavior && fitContentWidth) {
      raw['overflow'] = 'clip';
    }
    if (containerBgOverride != null) {
      raw['background-color'] = containerBgOverride;
    }
    if (outerBorderWidth > 0) {
      raw['border-style'] = 'solid';
      raw['border-width'] = strokeWidthCss(outerBorderWidth);
      if (borderColorOverride != null) {
        raw['border-color'] = borderColorOverride;
      }
    }
    // Border radius is always inline — the full four-corner shorthand
    // composed above. Default and override share this one surface.
    raw['border-radius'] = borderRadius;
    // The marker's other half — a preset restates this fill at a lower
    // alpha and cannot know which token the table chose. Empty (and a
    // no-op) when the fill is not token-bound, mirroring every other
    // surface on this axis.
    if (containerFillCore != null) {
      raw.addAll(surfaceFillVar(containerFillCore));
    }
    return Styles(raw: raw);
  }

  // ─── Local builders — per cell ────────────────────────

  /// Composes one cell `<div>` Tailwind className.
  String buildCellClassName(CoreTableCellDescriptor d) {
    final parts = ['transition-colors', 'duration-150'];
    final hasFrozenLeft = d.frozenLeft != null;
    final hasFrozenTop = d.frozenTop != null;
    final isFrozen = hasFrozenLeft || hasFrozenTop;

    final headerUsesFrozenBase =
        d.rowKind == .header && headerIsClear && isFrozen;
    final usesZebra =
        d.rowKind == .body &&
        d.bodyRowEven &&
        !d.selected &&
        !d.hovered &&
        rowAlternateOverride != null;
    final hasOverrideBg =
        (d.selected && rowSelectedOverride != null) ||
        (d.hovered && !d.selected && rowHoverOverride != null) ||
        (d.rowKind == .header &&
            !headerUsesFrozenBase &&
            headerBgOverride != null) ||
        (d.rowKind == .footer && footerBgOverride != null) ||
        usesZebra;
    if (!hasOverrideBg) {
      if (d.rowKind == .header) {
        final headerBgClass = headerUsesFrozenBase
            ? defaultFrozenBgClass
            : defaultHeaderBgClass;
        if (headerBgClass.isNotEmpty) parts.add(headerBgClass);
      } else if (d.rowKind == .footer) {
        parts.add(defaultFooterBgClass);
      } else if (isFrozen) {
        parts.add(defaultFrozenBgClass);
      }
      if (d.selected) {
        parts.add(defaultRowSelectedClass);
      } else if (d.hovered) {
        parts.add(defaultRowHoverClass);
      }
    }

    if (d.clickable && d.enabled) parts.add('cursor-pointer');
    // Disabled cells dim only their text colour (see the
    // `disabledForegroundColor` inline rule in `buildCellInlineStyles`)
    // — no blanket `opacity-50` here. Flutter's disabled treatment is
    // purely the text-foreground swap (no background/border dimming),
    // so a whole-cell opacity class would both diverge from Flutter and
    // double-dim the already-alpha-baked default disabled colour.
    // Cell typography role — the header reads
    // `CoreTableStyle.defaultHeaderTextStyle`, body / footer cells read
    // `defaultCellTextStyle`; the role class comes from `emitTypography`.
    // Per-instance slot overrides layer on top inline (see
    // `buildCellInlineStyles`).
    final typography = d.rowKind == .header
        ? (d.enabled ? headerTypography : headerDisabledTypography)
        : cellTypography;
    if (typography.className.isNotEmpty) parts.add(typography.className);
    // The separator's colour rides a class; its width is inline (see
    // `buildCellInlineStyles`), so `borderWidth` reaches the page whether or
    // not the colour is overridden — the way Flutter reads it.
    if (!d.isLastRow && borderColorOverride == null) {
      parts.add(defaultBorderClass);
    }
    return parts.join(' ');
  }

  /// Composes one cell `<div>` inline CSS.
  Styles buildCellInlineStyles(CoreTableCellDescriptor d) {
    final padding = d.rowKind == .header ? headerCellPadding : bodyCellPadding;
    final hasFrozenLeft = d.frozenLeft != null;
    final hasFrozenTop = d.frozenTop != null;
    final isFrozen = hasFrozenLeft || hasFrozenTop;
    final headerUsesFrozenBase =
        d.rowKind == .header && headerIsClear && isFrozen;
    final frozenBgOverride =
        frozenCellBgOverride ??
        (useRowBackgroundFallback
            ? (backgroundColorOverride ?? rowBackgroundColorOverride)
            : backgroundColorOverride);

    final raw = {
      'padding': padding.toValue(),
      'display': 'flex',
      'align-items': 'center',
    };
    // Row min-height — header reads `headerHeight`, body / footer read
    // `rowHeight`. Both stay absent unless the caller set the slot
    // (no design default; grid track sizing drives the natural height).
    final minHeight = d.rowKind == .header ? headerHeight : rowHeight;
    if (minHeight != null) {
      raw['min-height'] = '${minHeight / kRemDivisor}rem';
    }
    // Cell typography override — header cells read `headerTextStyle`,
    // body / footer cells read `cellTextStyle`. The slot's explicit
    // overlays (font-size / font-weight / letter-spacing / line-height,
    // and a raw colour) are emitted inline on top of the role class so
    // they win, mirroring Flutter's per-cell `DefaultTextStyle.merge`.
    final isHeaderCell = d.rowKind == .header;
    final typographyInline = isHeaderCell
        ? (d.enabled ? headerTypography : headerDisabledTypography).inline
        : cellTypography.inline;
    if (typographyInline != null) {
      raw.addAll(typographyInline);
    }
    // Body / footer foreground colour — only applies when the slot text
    // style above didn't already carry its own `color` (slot wins),
    // mirroring the Flutter resolver's `foreground(slotColor, disabled:)`
    // helper 1:1: disabled cells always resolve `disabledForegroundColor`
    // (override or the design default), enabled cells only emit inline
    // when `merged.foregroundColor` is explicitly set (the body default is
    // the ambient inherited text colour, so no explicit class / inline rule
    // is needed there). A header cell's colour is part of its typography
    // above.
    if (!isHeaderCell && cellTextStyle?.color == null) {
      final cellColor = d.enabled
          ? merged.foregroundColor?.toValue()
          : (merged.disabledForegroundColor ??
                    CoreTableStyle.defaultDisabledForegroundColor)
                .toValue();
      if (cellColor != null) {
        raw['color'] = cellColor;
      }
    }
    if (!d.isLastRow) {
      // border-width is a fixed-px design token (CoreStrokeWidth) and
      // intentionally bypasses text-scale ramping. A colour override states
      // the whole edge; otherwise the colour is a class and only the
      // width / style are inline.
      if (borderColorOverride != null) {
        raw['border-bottom'] =
            '${strokeWidthCss(borderWidth)} solid $borderColorOverride';
      } else {
        raw['border-bottom-width'] = strokeWidthCss(borderWidth);
        raw['border-bottom-style'] = 'solid';
      }
    }
    if (d.columnSpan > 1) raw['grid-column'] = 'span ${d.columnSpan}';
    if (d.rowSpan > 1) raw['grid-row'] = 'span ${d.rowSpan}';

    final String? bgOverride;
    if (d.selected && rowSelectedOverride != null) {
      bgOverride = rowSelectedOverride;
    } else if (d.hovered && !d.selected && rowHoverOverride != null) {
      bgOverride = rowHoverOverride;
    } else if (d.rowKind == .header &&
        !headerUsesFrozenBase &&
        headerBgOverride != null) {
      bgOverride = headerBgOverride;
    } else if (d.rowKind == .footer && footerBgOverride != null) {
      bgOverride = footerBgOverride;
    } else if (d.rowKind == .body &&
        d.bodyRowEven &&
        rowAlternateOverride != null) {
      // Zebra-stripe base for even body rows — layered under hover /
      // selection (which take precedence above), mirroring Flutter's
      // `rowBaseColor` fallback chain.
      bgOverride = rowAlternateOverride;
    } else {
      bgOverride = null;
    }
    if (bgOverride != null) {
      raw['background-color'] = bgOverride;
    }

    if (isFrozen) {
      raw['position'] = WebLayout.sticky;
      if (hasFrozenLeft) {
        raw['left'] = '${d.frozenLeft! / kRemDivisor}rem';
      }
      if (hasFrozenTop) {
        raw['top'] = '${d.frozenTop! / kRemDivisor}rem';
      }
      // Local intra-table stacking (frozen cell < frozen cell above other
      // frozen cell < resizer handle, see `buildResizerInlineStyles`) —
      // offsets from `CoreZIndex.z0` (1000) so they stay a magnitude below
      // the next named rung (dropdown menus, z10=1010) without claiming a
      // page-level semantic slot of their own.
      final z = hasFrozenLeft && hasFrozenTop
          ? '${CoreZIndex.z0 + 3}'
          : '${CoreZIndex.z0 + 2}';
      raw['z-index'] = z;
      final isBody = d.rowKind == .body;
      if ((isBody || headerUsesFrozenBase) &&
          frozenBgOverride != null &&
          !raw.containsKey('background-color')) {
        raw['background-color'] = frozenBgOverride;
      }
    } else if (d.positionRelative) {
      raw['position'] = WebLayout.relative;
    }

    return Styles(raw: raw);
  }

  // ─── Local builders — per resizer handle ──────────────

  /// Composes one resizer handle `<div>` Tailwind className.
  String buildResizerClassName(CoreTableResizerDescriptor d) {
    final parts = [
      WebLayout.absolute,
      'transition-colors',
      'duration-100',
      d.vertical ? 'cursor-col-resize' : 'cursor-row-resize',
    ];
    final hasOverride =
        (d.dragging && resizerDragOverride != null) ||
        (!d.dragging && d.hovered && resizerHoverOverride != null);
    if (!hasOverride) {
      if (d.dragging) {
        parts.add(defaultResizerDragClass);
      } else if (d.hovered) {
        parts.add(defaultResizerHoverClass);
      } else {
        parts.add('bg-transparent');
      }
    }
    return parts.join(' ');
  }

  /// Composes one resizer handle `<div>` inline CSS.
  Styles buildResizerInlineStyles(CoreTableResizerDescriptor d) {
    final half = resizerThickness / 2;
    // Extend the handle slightly beyond the cell bounds so it covers
    // the adjacent cell's separator border (1px) on both ends.
    const overshoot = 1.0;
    final String? bgColor;
    if (d.dragging && resizerDragOverride != null) {
      bgColor = resizerDragOverride;
    } else if (d.hovered && resizerHoverOverride != null) {
      bgColor = resizerHoverOverride;
    } else {
      bgColor = null;
    }
    final raw = {
      if (d.vertical) ...{
        // Drag-handle offsets are pixel-perfect alignment fixes
        // (separator overshoot) and intentionally bypass text-scale
        // ramping — matches the pre-rework behaviour.
        'right': '-${half}px', // design-token: handle alignment fixed-px
        'top': '-${overshoot}px', // design-token: handle alignment fixed-px
        'bottom': '-${overshoot}px', // design-token: handle alignment fixed-px
        'width': '${resizerThickness / kRemDivisor}rem',
      } else ...{
        'left': '-${overshoot}px', // design-token: handle alignment fixed-px
        'right': '-${overshoot}px', // design-token: handle alignment fixed-px
        'bottom': '-${half}px', // design-token: handle alignment fixed-px
        'height': '${resizerThickness / kRemDivisor}rem',
      },
      'z-index': '${CoreZIndex.z0 + 4}', // above frozen cells (z0+2/z0+3)
      'background-color': ?bgColor,
    };
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedTable(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    cells: [
      for (final d in cells)
        WebElementChrome(
          className: buildCellClassName(d),
          inlineStyles: buildCellInlineStyles(d),
        ),
    ],
    resizers: [
      for (final d in resizers)
        WebElementChrome(
          className: buildResizerClassName(d),
          inlineStyles: buildResizerInlineStyles(d),
        ),
    ],
  );
}

/// Converts a [CoreTableSize] spec to a CSS Grid track value.
String coreTableSizeToCssTrack(CoreTableSize size) {
  if (size is CoreFixedTableSize) return '${size.value / kRemDivisor}rem';
  if (size is CoreIntrinsicTableSize) return 'auto';
  // minmax(0, Nfr) lets cell content shrink below its intrinsic width so the
  // grid distributes width evenly regardless of per-cell content (badges,
  // wrapped text, etc.).
  if (size is CoreFlexTableSize) return 'minmax(0, ${size.flex}fr)';
  return 'minmax(0, 1fr)';
}
