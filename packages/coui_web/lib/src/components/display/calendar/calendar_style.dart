/// Single-entry resolver and Tailwind helpers for [Calendar] (Web).
///
/// Centralises the Epic #1302 / #1696 merge chain (`theme.calendar.style →
/// component.calendarStyle`) and converts the resolved [CoreCalendarStyle]
/// into a typed [ResolvedCalendar] bundle of [WebElementChrome] slots
/// (className + optional inline CSS). The widget reads from
/// [ResolvedCalendar] only — no inline Tailwind composition in
/// `co_calendar.dart`.
///
/// No `implements Styling` marker — `co_calendar.dart` reads
/// `ResolvedCalendar` directly via `resolved.{slot}.className /
/// inlineStyles`.
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

/// `display: contents` for the `role="gridcell"` wrapper around each day /
/// month / year button. The wrapper joins the ARIA tree (so the grid's
/// direct children are gridcells, per the APG grid pattern) without joining
/// the CSS box model, so the wrapped `Button` still lays out as if it were
/// the row's direct flex child.
const kCalendarGridCellStyles = Styles(raw: {'display': 'contents'});

/// Paint-ready chrome for Web `Calendar`.
///
/// DOM shape:
///
/// ```text
/// root (<div>, aria-label only — no role)
///   └─ container (<div>)
///        ├─ header (<div>)
///        │    ├─ nav prev (Button with navButtonStyle)
///        │    ├─ Gap (headerGridGapStyle)
///        │    ├─ title (Button ghost with navButtonStyle + headerLabelStyle)
///        │    ├─ Gap (headerGridGapStyle)
///        │    └─ nav next (Button with navButtonStyle)
///        ├─ Gap (headerGridGapStyle — header→grid vertical gap)
///        └─ grid (<div class="grid-wrapper" role="grid">)
///             ├─ row weekdays (<div class="row" role="row">)
///             │    └─ N × weekdayCell (<div role="columnheader">)
///             └─ rows days (<div class="row" role="row">)
///                  └─ N × gridcell wrapper (<div role="gridcell"
///                       style="display:contents">, [kCalendarGridCellStyles])
///                       ├─ rangeEndpointCell wrapping strip + pill
///                       ├─ inRangeCell
///                       └─ button-cell (none / today / selected — Button
///                          with dateCellStyle / monthYearCellStyle)
/// ```
///
/// `role="application"` used to sit on `root` — it told assistive tech to
/// hand every keystroke to the widget and suppress browse-mode navigation.
/// Nothing here ever intercepted arbitrary keys (day cells are individually
/// focusable `Button`s, reachable by ordinary Tab), so the role only turned
/// off navigation without buying anything. The month/year selection grids
/// (`buildMonthGrid` / `buildYearGrid` in `co_calendar.dart`) get the same
/// `grid` / `row` / `gridcell` treatment for the same reason — they are the
/// same kind of button matrix as the date grid, just without a header row.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots forwarded straight to child
///   unified widgets (`Button(buttonStyle: …)` /
///   `Icon(iconStyle: …)`). All slots are non-null — the resolver
///   merges the design-system default with the per-instance override
///   so `co_calendar.dart` reads `resolved.<slot>` as-is.
///
/// No scalar metadata (dayCellSize / yearGridSize / …)
/// is exposed — dimensional values are folded into the nested
/// `CoreButtonStyle` / `CoreIconStyle` slots, and the opacity for
/// from-another-month cells lives baked into the [fadedCellWrap]
/// `inlineStyles`. The logic-only grid counts (`yearGridSize` /
/// `monthGridColumns` / `yearGridColumns`) are NOT carried here — they
/// are behavioural layout-loop identifiers consumed by `co_calendar`'s
/// month / year grid builders, not paint chrome, so the widget reads
/// them from the merge chain via [resolveCalendarGrid] (the
/// number_ticker separate-resolver pattern).
class ResolvedCalendar implements WebResolvedChrome {
  /// Creates a [ResolvedCalendar].
  const ResolvedCalendar({
    required this.root,
    required this.container,
    required this.headerRow,
    required this.headerTitle,
    required this.rangeHeaderSide,
    required this.rangeGridRow,
    required this.navPlaceholder,
    required this.grid,
    required this.yearGrid,
    required this.gridRow,
    required this.gridRowGapped,
    required this.weekdayCell,
    required this.rangeEndpointCell,
    required this.rangeStripStart,
    required this.rangeStripEnd,
    required this.rangeEndpointPill,
    required this.inRangeCell,
    required this.headerGridGapStyle,
    required this.fadedCellWrap,
    required this.selectedOverride,
    required this.todayOverride,
    required this.navButtonStyle,
    required this.dateCellStyle,
    required this.dateCellSelectedStyle,
    required this.dateCellTodayStyle,
    required this.monthYearCellStyle,
    required this.headerButtonStyle,
    required this.arrowIconStyle,
  });

  /// Outermost `<div>` chrome (aria-label only — no role).
  @override
  final WebElementChrome root;

  /// Inner column container (flex-col) holding header + grid.
  final WebElementChrome container;

  /// Header row (`<div>`) — prev / title / next.
  final WebElementChrome headerRow;

  /// Header title wrap (flex-1 so the title fills the centre).
  final WebElementChrome headerTitle;

  /// Range-mode header side wrap (flex item containing nav + title for
  /// one calendar).
  final WebElementChrome rangeHeaderSide;

  /// Range-mode dual-grid row (two grids side by side).
  final WebElementChrome rangeGridRow;

  /// Placeholder square sized like the nav-button (for symmetric
  /// range mode layout).
  final WebElementChrome navPlaceholder;

  /// Grid (date / month) column wrapper — vertical row gap from
  /// `cellSpacing`.
  final WebElementChrome grid;

  /// Year-grid column wrapper — vertical row gap derived from
  /// `yearRowSpacing` (distinct from [grid]'s `cellSpacing`,
  /// matching the Flutter year grid).
  final WebElementChrome yearGrid;

  /// Single grid row (centered).
  final WebElementChrome gridRow;

  /// Single grid row with horizontal gap (month / year grids).
  final WebElementChrome gridRowGapped;

  /// Weekday header cell ("Su" / "Mo" / …).
  final WebElementChrome weekdayCell;

  /// Range endpoint cell wrapper (`relative`).
  final WebElementChrome rangeEndpointCell;

  /// Half-strip behind a range-endpoint cell — start variant
  /// (right-0).
  final WebElementChrome rangeStripStart;

  /// Half-strip behind a range-endpoint cell — end variant
  /// (left-0).
  final WebElementChrome rangeStripEnd;

  /// Range endpoint pill (the actual filled circle at start / end).
  final WebElementChrome rangeEndpointPill;

  /// In-range cell (continuous strip, no radius).
  final WebElementChrome inRangeCell;

  /// Nested [CoreGapStyle] slot for the gap between header buttons /
  /// title and between the header row and the grid. The widget
  /// forwards this slot straight to `Gap(gapStyle: …)` — Flutter
  /// parity (same slot, same widget).
  final CoreGapStyle headerGridGapStyle;

  /// Wrap chrome applied to a from-another-month cell — carries the
  /// faded opacity rule as `inlineStyles`. `co_calendar` wraps every
  /// outer-month cell in a `<div>` with this chrome.
  final WebElementChrome fadedCellWrap;

  /// Inline override wrapper for the `selected` cell.
  final WebElementChrome selectedOverride;

  /// Inline override wrapper for the `today` cell.
  final WebElementChrome todayOverride;

  /// Nested nav-button style — passed to each `Button` used to
  /// render prev / next month navigation. Pre-merged: design-system
  /// dimensional default (`dayCellSize` square, zero padding) merged
  /// with the per-instance `navButtonStyle` override.
  final CoreButtonStyle navButtonStyle;

  /// Nested header-button style — passed to the `Button` used to
  /// render the header title (e.g. "May 2026"). Pre-merged: same nav
  /// dimensional default + the resolved [headerTextStyle] via
  /// `labelStyle` slot.
  final CoreButtonStyle headerButtonStyle;

  /// Nested date-cell style — passed to each day-cell `Button`.
  /// Pre-merged: design-system dimensional default (`dayCellSize`
  /// square, zero padding, [cellTextStyle] as `labelStyle`) merged
  /// with the per-instance `dateCellStyle` override.
  final CoreButtonStyle dateCellStyle;

  /// Nested date-cell style for a SELECTED cell (single / multi selection,
  /// and a range endpoint folded back to a single pill at a row edge) —
  /// [dateCellStyle] with the `selectedTextStyle` slot over the cell slot as
  /// the `Button`'s `labelStyle`, so the selected weight reaches the label
  /// (the Flutter twin's `dateCellSelectedStyle` carries the same slot).
  final CoreButtonStyle dateCellSelectedStyle;

  /// Nested date-cell style for TODAY's cell — [dateCellStyle] with the
  /// `todayTextStyle` slot as the `Button`'s `labelStyle`.
  ///
  /// Separate because that slot states a typography role and weight, which an
  /// inline override cannot carry: on Web the role is a class on the label.
  final CoreButtonStyle dateCellTodayStyle;

  /// Nested month/year cell style — passed to each month / year
  /// grid `Button`. Pre-merged: same dimensional default as
  /// [dateCellStyle] except `width` uses `monthCellWidth`.
  final CoreButtonStyle monthYearCellStyle;

  /// Nested arrow-icon style — passed to the prev / next arrow
  /// `Icon`s. Pre-merged: design-system default
  /// ([CoreCalendarStyle.defaultArrowIconStyle]) merged with the
  /// per-instance `arrowIconStyle` override.
  final CoreIconStyle arrowIconStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves the calendar Style chain to a typed [ResolvedCalendar]
/// bundle of [WebElementChrome] slots + nested `CoreXxxStyle` slots.
///
/// Merge chain:
///
/// ```text
/// design system default for calendar
///   → context.theme.coreComponentTheme.calendar.style
///   → component.calendarStyle
/// ```
ResolvedCalendar resolveCalendar(
  BuildContext context, {
  CoreCalendarStyle? calendarStyle,
}) {
  final calendarTheme = context.theme.coreComponentTheme?.calendar;

  // ─── Merge chain ──────────────────────────────────
  final merged = resolveStyleChain(const CoreCalendarStyle(), [
    calendarTheme?.style,
    calendarStyle,
  ]);

  // ─── Dimensional fallback ─────────────────────────
  final dayCellSize =
      merged.dayCellSize ?? CoreCalendarStyle.defaultDayCellSize;
  final monthCellWidth =
      merged.monthCellWidth ?? CoreCalendarStyle.defaultMonthCellWidth;
  final cellSpacing =
      merged.cellSpacing ?? CoreCalendarStyle.defaultCellSpacing;
  // Resolve nested gap-style slots — forwarded straight to `Gap`
  // children in `co_calendar.dart` (Flutter parity: same slot, same
  // widget — no inline CSS emission from the resolver).
  final headerGridGapStyle = CoreCalendarStyle.defaultHeaderGridGapStyle.merge(
    merged.headerGridGapStyle,
  );
  final yearRowSpacing =
      merged.yearRowSpacing ?? CoreCalendarStyle.defaultYearRowSpacing;
  final endpointPillBorderRadius =
      merged.endpointPillBorderRadius ??
      CoreCalendarStyle.defaultEndpointPillBorderRadius;
  final fadedOpacity =
      merged.fadedOpacity ?? CoreCalendarStyle.defaultFadedOpacity;

  // ─── Colour EMIT (Stage 2, Web, theme-free) ─────────
  // sb8 — `selectedTextColor` / `todayTextColor` / `rangeSelectionTextColor`
  // / `weekdayLabelColor` raw fields removed; colour now lives inside the
  // matching nested `CoreTextStyle` slot. Each fill / text colour routes
  // through `emitColor` — a single class-XOR-inline decision per value.
  // Token values (default + token override) emit a `bg-{token}` / `text-
  // {token}` Tailwind class so they stay dark-mode reactive; a raw override
  // lands inline. No `scheme.resolve` (a no-op on Web) and no hand-rolled
  // `if (override != null)` branch (status / chip pattern).
  final selectedBgEmit = emitColor(
    merged.selectedColor,
    CoreCalendarStyle.defaultSelectedColor,
    .background,
  );
  final selectedTextEmit = emitColor(
    merged.selectedTextStyle?.color,
    CoreCalendarStyle.defaultSelectedTextStyle.color!,
    .text,
  );
  final rangeBgEmit = emitColor(
    merged.rangeSelectionColor,
    CoreCalendarStyle.defaultRangeSelectionColor,
    .background,
  );
  final rangeTextEmit = emitColor(
    merged.rangeSelectionTextStyle?.color,
    CoreCalendarStyle.defaultRangeSelectionTextStyle.color!,
    .text,
  );
  final weekdayLabelColor =
      CoreCalendarStyle.defaultWeekdayLabelTextStyle
          .merge(merged.weekdayLabelTextStyle)
          .color ??
      CoreCalendarStyle.defaultWeekdayLabelTextStyle.color!;
  // Today's cell has no design-system default fill / text colour (it
  // defers to the child `Button.secondary`), so its override wrapper
  // emits only when the caller sets a colour. Route the override through
  // `emitColor` (with the colour itself as the fallback so a token override
  // → class / null inline → no wrapper, a raw override → inline) and skip
  // entirely when the slot is null.
  final todayColorOverride = merged.todayColor;
  final todayTextColorOverride = CoreCalendarStyle.defaultTodayTextStyle
      .merge(merged.todayTextStyle)
      .color;
  final todayBgEmit = todayColorOverride == null
      ? const (className: '', inline: null)
      : emitColor(todayColorOverride, todayColorOverride, .background);
  final todayTextEmit = todayTextColorOverride == null
      ? const (className: '', inline: null)
      : emitColor(todayTextColorOverride, todayTextColorOverride, .text);

  // ─── Cell / header text style — Core (passed to Button.labelStyle) ──
  final cellLabelStyle = CoreCalendarStyle.defaultCellTextStyle.merge(
    merged.cellTextStyle,
  );
  final headerLabelStyle = CoreCalendarStyle.defaultHeaderTextStyle.merge(
    merged.headerTextStyle,
  );

  // Weekday typography — combine the role/overlay slot (`weekdayTextStyle`,
  // default `labelMedium`) with the dedicated colour slot
  // (`weekdayLabelTextStyle`, default `labelMedium` + `onSurface`) into one
  // `CoreTextStyle`, then route it through `emitTypography` (single
  // canonical path: role class + explicit-overlay inline). The fallback
  // default carries the `onSurface` colour; the combined override carries
  // the per-instance role/scalar overlays plus whichever colour slot the
  // caller set (`weekdayTextStyle.color` wins over `weekdayLabelTextStyle
  // .color`), so a colour-only override on either slot still lands.
  final weekdayCombinedDefault = CoreCalendarStyle.defaultWeekdayTextStyle
      .copyWith(color: weekdayLabelColor);
  final weekdayOverrideColor =
      merged.weekdayTextStyle?.color ?? merged.weekdayLabelTextStyle?.color;
  final weekdayCombinedOverride =
      (merged.weekdayTextStyle ?? const CoreTextStyle()).copyWith(
        color: weekdayOverrideColor,
      );
  final weekdayEmit = emitTypography(
    weekdayCombinedOverride,
    weekdayCombinedDefault,
  );

  // ─── Nested CoreXxxStyle slots — pre-merged ─────────
  // Default nav-button: square (dayCellSize × dayCellSize) with zero
  // padding so the arrow icon centers cleanly.
  final navButtonDefault = CoreCalendarStyle.defaultNavButtonStyle.copyWith(
    height: dayCellSize,
    width: dayCellSize,
  );
  final navButtonStyle = navButtonDefault.merge(merged.navButtonStyle);

  // Default header-button: dayCellSize tall, zero padding, header
  // typography. Width auto (expanded by `flex-1` on title wrap).
  final headerButtonDefault = CoreCalendarStyle.defaultNavButtonStyle.copyWith(
    height: dayCellSize,
    labelStyle: headerLabelStyle,
  );
  final headerButtonStyle = headerButtonDefault.merge(merged.navButtonStyle);

  // Default date-cell: square (dayCellSize × dayCellSize), zero
  // padding, cell typography.
  final dateCellDefault = CoreCalendarStyle.defaultDateCellStyle.copyWith(
    height: dayCellSize,
    width: dayCellSize,
    labelStyle: cellLabelStyle,
  );
  final dateCellStyle = dateCellDefault.merge(merged.dateCellStyle);

  // The selected cell's label — the cell slot with the `selectedTextStyle`
  // slot over it, the same composition as today's below. Read by the
  // selected cell `Button` and by the hand-drawn range endpoint pill, so a
  // single selection and a range endpoint carry one label.
  final selectedLabelStyle = cellLabelStyle.merge(
    CoreCalendarStyle.defaultSelectedTextStyle.merge(merged.selectedTextStyle),
  );
  final dateCellSelectedStyle = dateCellDefault
      .copyWith(labelStyle: selectedLabelStyle)
      .merge(merged.dateCellStyle);
  final pillLabelEmit = emitTypography(null, selectedLabelStyle);
  final inRangeLabelEmit = emitTypography(null, cellLabelStyle);

  // Today's cell takes the `todayTextStyle` slot WHOLE, as its Button's
  // `labelStyle`.
  //
  // `defaultTodayTextStyle` states a typography ROLE (`bodySmall`), a weight
  // (SemiBold) and a colour (`primary`); reading only `.color` off it would
  // drop the role and the weight — the `.color`-only flattening
  // `widget/render-only.md` forbids. The Flutter twin forwards the same slot.
  //
  // `labelStyle` is where a `Button`'s typography lives, and every cell is a
  // `Button`. Merged over the cell default so a caller's `dateCellStyle` still
  // wins, same order as the other cell styles.
  final dateCellTodayStyle = dateCellDefault
      .copyWith(
        borderColor:
            merged.todayBorderColor ??
            CoreCalendarStyle.defaultTodayBorderColor,
        borderWidth:
            merged.todayBorderWidth ??
            CoreCalendarStyle.defaultTodayBorderWidth,
        labelStyle: cellLabelStyle.merge(
          CoreCalendarStyle.defaultTodayTextStyle.merge(merged.todayTextStyle),
        ),
      )
      .merge(merged.dateCellStyle);

  // Default month/year-cell: dayCellSize tall, monthCellWidth wide,
  // zero padding, cell typography.
  final monthYearCellDefault = CoreCalendarStyle.defaultDateCellStyle.copyWith(
    height: dayCellSize,
    width: monthCellWidth,
    labelStyle: cellLabelStyle,
  );
  final monthYearCellStyle = monthYearCellDefault.merge(merged.dateCellStyle);

  // Default arrow-icon: design-system default Style slot.
  final arrowIconStyle = CoreCalendarStyle.defaultArrowIconStyle.merge(
    merged.arrowIconStyle,
  );

  // ─── Helper builders ──────────────────────────────

  WebElementChrome buildRoot() => const .new(className: WebLayout.inlineFlex);

  WebElementChrome buildContainer() => const .new(
    className: '${WebLayout.inlineFlex} ${WebLayout.flexCol}',
  );

  WebElementChrome buildHeaderRow() => const .new(
    className: WebLayout.flexItemsCenter,
  );

  WebElementChrome buildHeaderTitle() => const .new(
    // A month name plus a year in whatever the locale spells them, inside
    // a button the header row sizes. State what happens when it does not
    // fit rather than letting it spill — the Flutter twin ellipsizes for
    // the same reason, as the weekday cell already does on both sides.
    className: '${WebLayout.flex1} ${WebLayout.truncate}',
  );

  WebElementChrome buildRangeHeaderSide() => const .new(
    className: '${WebLayout.flex} ${WebLayout.itemsCenter} ${WebLayout.flex1}',
  );

  WebElementChrome buildRangeGridRow() => const .new(
    className: WebLayout.flexItemsStart,
  );

  // A day cell's side is a dimension, so it goes out on the size scale
  // (`--coui-size-*`). The spacing scale's variables are what a density
  // re-points; a cell sized through them would shrink on Web only — the
  // Flutter cell is `dayCellSize` and does not move.
  WebElementChrome buildNavPlaceholder() => .new(
    className: 'w-${dayCellSize.tailwindSize} h-${dayCellSize.tailwindSize}',
  );

  WebElementChrome buildGrid() => .new(
    className:
        '${WebLayout.flex} ${WebLayout.flexCol} gap-${cellSpacing.tailwindSpace}',
  );

  // Year-grid column wrapper — vertical row gap is driven by the flat
  // `yearRowSpacing` slot (mirrors the Flutter year grid, where rows
  // are separated by `Column.spacing = yearRowSpacing` rather than
  // `cellSpacing`).
  WebElementChrome buildYearGrid() => .new(
    className:
        '${WebLayout.flex} ${WebLayout.flexCol} gap-${yearRowSpacing.tailwindSpace}',
  );

  WebElementChrome buildGridRow({required bool withGap}) => .new(
    className: withGap
        ? '${WebLayout.flex} ${WebLayout.justifyCenter} gap-${cellSpacing.tailwindSpace}'
        : WebLayout.flexJustifyCenter,
  );

  WebElementChrome buildWeekdayCell() {
    final classList = [
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      'w-${dayCellSize.tailwindSize}',
      'h-${dayCellSize.tailwindSize}',
      // A fixed square holding a locale string: state what happens when
      // it does not fit rather than letting it spill out of the grid.
      // The Flutter twin ellipsizes for the same reason.
      WebLayout.truncate,
      // Role class (+ token-colour class) from the single emit path; any
      // explicit scalar or raw-colour overlay lands in the inline bundle.
      weekdayEmit.className,
    ];
    final inline = weekdayEmit.inline;
    return .new(
      className: classList.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: inline == null ? null : Styles(raw: inline),
    );
  }

  WebElementChrome buildRangeEndpointCell() => .new(
    className:
        '${WebLayout.relative} '
        'w-${dayCellSize.tailwindSize} h-${dayCellSize.tailwindSize} '
        'cursor-pointer',
  );

  WebElementChrome buildRangeStrip({required bool isStart}) {
    final classList = [
      WebLayout.absolute,
      WebLayout.topZero,
      WebLayout.bottomZero,
      isStart ? WebLayout.rightZero : WebLayout.leftZero,
      WebLayout.wHalf,
      rangeBgEmit.className,
    ];
    final inline = rangeBgEmit.inline;
    return .new(
      className: classList.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: inline == null ? null : Styles(raw: inline),
    );
  }

  WebElementChrome buildRangeEndpointPill() {
    // Border radius is **always** emitted inline (`(merged ?? default)
    // .toValue()`) — no `rounded-*` Tailwind class — so the override and
    // the default share one CSS surface and the resolved chrome reflects
    // `merged.endpointPillBorderRadius` directly (Epic #1603 single inline
    // signature). Token-bound corners still emit `var(--coui-radius-N)`
    // via `core_to_css`, so the default (radius8) is byte-identical to the
    // former `rounded-md` class.
    final classList = [
      WebLayout.absolute,
      WebLayout.insetZero,
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      // The selected label (role + token colour, weight overlay inline) —
      // the same `CoreTextStyle` the selected cell `Button` takes.
      pillLabelEmit.className,
      selectedBgEmit.className,
    ];
    final raw = {
      'border-radius': endpointPillBorderRadius.toValue(),
      // Local lift above the cell's own background — not a page-level
      // overlay, so an inline `z-index` (not a `z-` class: the value
      // isn't a registered `zIndex` scale step) sourced from
      // `CoreZIndex.z0 + 1`, a magnitude below the first named rung.
      'z-index': '${CoreZIndex.z0 + 1}',
      ...?pillLabelEmit.inline,
      ...?selectedBgEmit.inline,
    };
    return .new(
      className: classList.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(raw: raw),
    );
  }

  WebElementChrome buildInRangeCell() {
    final classList = [
      WebLayout.inlineFlex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      'w-${dayCellSize.tailwindSize}',
      'h-${dayCellSize.tailwindSize}',
      // The cell slot — the label a plain date `Button` takes, so a date
      // inside the band reads at the same role as one outside it.
      inRangeLabelEmit.className,
      'select-none',
      rangeBgEmit.className,
      rangeTextEmit.className,
    ];
    final raw = <String, String>{
      ...?inRangeLabelEmit.inline,
      ...?rangeBgEmit.inline,
      ...?rangeTextEmit.inline,
    };
    return .new(
      className: classList.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: raw.isEmpty ? null : Styles(raw: raw),
    );
  }

  WebElementChrome buildFadedCellWrap() => .new(
    className: '',
    inlineStyles: Styles(raw: {'opacity': '$fadedOpacity'}),
  );

  WebElementChrome buildSelectedOverride() {
    // Override wrapper carries ONLY the raw-colour part of a per-instance
    // override (token overrides already live on the child `Button`'s
    // `dateCellSelectedStyle`, which the cell resolves directly). So we
    // route each colour through `emitColor` and keep only `.inline` — a
    // token override yields an empty class + null inline → no wrapper; a
    // raw override yields the inline rule the wrapper applies.
    final raw = <String, String>{
      ...?selectedBgEmit.inline,
      ...?selectedTextEmit.inline,
    };
    return .new(
      className: '',
      inlineStyles: raw.isEmpty ? null : Styles(raw: raw),
    );
  }

  WebElementChrome buildTodayOverride() {
    // As [buildSelectedOverride] but for today's cell — only the raw
    // colour part of a `todayColor` / `todayTextStyle.color` override lands
    // here; the token part rides the child `Button`'s `dateCellTodayStyle`.
    final raw = <String, String>{
      ...?todayBgEmit.inline,
      ...?todayTextEmit.inline,
    };
    return .new(
      className: '',
      inlineStyles: raw.isEmpty ? null : Styles(raw: raw),
    );
  }

  return ResolvedCalendar(
    root: buildRoot(),
    container: buildContainer(),
    headerRow: buildHeaderRow(),
    headerTitle: buildHeaderTitle(),
    rangeHeaderSide: buildRangeHeaderSide(),
    rangeGridRow: buildRangeGridRow(),
    navPlaceholder: buildNavPlaceholder(),
    grid: buildGrid(),
    yearGrid: buildYearGrid(),
    gridRow: buildGridRow(withGap: false),
    gridRowGapped: buildGridRow(withGap: true),
    weekdayCell: buildWeekdayCell(),
    rangeEndpointCell: buildRangeEndpointCell(),
    rangeStripStart: buildRangeStrip(isStart: true),
    rangeStripEnd: buildRangeStrip(isStart: false),
    rangeEndpointPill: buildRangeEndpointPill(),
    inRangeCell: buildInRangeCell(),
    headerGridGapStyle: headerGridGapStyle,
    fadedCellWrap: buildFadedCellWrap(),
    selectedOverride: buildSelectedOverride(),
    todayOverride: buildTodayOverride(),
    navButtonStyle: navButtonStyle,
    dateCellStyle: dateCellStyle,
    dateCellSelectedStyle: dateCellSelectedStyle,
    dateCellTodayStyle: dateCellTodayStyle,
    monthYearCellStyle: monthYearCellStyle,
    headerButtonStyle: headerButtonStyle,
    arrowIconStyle: arrowIconStyle,
  );
}

/// Resolves the behavioural grid counts for `Calendar` — the year-grid
/// item count, the month / year subgrid column counts and the cap on marker
/// dots drawn for one date. These are
/// logic-only layout-loop identifiers consumed by `co_calendar`'s month /
/// year grid builders (chunking buttons into rows) and the prev/next
/// year-page step, not paint chrome.
///
/// Walks the same merge chain as [resolveCalendar]
/// (design-system default → `CoreCalendarTheme.style` →
/// `component.calendarStyle`). Kept as a separate `resolveCo*` entry
/// point so [ResolvedCalendar] stays pure paint-ready chrome
/// (number_ticker separate-resolver pattern).
({
  int yearGridSize,
  int monthGridColumns,
  int yearGridColumns,
  int markerMaxCount,
})
resolveCalendarGrid(
  BuildContext context, {
  CoreCalendarStyle? calendarStyle,
}) {
  final calendarTheme = context.theme.coreComponentTheme?.calendar;
  final merged = resolveStyleChain(const CoreCalendarStyle(), [
    calendarTheme?.style,
    calendarStyle,
  ]);
  return (
    yearGridSize: merged.yearGridSize ?? CoreCalendarStyle.defaultYearGridSize,
    monthGridColumns:
        merged.monthGridColumns ?? CoreCalendarStyle.defaultMonthGridColumns,
    yearGridColumns:
        merged.yearGridColumns ?? CoreCalendarStyle.defaultYearGridColumns,
    markerMaxCount:
        merged.markerMaxCount ?? CoreCalendarStyle.defaultMarkerMaxCount,
  );
}

// ═══════════════════════════════════════════════════
// Date marker — per-item chrome for one marked day cell
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for a single marked day cell in a `Calendar`.
///
/// DOM shape (`calendar.dart` wraps the day cell when the caller's
/// `markerBuilder` returns a marker for that date):
///
/// ```text
/// root (<div>, relative inline-flex)
///   ├─ day cell (Button / hand-drawn range cell)
///   │    └─ … day number + label (<span class="sr-only">)
///   └─ row (<div aria-hidden>, absolute bottom strip, flex centred,
///        padding + inline gap, pointer-events none)
///        └─ N × dot (<div>, inline width/height, radius, fill)
/// ```
///
/// Resolved per marked cell rather than folded into [ResolvedCalendar]:
/// the dot fill depends on the date's own `CoreCalendarMarker.color` and on
/// that cell's selection state. How many dots to draw is a layout-loop
/// count, read from [resolveCalendarGrid] (`markerMaxCount`) like the other
/// grid counts.
class ResolvedCalendarMarker implements WebResolvedChrome {
  /// Creates a [ResolvedCalendarMarker].
  const ResolvedCalendarMarker({
    required this.root,
    required this.row,
    required this.dot,
    required this.label,
  });

  /// Positioning wrapper around the day cell — the anchor the dot row is
  /// placed against.
  @override
  final WebElementChrome root;

  /// Dot row — pinned to the cell's bottom edge, out of the pointer path.
  final WebElementChrome row;

  /// One dot — size, corner radius and fill.
  final WebElementChrome dot;

  /// Visually hidden text carrying the marker's meaning into the day cell's
  /// accessible name.
  final WebElementChrome label;
}

/// Resolves the chrome for one marked day cell to a typed
/// [ResolvedCalendarMarker].
///
/// Walks the same merge chain as [resolveCalendar]:
///
/// ```text
/// design system default for calendar
///   → context.theme.coreComponentTheme.calendar.style
///   → component.calendarStyle
/// ```
///
/// [lookup] is the cell's semantic selection state — a build-time value the
/// Flutter twin receives the same way. A selected date or range endpoint
/// takes `selectedMarkerColor` and a date inside a range takes
/// `rangeMarkerColor` whatever colour the marker names, so the dots stay
/// legible on the selection fill they sit on.
ResolvedCalendarMarker resolveCalendarMarker(
  BuildContext context, {
  required CoreCalendarMarker marker,
  required CoreCalendarValueLookup lookup,
  CoreCalendarStyle? calendarStyle,
}) {
  final calendarTheme = context.theme.coreComponentTheme?.calendar;

  // ─── Merge chain ──────────────────────────────────
  final merged = resolveStyleChain(const CoreCalendarStyle(), [
    calendarTheme?.style,
    calendarStyle,
  ]);

  // ─── Stage 1 — RESOLVE ────────────────────────────
  final markerSize = merged.markerSize ?? CoreCalendarStyle.defaultMarkerSize;
  final markerSpacing =
      merged.markerSpacing ?? CoreCalendarStyle.defaultMarkerSpacing;

  // ─── Stage 2 — EMIT (theme-free) ──────────────────
  // On a selection fill the state's own dot colour always wins so the dots
  // stay legible; elsewhere the marker's own colour beats the style's
  // `markerColor`. Each route still goes class-XOR-inline.
  final dotColorEmit = switch (lookup) {
    .selected || .start || .end => emitColor(
      merged.selectedMarkerColor,
      CoreCalendarStyle.defaultSelectedMarkerColor,
      .background,
    ),
    .inRange => emitColor(
      merged.rangeMarkerColor,
      CoreCalendarStyle.defaultRangeMarkerColor,
      .background,
    ),
    .none => emitColor(
      marker.color ?? merged.markerColor,
      CoreCalendarStyle.defaultMarkerColor,
      .background,
    ),
  };
  final dotRadiusEmit = emitRadius(
    merged.markerBorderRadius,
    CoreCalendarStyle.defaultMarkerBorderRadius,
  );
  final rowPaddingEmit = emitSpacing(
    merged.markerPadding,
    CoreCalendarStyle.defaultMarkerPadding,
    prefix: 'p',
    cssProperty: 'padding',
  );
  final dotSizeCss = '${markerSize / kRemDivisor}rem';
  final rowGapCss = spaceCss(markerSpacing);

  // ─── Helper builders ──────────────────────────────

  WebElementChrome buildRoot() => const .new(
    className: '${WebLayout.relative} ${WebLayout.inlineFlex}',
  );

  WebElementChrome buildRow() {
    final classList = [
      WebLayout.absolute,
      WebLayout.insetXZero,
      WebLayout.bottomZero,
      WebLayout.flexJustifyCenter,
      WebLayout.pointerEventsNone,
      rowPaddingEmit.className,
    ];
    return .new(
      className: classList.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {'gap': rowGapCss, ...?rowPaddingEmit.inline},
      ),
    );
  }

  WebElementChrome buildDot() {
    final classList = [
      WebLayout.shrinkZero,
      dotRadiusEmit.className,
      dotColorEmit.className,
    ];
    return .new(
      className: classList.where((cls) => cls.isNotEmpty).join(' '),
      inlineStyles: Styles(
        raw: {
          'width': dotSizeCss,
          'height': dotSizeCss,
          ...?dotRadiusEmit.inline,
          ...?dotColorEmit.inline,
        },
      ),
    );
  }

  WebElementChrome buildLabel() => const .new(className: WebLayout.srOnly);

  return ResolvedCalendarMarker(
    root: buildRoot(),
    row: buildRow(),
    dot: buildDot(),
    label: buildLabel(),
  );
}
