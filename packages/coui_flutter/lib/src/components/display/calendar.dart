import 'package:flutter/foundation.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for calendar widgets.
///
/// Provides styling options for calendar components, including arrow icon colors
/// for navigation buttons and other visual elements.
class CalendarTheme {
  const CalendarTheme({this.arrowIconColor});

  /// Color of navigation arrow icons.
  final Color? arrowIconColor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CalendarTheme && other.arrowIconColor == arrowIconColor;
  }

  @override
  int get hashCode => arrowIconColor.hashCode;
}

/// Defines the different view types available in calendar components.
///
/// Specifies what granularity of time selection is displayed:
/// - [date]: Shows individual days in a month grid
/// - [month]: Shows months in a year grid
/// - [year]: Shows years in a decade grid
enum CalendarViewType {
  date,
  month,
  year,
}

/// Represents the interactive state of a date in the calendar.
///
/// Controls whether a specific date can be selected or interacted with:
/// - [disabled]: Date cannot be selected or clicked
/// - [enabled]: Date is fully interactive and selectable
enum DateState {
  disabled,
  enabled,
}

/// Callback function type for determining the state of calendar dates.
///
/// Takes a [DateTime] and returns a [DateState] to control whether
/// that date should be enabled or disabled for user interaction.
typedef DateStateBuilder = DateState Function(DateTime date);

/// Selection modes available for calendar components.
///
/// Determines how users can select dates in calendar widgets:
/// - [none]: No date selection allowed (display only)
/// - [single]: Only one date can be selected at a time
/// - [range]: Two dates can be selected to form a date range
/// - [multi]: Multiple individual dates can be selected
enum CalendarSelectionMode {
  multi,
  none,
  range,
  single,
}

/// A date picker dialog that provides comprehensive date selection capabilities.
///
/// Displays a modal dialog containing a calendar interface with support for
/// different view types (date, month, year), selection modes (single, range, multi),
/// and customizable date states. Includes navigation controls and responsive layouts.
///
/// Features:
/// - Multiple view types: date grid, month grid, year grid
/// - Various selection modes: single date, date range, multiple dates
/// - Navigation arrows with keyboard support
/// - Customizable date state validation
/// - Dual-calendar layout for range selection
/// - Theme integration and localization support
///
/// Example:
/// ```dart
/// DatePickerDialog(
///   initialViewType: CalendarViewType.date,
///   selectionMode: CalendarSelectionMode.single,
///   initialValue: CalendarValue.single(DateTime.now()),
///   onChanged: (value) => print('Selected: $value'),
/// )
/// ```
class DatePickerDialog extends StatefulWidget {
  /// Creates a [DatePickerDialog] with comprehensive date selection options.
  ///
  /// Configures the dialog's initial state, selection behavior, and callbacks
  /// for handling date changes and validation.
  ///
  /// Parameters:
  /// - [initialViewType] (CalendarViewType, required): Starting view (date/month/year)
  /// - [initialView] (CalendarView?, optional): Initial calendar view position
  /// - [selectionMode] (CalendarSelectionMode, required): How dates can be selected
  /// - [viewMode] (CalendarSelectionMode?, optional): Alternative view mode for display
  /// - [initialValue] (CalendarValue?, optional): Pre-selected date(s)
  /// - [onChanged] (ValueChanged<CalendarValue?>?, optional): Called when selection changes
  /// - [stateBuilder] (DateStateBuilder?, optional): Custom date state validation
  ///
  /// Example:
  /// ```dart
  /// DatePickerDialog(
  ///   initialViewType: CalendarViewType.date,
  ///   selectionMode: CalendarSelectionMode.range,
  ///   onChanged: (value) => handleDateChange(value),
  ///   stateBuilder: (date) => date.isBefore(DateTime.now())
  ///     ? DateState.disabled
  ///     : DateState.enabled,
  /// )
  /// ```
  const DatePickerDialog({
    this.initialValue,
    this.initialView,
    required this.initialViewType,
    super.key,
    this.onChanged,
    required this.selectionMode,
    this.stateBuilder,
    this.viewMode,
  });

  final CalendarViewType initialViewType;
  final CalendarView? initialView;
  final CalendarSelectionMode selectionMode;
  final CalendarSelectionMode? viewMode;
  final CalendarValue? initialValue;
  final ValueChanged<CalendarValue?>? onChanged;

  final DateStateBuilder? stateBuilder;

  @override
  State<DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<DatePickerDialog> {
  late CalendarView _view;
  late CalendarView _alternateView;
  CalendarValue? _value;
  late CalendarViewType _viewType;
  late int _yearSelectStart;
  bool _alternate = false;

  static String getHeaderText(
    CoUILocalizations localizations,
    CalendarView view,
    CalendarViewType viewType,
  ) {
    if (viewType == CalendarViewType.date) {
      return '${localizations.getMonth(view.month)} ${view.year}';
    }

    return viewType == CalendarViewType.month
        ? '${view.year}'
        : localizations.datePickerSelectYear;
  }

  @override
  void initState() {
    super.initState();
    _view =
        widget.initialView ?? widget.initialValue?.view ?? CalendarView.now();
    _alternateView = _view.next;
    _value = widget.initialValue;
    _viewType = widget.initialViewType;
    // _yearSelectStart = round year every 16 years so that it can fit 4x4 grid
    _yearSelectStart = (_view.year ~/ 16) * 16;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<CalendarTheme>(context);
    final arrowColor = styleValue(
      themeValue: compTheme?.arrowIconColor,
      defaultValue: null,
    );
    final viewMode = widget.viewMode ?? widget.selectionMode;

    return widget.selectionMode == CalendarSelectionMode.range
        ? IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlineButton(
                            onPressed: () {
                              setState(() {
                                switch (_viewType) {
                                  case CalendarViewType.date:
                                    _view = _view.previous;
                                    _alternateView = _alternateView.previous;

                                  case CalendarViewType.month:
                                    _view = _view.previousYear;

                                  case CalendarViewType.year:
                                    _yearSelectStart -= 16;
                                }
                              });
                            },
                            density: ButtonDensity.icon,
                            child: Icon(
                              LucideIcons.arrowLeft,
                              color: arrowColor,
                            ).iconXSmall(),
                          ),
                          SizedBox(width: theme.scaling * 16),
                          Expanded(
                            child: GhostButton(
                              onPressed: () {
                                _alternate = false;
                                switch (_viewType) {
                                  case CalendarViewType.date:
                                    setState(() {
                                      _viewType = CalendarViewType.month;
                                    });

                                  case CalendarViewType.month:
                                    setState(() {
                                      _viewType = CalendarViewType.year;
                                    });

                                  default:
                                    break;
                                }
                              },
                              enabled: _viewType != CalendarViewType.year,
                              child: Text(
                                getHeaderText(
                                  localizations,
                                  _view,
                                  _viewType,
                                ),
                              ).foreground().small().medium().center(),
                            ).sized(height: theme.scaling * 32),
                          ),
                          if (_viewType == CalendarViewType.date &&
                              viewMode == CalendarSelectionMode.range)
                            SizedBox(width: theme.scaling * 32),
                          SizedBox(width: theme.scaling * 16),
                          if (_viewType != CalendarViewType.date ||
                              viewMode != CalendarSelectionMode.range)
                            OutlineButton(
                              onPressed: () {
                                setState(() {
                                  switch (_viewType) {
                                    case CalendarViewType.date:
                                      _view = _view.next;

                                    case CalendarViewType.month:
                                      _view = _view.nextYear;

                                    case CalendarViewType.year:
                                      _yearSelectStart += 16;
                                  }
                                });
                              },
                              density: ButtonDensity.icon,
                              child: Icon(
                                LucideIcons.arrowRight,
                                color: arrowColor,
                              ).iconXSmall(),
                            ),
                        ],
                      ),
                    ),
                    if (_viewType == CalendarViewType.date &&
                        viewMode == CalendarSelectionMode.range)
                      Gap(theme.scaling * 16),
                    if (_viewType == CalendarViewType.date &&
                        viewMode == CalendarSelectionMode.range)
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: theme.scaling * (32 + 16)),
                            Expanded(
                              child: GhostButton(
                                onPressed: () {
                                  _alternate = true;
                                  switch (_viewType) {
                                    case CalendarViewType.date:
                                      setState(() {
                                        _viewType = CalendarViewType.month;
                                      });

                                    case CalendarViewType.month:
                                      setState(() {
                                        _viewType = CalendarViewType.year;
                                      });

                                    default:
                                      break;
                                  }
                                },
                                child: Text(
                                  getHeaderText(
                                    localizations,
                                    _alternateView,
                                    _viewType,
                                  ),
                                ).foreground().small().medium().center(),
                              ).sized(height: theme.scaling * 32),
                            ),
                            SizedBox(width: theme.scaling * 16),
                            OutlineButton(
                              onPressed: () {
                                setState(() {
                                  switch (_viewType) {
                                    case CalendarViewType.date:
                                      _view = _view.next;
                                      _alternateView = _alternateView.next;

                                    case CalendarViewType.month:
                                      _view = _view.nextYear;

                                    case CalendarViewType.year:
                                      _yearSelectStart += 16;
                                  }
                                });
                              },
                              density: ButtonDensity.icon,
                              child: Icon(
                                LucideIcons.arrowRight,
                                color: arrowColor,
                              ).iconXSmall(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Gap(theme.scaling * 16),
                Row(
                  mainAxisAlignment: viewMode == CalendarSelectionMode.range
                      ? MainAxisAlignment.spaceAround
                      : MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildView(
                      context,
                      _yearSelectStart,
                      _view,
                      _viewType,
                      widget.selectionMode,
                      (value) {
                        setState(() {
                          if (_alternate) {
                            _view = value.previous;
                            _alternateView = value;
                          } else {
                            _view = value;
                            _alternateView = value.next;
                          }
                          switch (_viewType) {
                            case CalendarViewType.date:
                              break;

                            case CalendarViewType.month:
                              _viewType = CalendarViewType.date;

                            case CalendarViewType.year:
                              _viewType = CalendarViewType.month;
                          }
                        });
                      },
                    ),
                    if (_viewType == CalendarViewType.date &&
                        viewMode == CalendarSelectionMode.range)
                      Gap(theme.scaling * 16),
                    if (_viewType == CalendarViewType.date &&
                        viewMode == CalendarSelectionMode.range)
                      buildView(
                        context,
                        _yearSelectStart,
                        _alternateView,
                        _viewType,
                        widget.selectionMode,
                        (value) {},
                      ),
                  ],
                ),
              ],
            ),
          )
        : IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    OutlineButton(
                      onPressed: () {
                        setState(() {
                          switch (_viewType) {
                            case CalendarViewType.date:
                              _view = _view.previous;

                            case CalendarViewType.month:
                              _view = _view.previousYear;

                            case CalendarViewType.year:
                              _yearSelectStart -= 16;
                          }
                        });
                      },
                      density: ButtonDensity.icon,
                      child: Icon(
                        LucideIcons.arrowLeft,
                        color: arrowColor,
                      ).iconXSmall(),
                    ),
                    SizedBox(width: theme.scaling * 16),
                    Expanded(
                      child: GhostButton(
                        onPressed: () {
                          switch (_viewType) {
                            case CalendarViewType.date:
                              setState(() {
                                _viewType = CalendarViewType.month;
                              });

                            case CalendarViewType.month:
                              setState(() {
                                _viewType = CalendarViewType.year;
                              });

                            default:
                              break;
                          }
                        },
                        enabled: _viewType != CalendarViewType.year,
                        child: Text(
                          getHeaderText(localizations, _view, _viewType),
                        ).foreground().small().medium().center(),
                      ).sized(height: theme.scaling * 32),
                    ),
                    SizedBox(width: theme.scaling * 16),
                    OutlineButton(
                      onPressed: () {
                        setState(() {
                          switch (_viewType) {
                            case CalendarViewType.date:
                              _view = _view.next;

                            case CalendarViewType.month:
                              _view = _view.nextYear;

                            case CalendarViewType.year:
                              _yearSelectStart += 16;
                          }
                        });
                      },
                      density: ButtonDensity.icon,
                      child: Icon(
                        LucideIcons.arrowRight,
                        color: arrowColor,
                      ).iconXSmall(),
                    ),
                  ],
                ),
                Gap(theme.scaling * 16),
                buildView(
                  context,
                  _yearSelectStart,
                  _view,
                  _viewType,
                  widget.selectionMode,
                  (value) {
                    setState(() {
                      _view = value;
                      switch (_viewType) {
                        case CalendarViewType.date:
                          break;

                        case CalendarViewType.month:
                          _viewType = CalendarViewType.date;

                        case CalendarViewType.year:
                          _viewType = CalendarViewType.month;
                      }
                    });
                  },
                ),
              ],
            ),
          );
  }

  Widget buildView(
    BuildContext context,
    int yearSelectStart,
    CalendarView view,
    CalendarViewType viewType,
    CalendarSelectionMode selectionMode,
    ValueChanged<CalendarView> onViewChanged,
  ) {
    if (viewType == CalendarViewType.year) {
      return YearCalendar(
        calendarValue: _value,
        onChanged: (value) {
          setState(() {
            onViewChanged(view.copyWith(year: () => value));
          });
        },
        stateBuilder: widget.stateBuilder,
        yearSelectStart: yearSelectStart,
      );
    }

    return viewType == CalendarViewType.month
        ? MonthCalendar(
            calendarValue: _value,
            onChanged: onViewChanged,
            stateBuilder: widget.stateBuilder,
            value: view,
          )
        : Calendar(
            onChanged: (value) {
              setState(() {
                _value = value;
                widget.onChanged?.call(value);
              });
            },
            selectionMode: selectionMode,
            stateBuilder: widget.stateBuilder,
            value: _value,
            view: view,
          );
  }
}

/// Abstract base class representing calendar selection values.
///
/// Provides a unified interface for different types of calendar selections including
/// single dates, date ranges, and multiple date collections. Handles date lookup
/// operations and conversion between different selection types.
///
/// Subclasses include:
/// - [SingleCalendarValue]: Represents a single selected date
/// - [RangeCalendarValue]: Represents a date range with start and end
/// - [MultiCalendarValue]: Represents multiple individual selected dates
///
/// The class provides factory constructors for easy creation and conversion
/// methods to transform between different selection types as needed.
///
/// Example:
/// ```dart
/// // Create different value types
/// final single = CalendarValue.single(DateTime.now());
/// final range = CalendarValue.range(startDate, endDate);
/// final multi = CalendarValue.multi([date1, date2, date3]);
///
/// // Check if a date is selected
/// final lookup = value.lookup(2024, 3, 15);
/// final isSelected = lookup != CalendarValueLookup.none;
/// ```
abstract class CalendarValue {
  const CalendarValue();

  CalendarValueLookup lookup(int year, [int? day = 1, int? month = 1]);

  static SingleCalendarValue single(DateTime date) {
    return SingleCalendarValue(date);
  }

  static RangeCalendarValue range(DateTime end, DateTime start) {
    return RangeCalendarValue(start, end);
  }

  static MultiCalendarValue multi(List<DateTime> dates) {
    return MultiCalendarValue(dates);
  }

  SingleCalendarValue toSingle();

  RangeCalendarValue toRange();

  MultiCalendarValue toMulti();

  CalendarView get view;
}

DateTime _convertNecessarry(DateTime from, int year, [int? date, int? month]) {
  if (month == null) {
    return DateTime(from.year);
  }

  return date == null
      ? DateTime(from.year, from.month)
      : DateTime(from.year, from.month, from.day);
}

/// Calendar value representing a single selected date.
///
/// Encapsulates a single [DateTime] selection and provides lookup functionality
/// to determine if a given date matches the selected date. Used primarily
/// with [CalendarSelectionMode.single].
///
/// Example:
/// ```dart
/// final singleValue = SingleCalendarValue(DateTime(2024, 3, 15));
/// final lookup = singleValue.lookup(2024, 3, 15);
/// print(lookup == CalendarValueLookup.selected); // true
/// ```
class SingleCalendarValue extends CalendarValue {
  const SingleCalendarValue(this.date);

  final DateTime date;

  @override
  CalendarValueLookup lookup(int year, [int? day, int? month]) {
    final current = _convertNecessarry(date, year, month, day);

    return current.isAtSameMomentAs(DateTime(year, month ?? 1, day ?? 1))
        ? CalendarValueLookup.selected
        : CalendarValueLookup.none;
  }

  @override
  String toString() {
    return 'SingleCalendarValue($date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SingleCalendarValue && other.date == date;
  }

  @override
  SingleCalendarValue toSingle() {
    return this;
  }

  @override
  RangeCalendarValue toRange() {
    return CalendarValue.range(date, date);
  }

  @override
  MultiCalendarValue toMulti() {
    return CalendarValue.multi([date]);
  }

  @override
  CalendarView get view => date.toCalendarView();

  @override
  int get hashCode => date.hashCode;
}

class RangeCalendarValue extends CalendarValue {
  RangeCalendarValue(DateTime end, DateTime start)
    : start = start.isBefore(end) ? start : end,
      end = start.isBefore(end) ? end : start;

  final DateTime start;

  final DateTime end;

  @override
  CalendarValueLookup lookup(int year, [int? day, int? month]) {
    final start = _convertNecessarry(this.start, year, month, day);
    final end = _convertNecessarry(this.end, year, month, day);
    final current = DateTime(year, month ?? 1, day ?? 1);
    if (current.isAtSameMomentAs(start) && current.isAtSameMomentAs(end)) {
      return CalendarValueLookup.selected;
    }
    if (current.isAtSameMomentAs(start)) {
      return CalendarValueLookup.start;
    }
    if (current.isAtSameMomentAs(end)) {
      return CalendarValueLookup.end;
    }

    return current.isAfter(start) && current.isBefore(end)
        ? CalendarValueLookup.inRange
        : CalendarValueLookup.none;
  }

  @override
  String toString() {
    return 'RangedCalendarValue($start, $end)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RangeCalendarValue &&
        other.start == start &&
        other.end == end;
  }

  @override
  SingleCalendarValue toSingle() {
    return CalendarValue.single(start);
  }

  @override
  RangeCalendarValue toRange() {
    return this;
  }

  @override
  MultiCalendarValue toMulti() {
    final dates = <DateTime>[];
    for (
      DateTime date = start;
      date.isBefore(end);
      date = date.add(const Duration(days: 1))
    ) {
      dates.add(date);
    }
    dates.add(end);

    return CalendarValue.multi(dates);
  }

  @override
  CalendarView get view => start.toCalendarView();

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class MultiCalendarValue extends CalendarValue {
  const MultiCalendarValue(this.dates);

  final List<DateTime> dates;

  @override
  CalendarValueLookup lookup(int year, [int? day, int? month]) {
    final current = DateTime(year, month ?? 1, day ?? 1);

    return dates.any(
          (element) => _convertNecessarry(
            element,
            year,
            month,
            day,
          ).isAtSameMomentAs(current),
        )
        ? CalendarValueLookup.selected
        : CalendarValueLookup.none;
  }

  @override
  String toString() {
    return 'MultiCalendarValue($dates)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MultiCalendarValue && listEquals(other.dates, dates);
  }

  @override
  SingleCalendarValue toSingle() {
    return CalendarValue.single(dates.first);
  }

  @override
  RangeCalendarValue toRange() {
    assert(dates.isNotEmpty, 'Cannot convert empty list to range');
    final min = dates.reduce(
      (value, element) => value.isBefore(element) ? value : element,
    );
    final max = dates.reduce(
      (value, element) => value.isAfter(element) ? value : element,
    );

    return CalendarValue.range(min, max);
  }

  @override
  MultiCalendarValue toMulti() {
    return this;
  }

  @override
  CalendarView get view =>
      dates.firstOrNull?.toCalendarView() ?? CalendarView.now();

  @override
  int get hashCode => dates.hashCode;
}

/// Result type for calendar value lookup operations.
///
/// Indicates the relationship between a queried date and the current calendar selection:
/// - [none]: Date is not part of any selection
/// - [selected]: Date is directly selected (single mode or exact match)
/// - [start]: Date is the start of a selected range
/// - [end]: Date is the end of a selected range
/// - [inRange]: Date falls within a selected range but is not start/end
enum CalendarValueLookup { end, inRange, none, selected, start }

/// Represents a specific month and year view in calendar navigation.
///
/// Provides immutable representation of a calendar's current viewing position
/// with navigation methods to move between months and years. Used to control
/// which month/year combination is displayed in calendar grids.
///
/// Key Features:
/// - **Navigation Methods**: [next], [previous], [nextYear], [previousYear]
/// - **Factory Constructors**: [now()], [fromDateTime()]
/// - **Validation**: Ensures month values stay within 1-12 range
/// - **Immutable**: All navigation returns new CalendarView instances
///
/// Example:
/// ```dart
/// // Create views for different dates
/// final current = CalendarView.now();
/// final specific = CalendarView(2024, 3); // March 2024
/// final fromDate = CalendarView.fromDateTime(someDateTime);
///
/// // Navigate between months
/// final nextMonth = current.next;
/// final prevMonth = current.previous;
/// final nextYear = current.nextYear;
/// ```
class CalendarView {
  /// Creates a [CalendarView] for the specified year and month.
  ///
  /// Parameters:
  /// - [year] (int): Four-digit year value
  /// - [month] (int): Month number (1-12, where 1 = January)
  ///
  /// Throws [AssertionError] if month is not between 1 and 12.
  ///
  /// Example:
  /// ```dart
  /// final view = CalendarView(2024, 3); // March 2024
  /// ```
  CalendarView(this.month, this.year) {
    assert(month >= 1 && month <= 12, 'Month must be between 1 and 12');
  }

  /// Creates a [CalendarView] for the current month and year.
  ///
  /// Uses [DateTime.now()] to determine the current date and extracts
  /// the year and month components.
  ///
  /// Example:
  /// ```dart
  /// final currentView = CalendarView.now();
  /// ```
  factory CalendarView.now() {
    final now = DateTime.now();

    return CalendarView(now.year, now.month);
  }

  /// Creates a [CalendarView] from an existing [DateTime].
  ///
  /// Extracts the year and month components from the provided [DateTime]
  /// and creates a corresponding calendar view.
  ///
  /// Parameters:
  /// - [dateTime] (DateTime): Date to extract year and month from
  ///
  /// Example:
  /// ```dart
  /// final birthday = DateTime(1995, 7, 15);
  /// final view = CalendarView.fromDateTime(birthday); // July 1995
  /// ```
  factory CalendarView.fromDateTime(DateTime dateTime) {
    return CalendarView(dateTime.year, dateTime.month);
  }

  final int year;

  final int month;

  CalendarView get next {
    return month == 12
        ? CalendarView(year + 1, 1)
        : CalendarView(year, month + 1);
  }

  CalendarView get previous {
    return month == 1
        ? CalendarView(year - 1, 12)
        : CalendarView(year, month - 1);
  }

  CalendarView get nextYear {
    return CalendarView(year + 1, month);
  }

  CalendarView get previousYear {
    return CalendarView(year - 1, month);
  }

  @override
  String toString() {
    return 'CalendarView($year, $month)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CalendarView && other.year == year && other.month == month;
  }

  CalendarView copyWith({ValueGetter<int>? month, ValueGetter<int>? year}) {
    return CalendarView(
      year == null ? this.year : year(),
      month == null ? this.month : month(),
    );
  }

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

extension CalendarDateTime on DateTime {
  CalendarView toCalendarView() {
    return CalendarView.fromDateTime(this);
  }
}

/// A highly customizable calendar widget supporting multiple selection modes.
///
/// Displays a grid-based calendar interface allowing users to view and select dates
/// with comprehensive support for single selection, range selection, and multiple
/// date selection. Includes built-in date validation, state management, and theme integration.
///
/// Key Features:
/// - **Selection Modes**: Single date, date range, multiple dates, or display-only
/// - **Date Validation**: Custom date state builder for enabling/disabling dates
/// - **Interactive Grid**: Touch/click support with visual feedback
/// - **Theme Integration**: Follows coui_flutter design system
/// - **Accessibility**: Screen reader and keyboard navigation support
/// - **Customizable Appearance**: Themed colors, spacing, and visual states
///
/// The calendar automatically handles date logic, leap years, month boundaries,
/// and provides consistent visual feedback for different selection states.
///
/// Selection Behavior:
/// - **Single**: Click to select one date, click again to deselect
/// - **Range**: Click start date, then end date to form range
/// - **Multi**: Click multiple dates to build selection set
/// - **None**: Display-only mode with no interaction
///
/// Example:
/// ```dart
/// Calendar(
///   view: CalendarView.now(),
///   selectionMode: CalendarSelectionMode.range,
///   value: CalendarValue.range(startDate, endDate),
///   onChanged: (value) => setState(() => selectedDates = value),
///   stateBuilder: (date) => date.isBefore(DateTime.now())
///     ? DateState.disabled
///     : DateState.enabled,
/// )
/// ```
class Calendar extends StatefulWidget {
  /// Creates a [Calendar] widget with flexible date selection capabilities.
  ///
  /// Configures the calendar's view, selection behavior, and interaction handling
  /// with comprehensive options for customization and validation.
  ///
  /// Parameters:
  /// - [view] (CalendarView, required): Month/year to display in calendar grid
  /// - [selectionMode] (CalendarSelectionMode, required): How dates can be selected
  /// - [now] (DateTime?, optional): Current date for highlighting, defaults to DateTime.now()
  /// - [value] (CalendarValue?, optional): Currently selected date(s)
  /// - [onChanged] (ValueChanged<CalendarValue?>?, optional): Called when selection changes
  /// - [isDateEnabled] (bool Function(DateTime)?, optional): Legacy date validation function
  /// - [stateBuilder] (DateStateBuilder?, optional): Custom date state validation
  ///
  /// The [view] parameter determines which month and year are shown in the calendar grid.
  /// Use [CalendarView.now()] for current month or [CalendarView(year, month)] for specific dates.
  ///
  /// The [stateBuilder] takes precedence over [isDateEnabled] when both are provided.
  ///
  /// Example:
  /// ```dart
  /// Calendar(
  ///   view: CalendarView(2024, 3), // March 2024
  ///   selectionMode: CalendarSelectionMode.single,
  ///   onChanged: (value) => print('Selected: ${value?.toString()}'),
  ///   stateBuilder: (date) => date.weekday == DateTime.sunday
  ///     ? DateState.disabled
  ///     : DateState.enabled,
  /// )
  /// ```
  const Calendar({
    super.key,
    this.now,
    this.onChanged,
    required this.selectionMode,
    this.stateBuilder,
    this.value,
    required this.view,
  });

  final DateTime? now;
  final CalendarValue? value;
  final CalendarView view;
  final CalendarSelectionMode selectionMode;
  final ValueChanged<CalendarValue?>? onChanged;
  final DateStateBuilder? stateBuilder;

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late CalendarGridData _gridData;

  @override
  void initState() {
    super.initState();
    _gridData = CalendarGridData(
      month: widget.view.month,
      year: widget.view.year,
    );
  }

  void _handleTap(DateTime date) {
    CalendarValue? calendarValue = widget.value;
    if (widget.selectionMode == CalendarSelectionMode.none) {
      return;
    }
    if (widget.selectionMode == CalendarSelectionMode.single) {
      if (calendarValue is SingleCalendarValue &&
          date.isAtSameMomentAs(calendarValue.date)) {
        widget.onChanged?.call(null);

        return;
      }
      widget.onChanged?.call(CalendarValue.single(date));

      return;
    }
    if (widget.selectionMode == CalendarSelectionMode.multi) {
      if (calendarValue == null) {
        widget.onChanged?.call(CalendarValue.single(date));

        return;
      }
      final lookup = calendarValue.lookup(date.year, date.month, date.day);
      if (lookup == CalendarValueLookup.none) {
        final multi = calendarValue.toMulti();
        multi.dates.add(date);
        widget.onChanged?.call(multi);

        return;
      }
      final multi = calendarValue.toMulti();
      multi.dates.remove(date);
      if (multi.dates.isEmpty) {
        widget.onChanged?.call(null);

        return;
      }
      widget.onChanged?.call(multi);

      return;
    }
    if (widget.selectionMode == CalendarSelectionMode.range) {
      if (calendarValue == null) {
        widget.onChanged?.call(CalendarValue.single(date));

        return;
      }
      if (calendarValue is MultiCalendarValue) {
        calendarValue = calendarValue.toRange();
      }
      if (calendarValue is SingleCalendarValue) {
        final selectedDate = calendarValue.date;
        if (date.isAtSameMomentAs(selectedDate)) {
          widget.onChanged?.call(null);

          return;
        }
        widget.onChanged?.call(CalendarValue.range(selectedDate, date));

        return;
      }
      if (calendarValue is RangeCalendarValue) {
        final start = calendarValue.start;
        final end = calendarValue.end;
        if (date.isBefore(start)) {
          widget.onChanged?.call(CalendarValue.range(date, end));

          return;
        }
        if (date.isAfter(end)) {
          widget.onChanged?.call(CalendarValue.range(start, date));

          return;
        }
        if (date.isAtSameMomentAs(start)) {
          widget.onChanged?.call(null);

          return;
        }
        if (date.isAtSameMomentAs(end)) {
          widget.onChanged?.call(CalendarValue.single(end));

          return;
        }
        widget.onChanged?.call(CalendarValue.range(start, date));
      }
    }
  }

  @override
  void didUpdateWidget(covariant Calendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.year != widget.view.year ||
        oldWidget.view.month != widget.view.month) {
      _gridData = CalendarGridData(
        month: widget.view.month,
        year: widget.view.year,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalendarGrid(
      data: _gridData,
      itemBuilder: (item) {
        final date = item.date;
        final lookup =
            widget.value?.lookup(date.year, date.month, date.day) ??
            CalendarValueLookup.none;
        CalendarItemType type = CalendarItemType.none;
        switch (lookup) {
          case CalendarValueLookup.none:
            if (widget.now != null && widget.now!.isAtSameMomentAs(date)) {
              type = CalendarItemType.today;
            }

          case CalendarValueLookup.selected:
            type = CalendarItemType.selected;

          case CalendarValueLookup.start:
            type = CalendarItemType.startRangeSelected;

          case CalendarValueLookup.end:
            type = CalendarItemType.endRangeSelected;

          case CalendarValueLookup.inRange:
            type = CalendarItemType.inRange;
        }
        final calendarItem = CalendarItem(
          indexAtRow: item.indexInRow,
          onTap: () {
            _handleTap(date);
          },
          rowCount: 7,
          state: widget.stateBuilder?.call(date) ?? DateState.enabled,
          type: type,
          child: Text('${date.day}'),
        );

        return item.fromAnotherMonth
            ? Opacity(opacity: 0.5, child: calendarItem)
            : calendarItem;
      },
    );
  }
}

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    this.calendarValue,
    super.key,
    this.now,
    required this.onChanged,
    this.stateBuilder,
    required this.value,
  });

  final CalendarView value;
  final ValueChanged<CalendarView> onChanged;
  final DateTime? now;
  final CalendarValue? calendarValue;

  final DateStateBuilder? stateBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Same as Calendar, but instead of showing date it shows month in a 4x3 grid.
    final localizations = CoUILocalizations.of(context);
    final rows = <Widget>[];
    final months = <Widget>[];
    for (int i = 1; i <= 12; i += 1) {
      final date = DateTime(value.year, i);
      CalendarItemType type = CalendarItemType.none;
      if (calendarValue == null) {
        if (now != null &&
            DateTime(now!.year, now!.month).isAtSameMomentAs(date)) {
          type = CalendarItemType.today;
        }
      } else {
        final lookup = calendarValue!.lookup(date.year, date.month);
        switch (lookup) {
          case CalendarValueLookup.none:
            if (now != null &&
                DateTime(now!.year, now!.month).isAtSameMomentAs(date)) {
              type = CalendarItemType.today;
            }

          case CalendarValueLookup.selected:
            type = CalendarItemType.selected;

          case CalendarValueLookup.start:
            type = CalendarItemType.startRangeSelected;

          case CalendarValueLookup.end:
            type = CalendarItemType.endRangeSelected;

          case CalendarValueLookup.inRange:
            type = CalendarItemType.inRange;
        }
      }
      months.add(
        CalendarItem(
          key: ValueKey(date),
          indexAtRow: (i - 1) % 4,
          onTap: () {
            onChanged(value.copyWith(month: () => i));
          },
          rowCount: 4,
          state: stateBuilder?.call(date) ?? DateState.enabled,
          type: type,
          width: theme.scaling * 56,
          child: Text(localizations.getAbbreviatedMonth(i)),
        ),
      );
    }
    for (int i = 0; i < months.length; i += 4) {
      rows.add(Gap(theme.scaling * 8));
      rows.add(Row(children: months.sublist(i, i + 4)));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

class YearCalendar extends StatelessWidget {
  const YearCalendar({
    this.calendarValue,
    super.key,
    this.now,
    required this.onChanged,
    this.stateBuilder,
    required this.yearSelectStart,
  });

  final int yearSelectStart;
  final ValueChanged<int> onChanged;
  final DateTime? now;
  final CalendarValue? calendarValue;

  final DateStateBuilder? stateBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Same as Calendar, but instead of showing date it shows year in a 4x4 grid.
    final rows = <Widget>[];
    final years = <Widget>[];
    for (int i = yearSelectStart; i < yearSelectStart + 16; i += 1) {
      final date = DateTime(i);
      CalendarItemType type = CalendarItemType.none;
      if (calendarValue == null) {
        if (now != null && now!.year == date.year) {
          type = CalendarItemType.today;
        }
      } else {
        final lookup = calendarValue!.lookup(date.year);
        switch (lookup) {
          case CalendarValueLookup.none:
            if (now != null && now!.year == date.year) {
              type = CalendarItemType.today;
            }

          case CalendarValueLookup.selected:
            type = CalendarItemType.selected;

          case CalendarValueLookup.start:
            type = CalendarItemType.startRangeSelected;

          case CalendarValueLookup.end:
            type = CalendarItemType.endRangeSelected;

          case CalendarValueLookup.inRange:
            type = CalendarItemType.inRange;
        }
      }
      years.add(
        CalendarItem(
          key: ValueKey(date),
          indexAtRow: (i - yearSelectStart) % 4,
          onTap: () {
            onChanged(i);
          },
          rowCount: 4,
          state: stateBuilder?.call(date) ?? DateState.enabled,
          type: type,
          width: theme.scaling * 56,
          child: Text('$i'),
        ),
      );
    }
    for (int i = 0; i < years.length; i += 4) {
      rows.add(Gap(theme.scaling * 8));
      rows.add(Row(children: years.sublist(i, i + 4)));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// Visual states for individual calendar date items.
///
/// Defines the different visual appearances and behaviors that calendar date cells
/// can have based on their selection state and position within ranges.
///
/// States include:
/// - [none]: Normal unselected date
/// - [today]: Current date highlighted
/// - [selected]: Single selected date or exact range boundary
/// - [inRange]: Date within a selected range but not start/end
/// - [startRange]/[endRange]: Range boundaries in other months
/// - [startRangeSelected]/[endRangeSelected]: Range boundaries in current month
/// - [startRangeSelectedShort]/[endRangeSelectedShort]: Boundaries in short ranges
/// - [inRangeSelectedShort]: Middle dates in short ranges (typically 2-day ranges)
enum CalendarItemType {
  /// Same as startRangeSelected, but used for other months.
  /// Same as endRangeSelected, but used for other months.
  endRange,
  endRangeSelected,
  endRangeSelectedShort, // usually when the range are just 2 days
  // when its the date in the range
  inRange,
  inRangeSelectedShort,
  none,
  selected,
  startRange,
  startRangeSelected,
  startRangeSelectedShort,
  today,
}

/// Individual calendar date cell with interactive behavior and visual states.
///
/// Represents a single date item within a calendar grid, handling touch interactions,
/// visual state management, and theme integration. Supports different visual states
/// for selection, ranges, and special dates like today.
///
/// Key Features:
/// - **Visual States**: Multiple appearance modes based on selection status
/// - **Interactive**: Touch/click handling with callbacks
/// - **Responsive Sizing**: Configurable width/height with theme scaling
/// - **Accessibility**: Screen reader support and focus management
/// - **State Management**: Enabled/disabled states with visual feedback
/// - **Range Support**: Special styling for range start/end/middle positions
///
/// The item automatically applies appropriate button styling based on its [type]
/// and handles edge cases for range visualization at row boundaries.
///
/// Example:
/// ```dart
/// CalendarItem(
///   type: CalendarItemType.selected,
///   indexAtRow: 2,
///   rowCount: 7,
///   state: DateState.enabled,
///   onTap: () => handleDateTap(date),
///   child: Text('15'),
/// )
/// ```
class CalendarItem extends StatelessWidget {
  const CalendarItem({
    required this.child,
    this.height,
    required this.indexAtRow,
    super.key,
    this.onTap,
    required this.rowCount,
    required this.state,
    required this.type,
    this.width,
  });

  final Widget child;
  final CalendarItemType type;
  final VoidCallback? onTap;
  final int indexAtRow;
  final int rowCount;
  final double? width;
  final double? height;

  final DateState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    CalendarItemType type = this.type;
    if ((indexAtRow == 0 || indexAtRow == rowCount - 1) &&
        (type == CalendarItemType.startRangeSelected ||
            type == CalendarItemType.endRangeSelected ||
            type == CalendarItemType.startRangeSelectedShort ||
            type == CalendarItemType.endRangeSelectedShort)) {
      type = CalendarItemType.selected;
    }
    switch (type) {
      case CalendarItemType.none:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: GhostButton(
            onPressed: onTap,
            enabled: state == DateState.enabled,
            alignment: Alignment.center,
            density: ButtonDensity.compact,
            child: child,
          ),
        );

      case CalendarItemType.today:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: SecondaryButton(
            onPressed: onTap,
            enabled: state == DateState.enabled,
            alignment: Alignment.center,
            density: ButtonDensity.compact,
            child: child,
          ),
        );

      case CalendarItemType.selected:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: PrimaryButton(
            onPressed: onTap,
            enabled: state == DateState.enabled,
            alignment: Alignment.center,
            density: ButtonDensity.compact,
            child: child,
          ),
        );

      case CalendarItemType.inRange:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: Button(
            onPressed: onTap,
            style:
                const ButtonStyle(
                  variance: ButtonVariance.secondary,
                  density: ButtonDensity.compact,
                ).copyWith(
                  decoration: (context, states, value) {
                    return (value as BoxDecoration).copyWith(
                      borderRadius: indexAtRow == 0
                          ? BorderRadius.only(
                              topLeft: Radius.circular(theme.radiusMd),
                              bottomLeft: Radius.circular(theme.radiusMd),
                            )
                          : indexAtRow == rowCount - 1
                          ? BorderRadius.only(
                              topRight: Radius.circular(theme.radiusMd),
                              bottomRight: Radius.circular(theme.radiusMd),
                            )
                          : BorderRadius.zero,
                    );
                  },
                ),
            alignment: Alignment.center,
            enabled: state == DateState.enabled,
            child: child,
          ),
        );

      case CalendarItemType.startRange:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: Button(
            onPressed: onTap,
            style:
                const ButtonStyle(
                  variance: ButtonVariance.secondary,
                  density: ButtonDensity.compact,
                ).copyWith(
                  decoration: (context, states, value) {
                    return (value as BoxDecoration).copyWith(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(theme.radiusMd),
                        bottomLeft: Radius.circular(theme.radiusMd),
                      ),
                    );
                  },
                ),
            alignment: Alignment.center,
            enabled: state == DateState.enabled,
            child: child,
          ),
        );

      case CalendarItemType.endRange:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: Button(
            onPressed: onTap,
            style:
                const ButtonStyle(
                  variance: ButtonVariance.secondary,
                  density: ButtonDensity.compact,
                ).copyWith(
                  decoration: (context, states, value) {
                    return (value as BoxDecoration).copyWith(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(theme.radiusMd),
                        bottomRight: Radius.circular(theme.radiusMd),
                      ),
                    );
                  },
                ),
            alignment: Alignment.center,
            enabled: state == DateState.enabled,
            child: child,
          ),
        );

      case CalendarItemType.startRangeSelected:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(theme.radiusMd),
                    bottomLeft: Radius.circular(theme.radiusMd),
                  ),
                ),
                width: width ?? theme.scaling * 32,
                height: height ?? theme.scaling * 32,
              ),
              PrimaryButton(
                onPressed: onTap,
                enabled: state == DateState.enabled,
                alignment: Alignment.center,
                density: ButtonDensity.compact,
                child: child,
              ),
            ],
          ),
        );

      case CalendarItemType.endRangeSelected:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(theme.radiusMd),
                    bottomRight: Radius.circular(theme.radiusMd),
                  ),
                ),
                width: width ?? theme.scaling * 32,
                height: height ?? theme.scaling * 32,
              ),
              PrimaryButton(
                onPressed: onTap,
                enabled: state == DateState.enabled,
                alignment: Alignment.center,
                density: ButtonDensity.compact,
                child: child,
              ),
            ],
          ),
        );

      case CalendarItemType.startRangeSelectedShort:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: Button(
            onPressed: onTap,
            style:
                const ButtonStyle(
                  variance: ButtonVariance.primary,
                  density: ButtonDensity.compact,
                ).copyWith(
                  decoration: (context, states, value) {
                    return (value as BoxDecoration).copyWith(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(theme.radiusMd),
                        bottomLeft: Radius.circular(theme.radiusMd),
                      ),
                    );
                  },
                ),
            alignment: Alignment.center,
            enabled: state == DateState.enabled,
            child: child,
          ),
        );

      case CalendarItemType.endRangeSelectedShort:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: Button(
            onPressed: onTap,
            style:
                const ButtonStyle(
                  variance: ButtonVariance.primary,
                  density: ButtonDensity.compact,
                ).copyWith(
                  decoration: (context, states, value) {
                    return (value as BoxDecoration).copyWith(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(theme.radiusMd),
                        bottomRight: Radius.circular(theme.radiusMd),
                      ),
                    );
                  },
                ),
            alignment: Alignment.center,
            enabled: state == DateState.enabled,
            child: child,
          ),
        );

      case CalendarItemType.inRangeSelectedShort:
        return SizedBox(
          width: width ?? theme.scaling * 32,
          height: height ?? theme.scaling * 32,
          child: Button(
            onPressed: onTap,
            style:
                const ButtonStyle(
                  variance: ButtonVariance.primary,
                  density: ButtonDensity.compact,
                ).copyWith(
                  decoration: (context, states, value) {
                    return (value as BoxDecoration).copyWith(
                      borderRadius: BorderRadius.zero,
                    );
                  },
                ),
            alignment: Alignment.center,
            enabled: state == DateState.enabled,
            child: child,
          ),
        );
    }
  }
}

class CalendarGridData {
  factory CalendarGridData({required int month, required int year}) {
    final firstDayOfMonth = DateTime(year, month);
    final daysInMonth = DateTime(year, month == 12 ? 1 : month + 1, 0).day;

    final prevMonthDays = firstDayOfMonth.weekday;
    final prevMonthLastDay = firstDayOfMonth.subtract(
      Duration(days: prevMonthDays),
    );

    final items = <CalendarGridItem>[];

    int itemCount = 0;

    if (prevMonthDays < 7) {
      for (int i = 0; i < prevMonthDays; i += 1) {
        final currentItemIndex = itemCount += 1;
        items.add(
          CalendarGridItem(
            prevMonthLastDay.add(Duration(days: i)),
            true,
            currentItemIndex % 7,
            currentItemIndex ~/ 7,
          ),
        );
      }
    }

    for (int i = 0; i < daysInMonth; i += 1) {
      final currentItemIndex = itemCount += 1;
      final currentDay = DateTime(year, month, i + 1);
      items.add(
        CalendarGridItem(
          currentDay,
          false,
          currentItemIndex % 7,
          currentItemIndex ~/ 7,
        ),
      );
    }

    final remainingDays = (7 - (items.length % 7)) % 7;
    final nextMonthFirstDay = DateTime(year, month + 1);

    if (remainingDays < 7) {
      for (int i = 0; i < remainingDays; i += 1) {
        final currentItemIndex = itemCount += 1;
        items.add(
          CalendarGridItem(
            nextMonthFirstDay.add(Duration(days: i)),
            true,
            currentItemIndex % 7,
            currentItemIndex ~/ 7,
          ),
        );
      }
    }

    return CalendarGridData._(items, month, year);
  }
  const CalendarGridData._(this.items, this.month, this.year);

  final int month;

  final int year;

  final List<CalendarGridItem> items;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CalendarGridData &&
        other.month == month &&
        other.year == year &&
        listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hash(month, year, items);
}

class CalendarGridItem {
  const CalendarGridItem(
    this.date,
    this.fromAnotherMonth,
    this.indexInRow,
    this.rowIndex,
  );

  final DateTime date;
  final int indexInRow;
  final int rowIndex;

  final bool fromAnotherMonth;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CalendarGridItem &&
        other.date.isAtSameMomentAs(date) &&
        other.indexInRow == indexInRow &&
        other.fromAnotherMonth == fromAnotherMonth &&
        other.rowIndex == rowIndex;
  }

  @override
  int get hashCode => Object.hash(date, indexInRow, fromAnotherMonth, rowIndex);
}

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    required this.data,
    required this.itemBuilder,
    super.key,
  });

  final CalendarGridData data;

  final Widget Function(CalendarGridItem item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = CoUILocalizations.of(context);
    // Do not use GridView because it doesn't support IntrinsicWidth.
    final rows = <Widget>[];
    final weekDays = <Widget>[];
    for (int i = 0; i < 7; i += 1) {
      final weekday = ((i - 1) % 7) + 1;
      weekDays.add(
        Container(
          alignment: Alignment.center,
          width: theme.scaling * 32,
          height: theme.scaling * 32,
          child: Text(
            localizations.getAbbreviatedWeekday(weekday),
          ).muted().xSmall(),
        ),
      );
    }
    rows.add(Row(mainAxisSize: MainAxisSize.min, children: weekDays));
    for (int i = 0; i < data.items.length; i += 7) {
      rows.add(
        Row(
          children: data.items.sublist(i, i + 7).map((e) {
            return SizedBox.square(
              dimension: theme.scaling * 32,
              child: itemBuilder(e),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.scaling * 8,
      children: rows,
    );
  }
}
