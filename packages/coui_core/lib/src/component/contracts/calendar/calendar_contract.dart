/// Platform-independent contract for unified calendar components.
///
/// Defines the interface that all Calendar implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/calendar/calendar_marker.dart';
import 'package:coui_core/src/component/contracts/calendar/calendar_style.dart';
import 'package:coui_core/src/component/contracts/calendar/calendar_value.dart';
import 'package:coui_core/src/component/contracts/calendar/calendar_view.dart';

/// Selection mode for calendar components.
///
/// Determines how users can select dates in the calendar:
/// - [none]: Display-only, no date selection.
/// - [single]: Only one date can be selected at a time.
/// - [range]: Two dates form a start-end range.
/// - [multi]: Multiple individual dates can be selected.
enum CoreCalendarSelectionMode {
  /// Display-only, no selection.
  none,

  /// Single date selection.
  single,

  /// Date range selection (start and end).
  range,

  /// Multiple individual date selection.
  multi,
}

/// View type for calendar navigation.
///
/// Specifies the granularity of the time selection display:
/// - [date]: Individual days in a month grid.
/// - [month]: Months in a year grid.
/// - [year]: Years in a decade grid.
enum CoreCalendarViewType {
  /// Individual date grid.
  date,

  /// Month selection grid.
  month,

  /// Year selection grid.
  year,
}

/// Interaction state of a date in the calendar.
///
/// Controls whether a specific date can be selected or interacted with:
/// - [disabled]: Date cannot be selected or clicked.
/// - [enabled]: Date is fully interactive and selectable.
enum CoreCalendarDateState {
  /// Disabled - cannot be selected.
  disabled,

  /// Enabled - can be selected.
  enabled,
}

/// Result type for calendar value lookup operations.
///
/// Represents the relationship between a looked-up date and
/// the current calendar selection:
/// - [none]: Date is not part of any selection.
/// - [selected]: Date is directly selected.
/// - [start]: Date is the start of a selected range.
/// - [end]: Date is the end of a selected range.
/// - [inRange]: Date is within a selected range but not start/end.
enum CoreCalendarValueLookup {
  /// Not selected.
  none,

  /// Directly selected.
  selected,

  /// Start of range.
  start,

  /// End of range.
  end,

  /// Within range.
  inRange,
}

/// Callback type for determining the state of a calendar date.
///
/// Receives a [DateTime] and returns a [CoreCalendarDateState] controlling
/// whether the date should be enabled or disabled.
typedef CoreCalendarDateStateBuilder =
    CoreCalendarDateState Function(DateTime date);

/// Contract for a unified calendar component.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
///
/// The selection value is the unified platform-neutral
/// [CoreCalendarValue] on both platforms; the change callback is a
/// plain `void Function(CoreCalendarValue?)?` — no separate `Val` /
/// `ValChanged` generics (Phase 6f, verify.md 7-7).
///
/// Implementations should render a date grid with navigation
/// and selection support.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [calendarStyle] field — see [CoreCalendarStyle] for
/// the merge chain. Behaviour fields stay flat on the contract.
abstract interface class CoreCalendarContract<W> {
  /// The weekday a calendar week starts on when none is stated: Sunday.
  ///
  /// A plain [DateTime] weekday (`DateTime.monday`…`DateTime.sunday`) and
  /// not a value derived from the active locale — see [firstDayOfWeek].
  static const int defaultFirstDayOfWeek = DateTime.sunday;

  // === Selection ===

  /// The selection mode controlling how dates are selected.
  CoreCalendarSelectionMode get selectionMode;

  /// The current selection value.
  CoreCalendarValue? get value;

  /// Callback when selection changes.
  void Function(CoreCalendarValue?)? get onChanged;

  // === View ===

  /// Initial view position (month/year to display).
  CoreCalendarView? get initialView;

  /// The weekday each week row starts on — a [DateTime] weekday
  /// (`DateTime.monday`…`DateTime.sunday`, `1..7`), [defaultFirstDayOfWeek]
  /// (Sunday) when not stated. Values outside that range are rejected in
  /// debug builds.
  ///
  /// It orders the weekday header and decides which days of the neighbouring
  /// months open and close the grid, so a Monday-first calendar heads its
  /// first column with Monday and puts the 1st of the month that many
  /// columns in. `CoreCalendarGridData` does that arithmetic once for both
  /// platforms.
  ///
  /// The caller states it; it is not read from the locale. Where a week
  /// starts is a property of the region, not of the language — American and
  /// British English share a language and disagree on the day — and the
  /// locale tables here are keyed by language, so a locale-derived default
  /// would be wrong for a whole population of each language's speakers.
  /// `DatePicker` and `DateRangePicker` take the same value and hand it to
  /// the calendar they open.
  int get firstDayOfWeek;

  // === Date constraints ===

  /// Builder to determine enabled/disabled state per date.
  CoreCalendarDateStateBuilder? get stateBuilder;

  /// Minimum selectable date.
  DateTime? get minDate;

  /// Maximum selectable date.
  DateTime? get maxDate;

  // === Markers ===

  /// Builder returning the marker drawn under each day cell (dots standing
  /// for how many things fall on that date), or `null` for an unmarked day.
  ///
  /// Data only — every dot's look comes from [calendarStyle]'s `marker*`
  /// fields. Markers sit under the day number in every selection mode,
  /// including range (a check-in / check-out span keeps its markers), and the
  /// marker's count or label joins the date's accessible name.
  CoreCalendarMarkerBuilder? get markerBuilder;

  // === Style ===

  /// Per-instance calendar style covering nav button / date cell /
  /// arrow icon / header / weekday slots plus the state-token
  /// colours (selected / today / range).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreCalendarTheme.style
  ///   → parent slot override (e.g. CoreDatePickerStyle.calendarStyle)
  ///   → widget.calendarStyle
  /// ```
  ///
  /// Named [calendarStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreCalendarStyle? get calendarStyle;
}
