/// Per-instance style for `Calendar`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Calendar` should render.
///
/// `CoreCalendarStyle` carries every chrome / dimensional override as a
/// flat slot plus nested `CoreButtonStyle` / `CoreIconStyle` /
/// `CoreTextStyle` / `CoreGapStyle` slot references. All defaults —
/// dimensional (`dayCellSize`, `cellSpacing`, `yearRowSpacing`, etc.),
/// gap chrome (`headerGridGapStyle`) **and** state-token chrome
/// (`selectedColor` / `todayColor` / `rangeSelectionColor` /
/// `weekdayLabelColor`) — live here as `static const` so Flutter and
/// Web share a single source of truth (Epic #1696 Phase 3, Tokens
/// 폐기).
///
/// **Semantic enums (`selectionMode` / `view`) and behaviour fields
/// live on the widget, not on this style** (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default
///   → CoreCalendarTheme.style                       // 프로젝트 공통
///   → parent component slot override
///       (e.g. CoreDatePickerStyle.calendarStyle)
///   → widget.calendarStyle                          // 인스턴스별
/// ```
@immutable
class CoreCalendarStyle implements CoreStyle<CoreCalendarStyle> {
  /// Creates a [CoreCalendarStyle].
  const CoreCalendarStyle({
    this.dayCellSize,
    this.monthCellWidth,
    this.cellSpacing,
    this.headerGridGapStyle,
    this.yearRowSpacing,
    this.endpointPillBorderRadius,
    this.fadedOpacity,
    this.yearGridSize,
    this.monthGridColumns,
    this.yearGridColumns,
    this.navButtonStyle,
    this.dateCellStyle,
    this.arrowIconStyle,
    this.headerTextStyle,
    this.weekdayTextStyle,
    this.cellTextStyle,
    this.selectedColor,
    this.selectedTextStyle,
    this.todayColor,
    this.todayBorderColor,
    this.todayBorderWidth,
    this.todayTextStyle,
    this.rangeSelectionColor,
    this.rangeSelectionTextStyle,
    this.weekdayLabelTextStyle,
    this.markerSize,
    this.markerSpacing,
    this.markerPadding,
    this.markerBorderRadius,
    this.markerMaxCount,
    this.markerColor,
    this.selectedMarkerColor,
    this.rangeMarkerColor,
  });

  // ─── Design-system defaults (Phase 6f option D) ──

  /// Default day / month / year cell size (logical px) — `space32`.
  static const double defaultDayCellSize = CoreSpace.space32;

  /// Default month / year grid cell width (logical px) — `size56`.
  static const double defaultMonthCellWidth = CoreSize.size56;

  /// Default gap between calendar grid cells (logical px) — `space8`.
  static const double defaultCellSpacing = CoreSpace.space8;

  /// Default header-row → grid gap style — `CoreGapStyle(size: 16)`.
  /// Per-instance override flows through [headerGridGapStyle] (merged
  /// on top of this default).
  static const CoreGapStyle defaultHeaderGridGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
  );

  /// Default year-grid row spacing (logical px) — `space8`.
  /// Per-instance override flows through [yearRowSpacing] (single
  /// `??` fallback). Consumed natively as `Column.spacing` on Flutter
  /// and `gap-${yearRowSpacing.tailwindSpace}` on Web.
  static const double defaultYearRowSpacing = CoreSpace.space8;

  /// Default prev/next arrow icon style. Carries the design-system
  /// arrow icon size (`space12`); the resolver forwards this slot
  /// (merged with the per-instance override) straight to
  /// `Icon(iconStyle: …)`.
  static const CoreIconStyle defaultArrowIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default nav-button chrome — a partial that pins the padding to zero
  /// so the arrow glyph centres inside the square hit target the grid
  /// gives it. Only the padding is stated: the square's own extent comes
  /// from [defaultDayCellSize] (resolved per-instance and, on Flutter,
  /// pre-scaled), so it is not a constant. Everything else stays null and
  /// resolves inside `Button`'s own resolver via
  /// `defaultNavButtonStyle.merge(merged.navButtonStyle)`.
  ///
  /// Spelled `.all(CoreSpace.space0)` rather than `CoreEdgeInsets.zero`
  /// for the same two reasons `CoreBasicStyle.defaultPadding` is: the
  /// value keeps its spacing-token provenance, and the constructor form is
  /// the only one the Figma reader can evaluate (`CoreEdgeInsets` lives
  /// outside `contracts/`, so a static-const reference on it resolves to
  /// nothing and the padding drops out of `components.json` unread).
  static const CoreButtonStyle defaultNavButtonStyle = CoreButtonStyle(
    // ignore: use_named_constants, see the paragraph above
    padding: CoreEdgeInsets.all(CoreSpace.space0),
  );

  /// Default date / month / year cell-button chrome — a partial that pins
  /// the padding to zero, for the same reason as [defaultNavButtonStyle]:
  /// the cell's extent is the grid's, and a cell that carried the
  /// button's own size-tier padding would outgrow its column. The label
  /// typography is not stated here because it is [defaultCellTextStyle]
  /// merged with the per-instance `cellTextStyle` override — a value, not
  /// a constant. Everything else resolves inside `Button`'s own resolver
  /// via `defaultDateCellStyle.merge(merged.dateCellStyle)`. The padding
  /// is spelled the constructor way for the reason [defaultNavButtonStyle]
  /// gives.
  static const CoreButtonStyle defaultDateCellStyle = CoreButtonStyle(
    // ignore: use_named_constants, see defaultNavButtonStyle
    padding: CoreEdgeInsets.all(CoreSpace.space0),
  );

  /// Default border radius for the range endpoint pill — matches
  /// `Button.primary` chrome (`radius8`).
  static const CoreBorderRadius defaultEndpointPillBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius8);

  /// Default opacity applied to dates that belong to the previous /
  /// next month — `opacity50`.
  static const double defaultFadedOpacity = CoreOpacity.opacity50;

  /// Default total items in the year grid (4×4).
  static const int defaultYearGridSize = 16;

  /// Default month grid columns (4×3 = 12 months).
  static const int defaultMonthGridColumns = 4;

  /// Default year grid columns (4×4 = 16 years). Aliased to
  /// [defaultMonthGridColumns] — both subgrids share the same 4-column
  /// layout, but keeping a dedicated name preserves intent at call
  /// sites.
  static const int defaultYearGridColumns = defaultMonthGridColumns;

  /// Default selected (start / end pill) background colour — `primary`.
  static const CoreColor defaultSelectedColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default range band colour — `primaryContainer`. Fills the cells
  /// between the endpoints and the inner half of each endpoint cell, behind
  /// its pill, so the band runs unbroken into the middle of both end dates.
  static const CoreColor defaultRangeSelectionColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  /// Default date / month / year cell text style — `bodySmall`.
  ///
  /// Body family, not the label role of the `Button` each cell composes:
  /// a date in a grid is **data being read**, not a control's label, and
  /// the cell reaches that decision through `Button`'s `labelStyle` slot
  /// — the sanctioned entry point for a parent to state its child's
  /// chrome — rather than by painting over the composed child.
  ///
  /// The trigger that opens this calendar answers the opposite way
  /// (`CoreDatePickerStyle.defaultValueTypography` is `labelLarge`) and
  /// that is not a contradiction: one is a button's own label, the other
  /// is tabular content inside it.
  static const CoreTextStyle defaultCellTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
  );

  /// Default header label text style — `labelMedium` (13 · Medium · 140%).
  ///
  /// The month title is a button — tapping it switches the grid to the
  /// month / year view — so it takes the button-label role rather than the
  /// body role the date cells read in ([defaultCellTextStyle]). A Regular
  /// title at the cells' weight sinks into the grid it heads; the label
  /// role's Medium weight lifts it above the dates while the size stays the
  /// grid's 13.
  static const CoreTextStyle defaultHeaderTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
  );

  /// Default weekday header text style — `bodyXs` (12 · 150%).
  ///
  /// The weekday row is the grid's axis label, not data the user reads, so
  /// it sits one step below the date cells' `bodySmall`
  /// ([defaultCellTextStyle]) and takes the subtle colour
  /// ([defaultWeekdayLabelTextStyle]) — smaller and quieter than the dates
  /// under it, which is what tells the axis from the data.
  static const CoreTextStyle defaultWeekdayTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
  );

  /// Default selected date cell text style — `bodySmall` at Medium weight
  /// with the design-system `onPrimary` colour. Read by a single selection
  /// and by both range endpoints (the start / end pill).
  ///
  /// The role stays the cells' `bodySmall` so the date on the fill keeps the
  /// grid's size and leading; only the weight rises, so the chosen date reads
  /// as chosen without changing size under the pill.
  static final CoreTextStyle defaultSelectedTextStyle =
      const CoreTextStyle.token(
        CoreTextStyles.bodySmall,
        color: CoreColor.token(CoreColors.onPrimary),
      ).copyWith(fontWeight: CoreFontWeight.medium);

  /// Default today's date cell text style — `bodySmall` at SemiBold weight
  /// in `primary`.
  ///
  /// Today is marked by its outline ([defaultTodayBorderColor]), this weight
  /// and the primary colour; the role stays the cells' `bodySmall` so the
  /// number keeps the grid's size. A date that is today AND selected takes
  /// the selected cell instead (both widgets reach the today branch only when
  /// the date is not selected), so this colour never sits on the pill.
  static final CoreTextStyle defaultTodayTextStyle = const CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.primary),
  ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default range-inner date cell text style — `bodySmall` typography
  /// with the design-system `onPrimaryContainer` colour. The inner cells
  /// sit on the [defaultRangeSelectionColor] band (`primaryContainer`),
  /// so the text takes the foreground that pairs with that fill.
  static const CoreTextStyle defaultRangeSelectionTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.bodySmall,
        color: CoreColor.token(CoreColors.onPrimaryContainer),
      );

  /// Default weekday header label colour carrier — `bodyXs` with the
  /// design-system `onSurfaceSubtle` colour. Only its colour is read; the
  /// role comes from [defaultWeekdayTextStyle].
  static const CoreTextStyle defaultWeekdayLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default today-cell border colour — `outline`.
  static const CoreColor defaultTodayBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default today-cell border width — `stroke1`.
  static const double defaultTodayBorderWidth = CoreStrokeWidth.stroke1;

  /// Default marker dot diameter (logical px) — `size4`. Small enough to
  /// sit in the strip under a `bodySmall` day number inside the
  /// [defaultDayCellSize] square without touching the digit.
  static const double defaultMarkerSize = CoreSize.size4;

  /// Default space between two marker dots (logical px) — `space2`.
  static const double defaultMarkerSpacing = CoreSpace.space2;

  /// Default inset of the marker row from the day cell's edges — `space2`
  /// above the cell's bottom edge, so the dots hang under the number rather
  /// than on the cell border.
  static const CoreEdgeInsets defaultMarkerPadding = CoreEdgeInsets.only(
    bottom: CoreSpace.space2,
  );

  /// Default marker dot corner radius — `radius9999`, i.e. a round dot.
  static const CoreBorderRadius defaultMarkerBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default cap on the dots drawn for one date. A marker with a larger
  /// count draws this many and still speaks its full count.
  static const int defaultMarkerMaxCount = 3;

  /// Default marker dot fill on an unselected cell — `primary`.
  static const CoreColor defaultMarkerColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default marker dot fill on a selected cell — `onPrimary`, the
  /// foreground that pairs with [defaultSelectedColor], so the dots stay
  /// visible on the selection pill.
  static const CoreColor defaultSelectedMarkerColor = CoreColor.token(
    CoreColors.onPrimary,
  );

  /// Default marker dot fill on a cell inside a selected range —
  /// `onPrimaryContainer`, the foreground that pairs with
  /// [defaultRangeSelectionColor] (`primaryContainer`), so the dots stay
  /// visible on the range band in the same colour as the date above them
  /// ([defaultRangeSelectionTextStyle]).
  static const CoreColor defaultRangeMarkerColor = CoreColor.token(
    CoreColors.onPrimaryContainer,
  );

  // ─── Fields ──────────────────────────────────────

  /// Day / month / year cell size (logical px). `null` defers to
  /// [defaultDayCellSize].
  final double? dayCellSize;

  /// Month / year grid cell width (logical px). `null` defers to
  /// [defaultMonthCellWidth].
  final double? monthCellWidth;

  /// Gap between calendar grid cells (logical px). `null` defers to
  /// [defaultCellSpacing]. Consumed natively as `Column.spacing` on
  /// Flutter and `gap-${cellSpacing.tailwindSpace}` on Web.
  final double? cellSpacing;

  /// Gap between the header row and the grid, also used between the
  /// buttons inside the header row. Laid over [defaultHeaderGridGapStyle]
  /// and passed to `Gap(gapStyle: …)` as is.
  final CoreGapStyle? headerGridGapStyle;

  /// Row gap between year-grid rows (logical px). `null` defers to
  /// [defaultYearRowSpacing]. Consumed natively as `Column.spacing` on
  /// Flutter and `gap-${yearRowSpacing.tailwindSpace}` on Web.
  final double? yearRowSpacing;

  /// Border radius for the range endpoint pill. `null` defers to
  /// [defaultEndpointPillBorderRadius].
  final CoreBorderRadius? endpointPillBorderRadius;

  /// Opacity applied to dates from the previous / next month.
  /// `null` defers to [defaultFadedOpacity].
  final double? fadedOpacity;

  /// Total items in the year grid. `null` defers to
  /// [defaultYearGridSize].
  final int? yearGridSize;

  /// Month grid columns. `null` defers to [defaultMonthGridColumns].
  final int? monthGridColumns;

  /// Year grid columns. `null` defers to [defaultYearGridColumns].
  final int? yearGridColumns;

  // ── Slot Styles (nested) ─────────────────────────

  /// Style applied to navigation buttons (prev / next month / year
  /// arrows + the header button that opens the year/month grid).
  final CoreButtonStyle? navButtonStyle;

  /// Style applied to each date / month / year cell button.
  final CoreButtonStyle? dateCellStyle;

  /// Icon style used by the prev / next arrow icons inside the nav
  /// buttons.
  final CoreIconStyle? arrowIconStyle;

  /// Header label text style (the "May 2026" / "2026" / decade label).
  /// `null` defers to [defaultHeaderTextStyle].
  final CoreTextStyle? headerTextStyle;

  /// Weekday header label text style (Sun / Mon / …).
  /// `null` defers to [defaultWeekdayTextStyle].
  ///
  /// The weekday header is the grid's axis label, so its default role is
  /// `bodyXs` (12px) — a step below the date cells' `bodySmall` on purpose,
  /// not drift to reconcile.
  final CoreTextStyle? weekdayTextStyle;

  /// Date / month / year cell text style — applied to the cell
  /// `Button.labelStyle`. `null` defers to [defaultCellTextStyle].
  final CoreTextStyle? cellTextStyle;

  // ── State token colours ──────────────────────────

  /// Background colour for the selected (start / end pill) date cell.
  /// `null` defers to [defaultSelectedColor].
  final CoreColor? selectedColor;

  /// Text style for the selected (start / end pill) date cell.
  /// Text colour is carried via [CoreTextStyle.color] inside this slot
  /// (sb8 — raw `selectedTextColor` field removed). `null` defers to
  /// [defaultSelectedTextStyle].
  final CoreTextStyle? selectedTextStyle;

  /// Background colour for today's date cell. `null` defers to
  /// Button's secondary variant default.
  ///
  /// Carries no `defaultTodayColor`. The today cell is a composed
  /// `Button(variant: .secondary)`, so its fill is
  /// `CoreButtonStyle.defaultsByVariant[.secondary].backgroundColor` and a
  /// constant here would be a second copy of it (`style-contract.md`: the
  /// parent must not reach into the child's defaults). Both platforms key
  /// the *override* on absence, so a default would double the fill rather
  /// than replace it: Flutter passes it as
  /// `dateCellDefault.copyWith(backgroundColor: merged.todayColor)`, where
  /// null leaves the Button's own variant fill in place, and Web skips the
  /// override wrapper entirely (`todayColor == null` emits neither class
  /// nor inline), so a constant would paint a fill on top of the Button's
  /// on every calendar.
  final CoreColor? todayColor;

  /// Border colour of today's date cell. `null` → [defaultTodayBorderColor].
  ///
  /// Today is a quiet `ghost` cell marked by this line rather than by a
  /// fill, so it reads against the selected (filled) and range cells.
  final CoreColor? todayBorderColor;

  /// Border width of today's date cell (logical px, pre-scaling). `null` →
  /// [defaultTodayBorderWidth].
  final double? todayBorderWidth;

  /// Text style for today's date cell. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw `todayTextColor`
  /// field removed). `null` defers to [defaultTodayTextStyle].
  final CoreTextStyle? todayTextStyle;

  /// Range band colour — fills the cells inside a selected range (between
  /// start and end, exclusive) and the inner half of each endpoint cell
  /// behind its pill. `null` defers to [defaultRangeSelectionColor].
  final CoreColor? rangeSelectionColor;

  /// Text style for cells inside a selected range.
  /// Text colour is carried via [CoreTextStyle.color] inside this slot
  /// (sb8 — raw `rangeSelectionTextColor` field removed). `null` defers
  /// to [defaultRangeSelectionTextStyle].
  final CoreTextStyle? rangeSelectionTextStyle;

  /// Weekday header label text style (Sun / Mon / …). Text colour is
  /// carried via [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `weekdayLabelColor` field removed). `null` defers to
  /// [defaultWeekdayLabelTextStyle].
  final CoreTextStyle? weekdayLabelTextStyle;

  // ── Date markers ─────────────────────────────────

  /// Marker dot diameter (logical px). `null` defers to
  /// [defaultMarkerSize].
  final double? markerSize;

  /// Space between two marker dots (logical px). `null` defers to
  /// [defaultMarkerSpacing]. Consumed natively as `Row.spacing` on Flutter
  /// and an inline `gap` on Web.
  final double? markerSpacing;

  /// Inset of the marker row from the day cell's edges. The row is anchored
  /// to the cell's bottom centre, so the bottom inset is the one that
  /// shows. `null` defers to [defaultMarkerPadding].
  final CoreEdgeInsets? markerPadding;

  /// Marker dot corner radius. `null` defers to
  /// [defaultMarkerBorderRadius] (a round dot).
  final CoreBorderRadius? markerBorderRadius;

  /// Most dots drawn for one date. `null` defers to
  /// [defaultMarkerMaxCount].
  final int? markerMaxCount;

  /// Marker dot fill on an unselected cell, used when the marker itself
  /// names no colour. `null` defers to [defaultMarkerColor].
  final CoreColor? markerColor;

  /// Marker dot fill on a selected cell (single / multi selection and range
  /// endpoints) — always used there, even when the marker names its own
  /// colour, so the dots stay legible on the selection fill. `null` defers
  /// to [defaultSelectedMarkerColor].
  final CoreColor? selectedMarkerColor;

  /// Marker dot fill on a cell inside a selected range (between the
  /// endpoints) — always used there, for the same legibility reason as
  /// [selectedMarkerColor]. `null` defers to [defaultRangeMarkerColor].
  final CoreColor? rangeMarkerColor;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreCalendarStyle merge(CoreCalendarStyle? other) {
    if (other == null) return this;
    return CoreCalendarStyle(
      dayCellSize: other.dayCellSize ?? dayCellSize,
      monthCellWidth: other.monthCellWidth ?? monthCellWidth,
      cellSpacing: other.cellSpacing ?? cellSpacing,
      headerGridGapStyle: _mergeGap(
        headerGridGapStyle,
        other.headerGridGapStyle,
      ),
      yearRowSpacing: other.yearRowSpacing ?? yearRowSpacing,
      endpointPillBorderRadius:
          other.endpointPillBorderRadius ?? endpointPillBorderRadius,
      fadedOpacity: other.fadedOpacity ?? fadedOpacity,
      yearGridSize: other.yearGridSize ?? yearGridSize,
      monthGridColumns: other.monthGridColumns ?? monthGridColumns,
      yearGridColumns: other.yearGridColumns ?? yearGridColumns,
      navButtonStyle: _mergeButton(navButtonStyle, other.navButtonStyle),
      dateCellStyle: _mergeButton(dateCellStyle, other.dateCellStyle),
      arrowIconStyle: _mergeIcon(arrowIconStyle, other.arrowIconStyle),
      headerTextStyle: _mergeText(headerTextStyle, other.headerTextStyle),
      weekdayTextStyle: _mergeText(weekdayTextStyle, other.weekdayTextStyle),
      cellTextStyle: _mergeText(cellTextStyle, other.cellTextStyle),
      selectedColor: other.selectedColor ?? selectedColor,
      selectedTextStyle: _mergeText(selectedTextStyle, other.selectedTextStyle),
      todayColor: other.todayColor ?? todayColor,
      todayBorderColor: other.todayBorderColor ?? todayBorderColor,
      todayBorderWidth: other.todayBorderWidth ?? todayBorderWidth,
      todayTextStyle: _mergeText(todayTextStyle, other.todayTextStyle),
      rangeSelectionColor: other.rangeSelectionColor ?? rangeSelectionColor,
      rangeSelectionTextStyle: _mergeText(
        rangeSelectionTextStyle,
        other.rangeSelectionTextStyle,
      ),
      weekdayLabelTextStyle: _mergeText(
        weekdayLabelTextStyle,
        other.weekdayLabelTextStyle,
      ),
      markerSize: other.markerSize ?? markerSize,
      markerSpacing: other.markerSpacing ?? markerSpacing,
      markerPadding: other.markerPadding ?? markerPadding,
      markerBorderRadius: other.markerBorderRadius ?? markerBorderRadius,
      markerMaxCount: other.markerMaxCount ?? markerMaxCount,
      markerColor: other.markerColor ?? markerColor,
      selectedMarkerColor: other.selectedMarkerColor ?? selectedMarkerColor,
      rangeMarkerColor: other.rangeMarkerColor ?? rangeMarkerColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreCalendarStyle copyWith({
    double? dayCellSize,
    double? monthCellWidth,
    double? cellSpacing,
    CoreGapStyle? headerGridGapStyle,
    double? yearRowSpacing,
    CoreBorderRadius? endpointPillBorderRadius,
    double? fadedOpacity,
    int? yearGridSize,
    int? monthGridColumns,
    int? yearGridColumns,
    CoreButtonStyle? navButtonStyle,
    CoreButtonStyle? dateCellStyle,
    CoreIconStyle? arrowIconStyle,
    CoreTextStyle? headerTextStyle,
    CoreTextStyle? weekdayTextStyle,
    CoreTextStyle? cellTextStyle,
    CoreColor? selectedColor,
    CoreTextStyle? selectedTextStyle,
    CoreColor? todayColor,
    CoreColor? todayBorderColor,
    double? todayBorderWidth,
    CoreTextStyle? todayTextStyle,
    CoreColor? rangeSelectionColor,
    CoreTextStyle? rangeSelectionTextStyle,
    CoreTextStyle? weekdayLabelTextStyle,
    double? markerSize,
    double? markerSpacing,
    CoreEdgeInsets? markerPadding,
    CoreBorderRadius? markerBorderRadius,
    int? markerMaxCount,
    CoreColor? markerColor,
    CoreColor? selectedMarkerColor,
    CoreColor? rangeMarkerColor,
  }) {
    return CoreCalendarStyle(
      dayCellSize: dayCellSize ?? this.dayCellSize,
      monthCellWidth: monthCellWidth ?? this.monthCellWidth,
      cellSpacing: cellSpacing ?? this.cellSpacing,
      headerGridGapStyle: headerGridGapStyle ?? this.headerGridGapStyle,
      yearRowSpacing: yearRowSpacing ?? this.yearRowSpacing,
      endpointPillBorderRadius:
          endpointPillBorderRadius ?? this.endpointPillBorderRadius,
      fadedOpacity: fadedOpacity ?? this.fadedOpacity,
      yearGridSize: yearGridSize ?? this.yearGridSize,
      monthGridColumns: monthGridColumns ?? this.monthGridColumns,
      yearGridColumns: yearGridColumns ?? this.yearGridColumns,
      navButtonStyle: navButtonStyle ?? this.navButtonStyle,
      dateCellStyle: dateCellStyle ?? this.dateCellStyle,
      arrowIconStyle: arrowIconStyle ?? this.arrowIconStyle,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      weekdayTextStyle: weekdayTextStyle ?? this.weekdayTextStyle,
      cellTextStyle: cellTextStyle ?? this.cellTextStyle,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
      todayColor: todayColor ?? this.todayColor,
      todayBorderColor: todayBorderColor ?? this.todayBorderColor,
      todayBorderWidth: todayBorderWidth ?? this.todayBorderWidth,
      todayTextStyle: todayTextStyle ?? this.todayTextStyle,
      rangeSelectionColor: rangeSelectionColor ?? this.rangeSelectionColor,
      rangeSelectionTextStyle:
          rangeSelectionTextStyle ?? this.rangeSelectionTextStyle,
      weekdayLabelTextStyle:
          weekdayLabelTextStyle ?? this.weekdayLabelTextStyle,
      markerSize: markerSize ?? this.markerSize,
      markerSpacing: markerSpacing ?? this.markerSpacing,
      markerPadding: markerPadding ?? this.markerPadding,
      markerBorderRadius: markerBorderRadius ?? this.markerBorderRadius,
      markerMaxCount: markerMaxCount ?? this.markerMaxCount,
      markerColor: markerColor ?? this.markerColor,
      selectedMarkerColor: selectedMarkerColor ?? this.selectedMarkerColor,
      rangeMarkerColor: rangeMarkerColor ?? this.rangeMarkerColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCalendarStyle &&
          runtimeType == other.runtimeType &&
          dayCellSize == other.dayCellSize &&
          monthCellWidth == other.monthCellWidth &&
          cellSpacing == other.cellSpacing &&
          headerGridGapStyle == other.headerGridGapStyle &&
          yearRowSpacing == other.yearRowSpacing &&
          endpointPillBorderRadius == other.endpointPillBorderRadius &&
          fadedOpacity == other.fadedOpacity &&
          yearGridSize == other.yearGridSize &&
          monthGridColumns == other.monthGridColumns &&
          yearGridColumns == other.yearGridColumns &&
          navButtonStyle == other.navButtonStyle &&
          dateCellStyle == other.dateCellStyle &&
          arrowIconStyle == other.arrowIconStyle &&
          headerTextStyle == other.headerTextStyle &&
          weekdayTextStyle == other.weekdayTextStyle &&
          cellTextStyle == other.cellTextStyle &&
          selectedColor == other.selectedColor &&
          selectedTextStyle == other.selectedTextStyle &&
          todayColor == other.todayColor &&
          todayBorderColor == other.todayBorderColor &&
          todayBorderWidth == other.todayBorderWidth &&
          todayTextStyle == other.todayTextStyle &&
          rangeSelectionColor == other.rangeSelectionColor &&
          rangeSelectionTextStyle == other.rangeSelectionTextStyle &&
          weekdayLabelTextStyle == other.weekdayLabelTextStyle &&
          markerSize == other.markerSize &&
          markerSpacing == other.markerSpacing &&
          markerPadding == other.markerPadding &&
          markerBorderRadius == other.markerBorderRadius &&
          markerMaxCount == other.markerMaxCount &&
          markerColor == other.markerColor &&
          selectedMarkerColor == other.selectedMarkerColor &&
          rangeMarkerColor == other.rangeMarkerColor;

  @override
  int get hashCode => Object.hashAll([
    dayCellSize,
    monthCellWidth,
    cellSpacing,
    headerGridGapStyle,
    yearRowSpacing,
    endpointPillBorderRadius,
    fadedOpacity,
    yearGridSize,
    monthGridColumns,
    yearGridColumns,
    navButtonStyle,
    dateCellStyle,
    arrowIconStyle,
    headerTextStyle,
    weekdayTextStyle,
    cellTextStyle,
    selectedColor,
    selectedTextStyle,
    todayColor,
    todayBorderColor,
    todayBorderWidth,
    todayTextStyle,
    rangeSelectionColor,
    rangeSelectionTextStyle,
    weekdayLabelTextStyle,
    markerSize,
    markerSpacing,
    markerPadding,
    markerBorderRadius,
    markerMaxCount,
    markerColor,
    selectedMarkerColor,
    rangeMarkerColor,
  ]);

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
