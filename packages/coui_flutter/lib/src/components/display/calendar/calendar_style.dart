/// Single-entry resolver for the Flutter `Calendar`.
///
/// Encapsulates Epic #1302 / #1696 merge chain (`theme.calendar.style →
/// widget.calendarStyle`) and converts the resolved [CoreCalendarStyle]
/// to a typed [ResolvedCalendar] paint-ready bundle. The widget
/// reads from [ResolvedCalendar] only — no direct
/// `theme.coreComponentTheme` or `.merge()` calls inside `build`.
library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output — paint-ready chrome for `Calendar`.
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Calendar`.
///
/// Widget tree (`co_calendar.dart` builds):
///
/// ```text
/// IntrinsicWidth
///   └─ Column
///        ├─ Row (header — prev / title / next, separated by Gap with
///        │     headerGridGapStyle)
///        ├─ Gap (headerGridGapStyle — header→grid vertical gap)
///        └─ View content (date / month / year grid)
///             └─ Date grid:
///                  ├─ Row weekdays (DefaultTextStyle wrapped)
///                  ├─ Row*N days (each cell sized dayCellSize), rows
///                  │   separated by Column.spacing = cellSpacing
///                  └─ Year-grid rows separated by Column.spacing =
///                      yearRowSpacing
/// ```
///
/// Carries paint-ready values (`Color` / `BorderRadius` / `TextStyle`)
/// so `build` reads `resolved.X` once and forwards without re-fallback.
class ResolvedCalendar {
  /// Creates a [ResolvedCalendar].
  const ResolvedCalendar({
    required this.dayCellSize,
    required this.monthCellWidth,
    required this.cellSpacing,
    required this.headerGridGapStyle,
    required this.headerGridGap,
    required this.yearRowSpacing,
    required this.endpointPillBorderRadius,
    required this.fadedOpacity,
    required this.yearGridSize,
    required this.monthGridColumns,
    required this.yearGridColumns,
    required this.navButtonStyle,
    required this.headerButtonStyle,
    required this.dateCellNormalStyle,
    required this.dateCellSelectedStyle,
    required this.dateCellTodayStyle,
    required this.monthYearCellStyle,
    required this.arrowIconStyle,
    required this.cellLabelTextStyle,
    required this.headerLabelTextStyle,
    required this.weekdayLabelTextStyle,
    required this.todayTextColor,
    required this.rangeSelectionColor,
    required this.rangeSelectionTextColor,
  });

  /// Day / month / year cell size (logical px, pre-scaling).
  final double dayCellSize;

  /// Month / year grid cell width (logical px, pre-scaling).
  final double monthCellWidth;

  /// Gap between calendar grid cells (logical px, post-scaling). Used
  /// directly as `Column.spacing` for the date-grid rows and as a raw
  /// `Gap(size:)` for month-grid row separators.
  final double cellSpacing;

  /// Nested [CoreGapStyle] slot for the header-row → grid gap (and the
  /// inter-button gap inside the header row). Forwarded raw to
  /// `Gap(gapStyle: …)` — `Gap` applies `theme.scaling` itself, so
  /// the slot stays in pre-scaling units (no double-scale).
  final CoreGapStyle headerGridGapStyle;

  /// Paired post-scaling raw double derived from [headerGridGapStyle]
  /// for arithmetic / `SizedBox.width` consumers (the range-mode header
  /// row needs `dayCellSize + headerGridGap` as a fixed spacer). Equal
  /// to `(default ?? merged.headerGridGapStyle).size * theme.scaling`.
  final double headerGridGap;

  /// Row gap between year-grid rows (logical px, post-scaling). Used
  /// directly as `Column.spacing` for the year-grid rows.
  final double yearRowSpacing;

  /// Border radius for the range endpoint pill.
  final BorderRadius endpointPillBorderRadius;

  /// Opacity applied to dates from another month.
  final double fadedOpacity;

  /// Total items in the year grid.
  final int yearGridSize;

  /// Month grid columns.
  final int monthGridColumns;

  /// Year grid columns.
  final int yearGridColumns;

  /// Prev / next navigation button style — the zero-padding base with the
  /// (pre-scaled) day-cell size baked into `height` / `width` and the
  /// per-instance `navButtonStyle` override merged on top. Forwarded
  /// straight to `Button(buttonStyle: …)`.
  final CoreButtonStyle navButtonStyle;

  /// Header button style — as [navButtonStyle] but with the header label
  /// typography baked in (`defaultHeaderTextStyle` + `headerTextStyle`) and
  /// no fixed width.
  final CoreButtonStyle headerButtonStyle;

  /// Date-cell button style — normal (unselected) state. The zero-padding
  /// base with the cell label typography (`defaultCellTextStyle` +
  /// `cellTextStyle`) as `labelStyle`, + the per-instance `dateCellStyle`
  /// override.
  final CoreButtonStyle dateCellNormalStyle;

  /// Date-cell button style — selected / range-endpoint state. As
  /// [dateCellNormalStyle] but with the selected background / foreground
  /// colour TOKENS baked in (the child `Button` resolves them — no
  /// paint→domain round-trip) and the `selectedTextStyle` slot merged over
  /// the cell label as `labelStyle`.
  final CoreButtonStyle dateCellSelectedStyle;

  /// Date-cell button style — today state. As [dateCellNormalStyle] but
  /// with the today background / foreground colour tokens baked in and the
  /// `todayTextStyle` slot merged over the cell label as `labelStyle`.
  final CoreButtonStyle dateCellTodayStyle;

  /// Month / year grid cell button style — the (pre-scaled) cell size +
  /// label typography baked in (the per-cell variant supplies the state
  /// colour). The per-instance `dateCellStyle` override merges last.
  final CoreButtonStyle monthYearCellStyle;

  /// Nested arrow-icon style — forwarded to the prev / next arrow
  /// `Icon`s. Carries the design-system default size merged with the
  /// per-instance override.
  final CoreIconStyle arrowIconStyle;

  /// Paint-ready text style for the cell labels that are not drawn by a
  /// date-cell `Button` — the range band's dates and the month / year grid
  /// labels.
  final TextStyle cellLabelTextStyle;

  /// Paint-ready text style for the header label.
  final TextStyle headerLabelTextStyle;

  /// Paint-ready text style for the weekday labels (Sun / Mon / …).
  final TextStyle weekdayLabelTextStyle;

  /// Text colour for today's date cell — applied to the cell's label via
  /// `DefaultTextStyle` (alongside the [dateCellTodayStyle] foreground).
  final Color? todayTextColor;

  /// Background colour for cells inside a selected range.
  final Color rangeSelectionColor;

  /// Text colour for cells inside a selected range.
  final Color rangeSelectionTextColor;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves the calendar Style chain to a typed [ResolvedCalendar].
///
/// Merge chain:
///
/// ```text
/// design system default for calendar
///   → theme.coreComponentTheme.calendar.style
///   → widget.calendarStyle
/// ```
///
/// Token resolution is performed once: dimensional fields fall back to
/// `CoreCalendarStyle.defaultX`; colour fields are resolved through
/// `scheme.resolve(...)` so dark-mode auto-switching works; text style
/// slots merge default token + per-instance override before
/// materialising into `TextStyle` via
/// `theme.typography.resolve(...).toValue(color: ...)`.
ResolvedCalendar resolveCalendar(
  BuildContext context, {
  CoreCalendarStyle? calendarStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final calendarTheme = theme.coreComponentTheme?.calendar;

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
      theme.geometry.space(
        merged.cellSpacing ?? CoreCalendarStyle.defaultCellSpacing,
      ) *
      scaling;
  // Merge the design-system default `CoreGapStyle` slot with the
  // per-instance override and forward the merged slot raw to
  // `Gap(gapStyle: …)`. `Gap`'s own resolver multiplies `size` by
  // `theme.scaling`, so pre-applying scaling here would double-scale
  // under non-default text scaler (Epic #1603 옵션 B — parent forwards
  // raw nested style slots; Gap self-scales).
  final headerGridGapStyle = CoreCalendarStyle.defaultHeaderGridGapStyle.merge(
    merged.headerGridGapStyle,
  );
  final yearRowSpacing =
      theme.geometry.space(
        merged.yearRowSpacing ?? CoreCalendarStyle.defaultYearRowSpacing,
      ) *
      scaling;
  // Nested arrow-icon Style slot — merge design-system default
  // (carries the default size) with the per-instance override and
  // forward raw to `Icon(iconStyle: …)`. Icon's own resolver
  // applies `theme.scaling`.
  final arrowIconStyle = CoreCalendarStyle.defaultArrowIconStyle.merge(
    merged.arrowIconStyle,
  );
  final endpointPillBorderRadius =
      (merged.endpointPillBorderRadius ??
              CoreCalendarStyle.defaultEndpointPillBorderRadius)
          .toValue(geometry: theme.geometry);
  final fadedOpacity =
      merged.fadedOpacity ?? CoreCalendarStyle.defaultFadedOpacity;
  final yearGridSize =
      merged.yearGridSize ?? CoreCalendarStyle.defaultYearGridSize;
  final monthGridColumns =
      merged.monthGridColumns ?? CoreCalendarStyle.defaultMonthGridColumns;
  final yearGridColumns =
      merged.yearGridColumns ?? CoreCalendarStyle.defaultYearGridColumns;

  // ─── Colour resolution ────────────────────────────
  // sb8 — `selectedTextColor` / `todayTextColor` / `rangeSelectionTextColor`
  // / `weekdayLabelColor` raw fields removed; colour now lives inside
  // the matching nested `CoreTextStyle` slot (`selectedTextStyle` etc.).
  // We merge the design-system default text style with the per-instance
  // override and pull `.color` for downstream `Color` consumers.
  final selectedTextStyleSlot = CoreCalendarStyle.defaultSelectedTextStyle
      .merge(merged.selectedTextStyle);
  final todayTextStyleSlot = CoreCalendarStyle.defaultTodayTextStyle.merge(
    merged.todayTextStyle,
  );
  final todayTextColor = todayTextStyleSlot.color != null
      ? scheme.resolve(todayTextStyleSlot.color!).toValue()
      : null;
  final rangeSelectionColor = scheme
      .resolve(
        merged.rangeSelectionColor ??
            CoreCalendarStyle.defaultRangeSelectionColor,
      )
      .toValue();
  final rangeSelectionTextStyleSlot = CoreCalendarStyle
      .defaultRangeSelectionTextStyle
      .merge(merged.rangeSelectionTextStyle);
  final rangeSelectionTextColor = scheme
      .resolve(
        rangeSelectionTextStyleSlot.color ??
            CoreCalendarStyle.defaultRangeSelectionTextStyle.color!,
      )
      .toValue();
  final weekdayLabelTextStyleSlot = CoreCalendarStyle
      .defaultWeekdayLabelTextStyle
      .merge(merged.weekdayLabelTextStyle);
  final weekdayLabelColor = scheme
      .resolve(
        weekdayLabelTextStyleSlot.color ??
            CoreCalendarStyle.defaultWeekdayLabelTextStyle.color!,
      )
      .toValue();

  // ─── Text styles (EMIT Stage 2 — single primitive) ──
  // `default.merge(override).toValue(theme:, color:)` is the canonical
  // Flutter typography emit: the token role is materialised against the
  // active theme and its colour resolved through the scheme (dark-mode
  // tracking), folding what `typography.resolve` + value-only
  // `.toValue()` did in two steps (badge reference).
  final cellLabelTextStyle = CoreCalendarStyle.defaultCellTextStyle
      .merge(merged.cellTextStyle)
      .toValue(theme: theme);

  final headerTextStyleSlot = CoreCalendarStyle.defaultHeaderTextStyle.merge(
    merged.headerTextStyle,
  );
  final headerLabelTextStyle = headerTextStyleSlot.toValue(theme: theme);

  // Weekday cell — the role/overlay comes from `weekdayTextStyle` (default
  // `labelMedium`), and the colour from the dedicated `weekdayLabelTextStyle`
  // slot wins only when the role slot does not override it (forced via the
  // `color:` arg when `weekdayTextStyle.color` is null).
  final weekdayLabelTextStyle = CoreCalendarStyle.defaultWeekdayTextStyle
      .merge(merged.weekdayTextStyle)
      .toValue(
        color: merged.weekdayTextStyle?.color == null
            ? weekdayLabelColor
            : null,
        theme: theme,
      );

  final scaledDayCellSize = dayCellSize * scaling;
  final scaledMonthCellWidth = monthCellWidth * scaling;

  // ─── Button styles (paint-ready CoreButtonStyle slots) ─────────
  // The cell size is pre-scaled here: `Button` paints `height` / `width`
  // raw (it does not self-scale its dimensional axis), so scaling must
  // live in the value handed to it. State colours stay `CoreColor` tokens
  // baked into the slot — the child `Button` resolves them (no
  // paint→domain round-trip). The per-instance overrides merge last.
  // Cell-button label typography routes through the Core single source
  // (`defaultCellTextStyle`, token-backed `bodySmall`) merged with the
  // per-instance `cellTextStyle` override — forwarded raw to the child
  // `Button`, which materialises the token and applies the state
  // foreground colour (no re-hardcoded `CoreTypography.coui.bodySmall`).
  final cellButtonLabelStyle = CoreCalendarStyle.defaultCellTextStyle.merge(
    merged.cellTextStyle,
  );
  const navButtonDefault = CoreCalendarStyle.defaultNavButtonStyle;
  const dateCellDefault = CoreCalendarStyle.defaultDateCellStyle;
  final navButtonStyle = navButtonDefault
      .copyWith(height: scaledDayCellSize, width: scaledDayCellSize)
      .merge(merged.navButtonStyle);
  // The month/year title is a header, not a cell: its Button reads the
  // header slot (`defaultHeaderTextStyle` + `headerTextStyle`), the same
  // Core value the Web resolver hands its title Button. Feeding it the cell
  // slot leaked a `cellTextStyle`-only override into the title.
  final headerButtonStyle = navButtonDefault
      .copyWith(height: scaledDayCellSize, labelStyle: headerTextStyleSlot)
      .merge(merged.navButtonStyle);
  // Every date-cell `Button` carries its label typography on `labelStyle`,
  // where a `Button`'s typography lives — the cell slot for a plain date,
  // the cell slot with the state slot over it for a selected date and for
  // today. The same composition the Web resolver hands its cell `Button`s,
  // so the state weight (selected Medium, today SemiBold) reaches the label
  // on both platforms rather than being painted over by the cell role.
  final dateCellNormalStyle = dateCellDefault
      .copyWith(labelStyle: cellButtonLabelStyle)
      .merge(merged.dateCellStyle);
  final dateCellSelectedStyle = dateCellDefault
      .copyWith(
        backgroundColor:
            merged.selectedColor ?? CoreCalendarStyle.defaultSelectedColor,
        foregroundColor:
            selectedTextStyleSlot.color ??
            CoreCalendarStyle.defaultSelectedTextStyle.color,
        labelStyle: cellButtonLabelStyle.merge(selectedTextStyleSlot),
      )
      .merge(merged.dateCellStyle);
  // The whole slot, not just its colour. `defaultTodayTextStyle` states a
  // typography ROLE (`bodySmall`), a weight (SemiBold) and a colour
  // (`primary`); reading only `.color` off it would drop the role and the
  // weight — the `.color`-only flattening `widget/render-only.md` forbids.
  // `labelStyle` is where a `Button`'s typography lives, and the today cell
  // is a `Button`; the colour also rides `foregroundColor`.
  final dateCellTodayStyle = dateCellDefault
      .copyWith(
        backgroundColor: merged.todayColor,
        borderColor:
            merged.todayBorderColor ??
            CoreCalendarStyle.defaultTodayBorderColor,
        borderWidth:
            merged.todayBorderWidth ??
            CoreCalendarStyle.defaultTodayBorderWidth,
        foregroundColor: todayTextStyleSlot.color,
        labelStyle: cellButtonLabelStyle.merge(todayTextStyleSlot),
      )
      .merge(merged.dateCellStyle);
  final monthYearCellStyle = dateCellDefault
      .copyWith(
        height: scaledDayCellSize,
        width: scaledMonthCellWidth,
        labelStyle: cellButtonLabelStyle,
      )
      .merge(merged.dateCellStyle);

  // Paired post-scaling raw double for `SizedBox.width` arithmetic at
  // the range-mode header (consumer needs `dayCellSize + headerGridGap`
  // as a fixed spacer alongside Gap-rendered gaps). `* scaling` is
  // Stage2 EMIT, so it settles in this local — the return literal stays a
  // bare mapping (resolver-pattern.md "return = bare 매핑").
  final headerGridGap =
      theme.geometry.space(headerGridGapStyle.size ?? 0) * scaling;

  return ResolvedCalendar(
    dayCellSize: scaledDayCellSize,
    monthCellWidth: scaledMonthCellWidth,
    cellSpacing: cellSpacing,
    headerGridGapStyle: headerGridGapStyle,
    headerGridGap: headerGridGap,
    yearRowSpacing: yearRowSpacing,
    endpointPillBorderRadius: endpointPillBorderRadius,
    fadedOpacity: fadedOpacity,
    yearGridSize: yearGridSize,
    monthGridColumns: monthGridColumns,
    yearGridColumns: yearGridColumns,
    navButtonStyle: navButtonStyle,
    headerButtonStyle: headerButtonStyle,
    dateCellNormalStyle: dateCellNormalStyle,
    dateCellSelectedStyle: dateCellSelectedStyle,
    dateCellTodayStyle: dateCellTodayStyle,
    monthYearCellStyle: monthYearCellStyle,
    arrowIconStyle: arrowIconStyle,
    cellLabelTextStyle: cellLabelTextStyle,
    headerLabelTextStyle: headerLabelTextStyle,
    weekdayLabelTextStyle: weekdayLabelTextStyle,
    todayTextColor: todayTextColor,
    rangeSelectionColor: rangeSelectionColor,
    rangeSelectionTextColor: rangeSelectionTextColor,
  );
}

// ═══════════════════════════════════════════════════
// Date marker — paint-ready chrome for one marked day cell
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for the dots drawn under one marked day
/// cell of the Flutter `Calendar`.
///
/// Widget tree (`calendar.dart` builds it over the day cell):
///
/// ```text
/// MergeSemantics                          // date + marker read as one name
///   └─ Stacks (passthrough)
///        ├─ day cell (Button / range band)
///        └─ Position.fill → IgnorePointer → Align(bottomCenter)
///             └─ Padding (padding)
///                  └─ Row (spacing: dotSpacing)
///                       └─ dotCount × DecoratedBox (dotSize square,
///                            dotColor, dotBorderRadius)
/// ```
///
/// Resolved per marked cell rather than folded into [ResolvedCalendar]:
/// the dot fill depends on the date's own `CoreCalendarMarker.color` and on
/// that cell's selection state, neither of which the grid-wide resolve
/// knows.
class ResolvedCalendarMarker {
  /// Creates a [ResolvedCalendarMarker].
  const ResolvedCalendarMarker({
    required this.dotCount,
    required this.dotSize,
    required this.dotSpacing,
    required this.padding,
    required this.dotBorderRadius,
    required this.dotColor,
  });

  /// Dots to draw — the marker's count capped at `markerMaxCount`.
  final int dotCount;

  /// Dot diameter (logical px, post-scaling).
  final double dotSize;

  /// Space between dots (logical px, post-scaling) — `Row.spacing`.
  final double dotSpacing;

  /// Inset of the dot row from the cell edges (post-scaling).
  final EdgeInsets padding;

  /// Dot corner radius.
  final BorderRadius dotBorderRadius;

  /// Dot fill — `selectedMarkerColor` on a selected cell or range endpoint,
  /// `rangeMarkerColor` inside a range, otherwise the marker's own colour or
  /// `markerColor`.
  final Color dotColor;
}

/// Resolves the dots for one marked day cell to a typed
/// [ResolvedCalendarMarker].
///
/// Walks the same merge chain as [resolveCalendar]:
///
/// ```text
/// design system default for calendar
///   → theme.coreComponentTheme.calendar.style
///   → widget.calendarStyle
/// ```
///
/// [lookup] is the cell's semantic selection state — a build-time value the
/// Web twin receives the same way. A selected date or range endpoint takes
/// `selectedMarkerColor` and a date inside a range takes `rangeMarkerColor`
/// whatever colour the marker names, so the dots stay legible on the
/// selection fill they sit on.
ResolvedCalendarMarker resolveCalendarMarker(
  BuildContext context, {
  required CoreCalendarMarker marker,
  required CoreCalendarValueLookup lookup,
  CoreCalendarStyle? calendarStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final calendarTheme = theme.coreComponentTheme?.calendar;

  // ─── Merge chain ──────────────────────────────────
  final merged = resolveStyleChain(const CoreCalendarStyle(), [
    calendarTheme?.style,
    calendarStyle,
  ]);

  // ─── Stage 1 — RESOLVE ────────────────────────────
  final markerMaxCount =
      merged.markerMaxCount ?? CoreCalendarStyle.defaultMarkerMaxCount;
  final markerSize = merged.markerSize ?? CoreCalendarStyle.defaultMarkerSize;
  final markerSpacing =
      merged.markerSpacing ?? CoreCalendarStyle.defaultMarkerSpacing;
  final markerPadding =
      merged.markerPadding ?? CoreCalendarStyle.defaultMarkerPadding;
  final markerBorderRadius =
      merged.markerBorderRadius ?? CoreCalendarStyle.defaultMarkerBorderRadius;
  final markerColor = switch (lookup) {
    .selected || .start || .end =>
      merged.selectedMarkerColor ??
          CoreCalendarStyle.defaultSelectedMarkerColor,
    .inRange =>
      merged.rangeMarkerColor ?? CoreCalendarStyle.defaultRangeMarkerColor,
    .none =>
      marker.color ??
          merged.markerColor ??
          CoreCalendarStyle.defaultMarkerColor,
  };

  // ─── Stage 2 — EMIT ───────────────────────────────
  final dotCount = marker.count < markerMaxCount
      ? marker.count
      : markerMaxCount;
  final dotSize = markerSize * scaling;
  final dotSpacing = theme.geometry.space(markerSpacing) * scaling;
  final padding = markerPadding.toValue(geometry: theme.geometry) * scaling;
  final dotBorderRadius = markerBorderRadius.toValue(
    geometry: theme.geometry,
  );
  final dotColor = scheme.resolve(markerColor).toValue();

  return ResolvedCalendarMarker(
    dotCount: dotCount,
    dotSize: dotSize,
    dotSpacing: dotSpacing,
    padding: padding,
    dotBorderRadius: dotBorderRadius,
    dotColor: dotColor,
  );
}
