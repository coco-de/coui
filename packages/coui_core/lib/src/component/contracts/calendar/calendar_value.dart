import 'package:coui_core/src/component/contracts/calendar/calendar_contract.dart';
import 'package:coui_core/src/component/contracts/calendar/calendar_view.dart';
import 'package:meta/meta.dart';

/// Platform-independent calendar selection value.
///
/// Represents the current date selection state for calendars.
/// Supports single, range, and multi-date selections.
abstract class CoreCalendarValue {
  /// Creates a [CoreCalendarValue].
  const CoreCalendarValue();

  /// Creates a single date selection.
  static CoreSingleCalendarValue single(DateTime date) {
    return CoreSingleCalendarValue(date);
  }

  /// Creates a date range selection.
  static CoreRangeCalendarValue range(DateTime start, DateTime end) {
    return CoreRangeCalendarValue(start, end);
  }

  /// Creates a multi-date selection.
  static CoreMultiCalendarValue multi(List<DateTime> dates) {
    return CoreMultiCalendarValue(dates);
  }

  /// Looks up whether a date matches this selection.
  CoreCalendarValueLookup lookup(int year, [int? month, int? day]);

  /// Converts to a single value (uses first date).
  CoreSingleCalendarValue toSingle();

  /// Converts to a range value.
  CoreRangeCalendarValue toRange();

  /// Converts to a multi value.
  CoreMultiCalendarValue toMulti();

  /// The year of the primary date for initial view positioning.
  int get viewYear;

  /// The month of the primary date for initial view positioning.
  int get viewMonth;
}

/// Normalizes a DateTime to the appropriate precision for comparison.
DateTime _normalizeDate(DateTime from, int year, [int? month, int? day]) {
  if (month == null) {
    return DateTime(from.year);
  }
  return day == null
      ? DateTime(from.year, from.month)
      : DateTime(from.year, from.month, from.day);
}

/// Single date selection value.
@immutable
class CoreSingleCalendarValue extends CoreCalendarValue {
  /// Creates a [CoreSingleCalendarValue].
  const CoreSingleCalendarValue(this.date);

  /// The selected date.
  final DateTime date;

  @override
  CoreCalendarValueLookup lookup(int year, [int? month, int? day]) {
    final current = _normalizeDate(date, year, month, day);
    final target = DateTime(year, month ?? 1, day ?? 1);
    return current.isAtSameMomentAs(target) ? .selected : .none;
  }

  @override
  CoreSingleCalendarValue toSingle() => this;

  @override
  CoreRangeCalendarValue toRange() => CoreCalendarValue.range(date, date);

  @override
  CoreMultiCalendarValue toMulti() => CoreCalendarValue.multi([date]);

  @override
  int get viewYear => date.year;

  @override
  int get viewMonth => date.month;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSingleCalendarValue && other.date == date;

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() => 'CoreSingleCalendarValue($date)';
}

/// Date range selection value.
@immutable
class CoreRangeCalendarValue extends CoreCalendarValue {
  /// Creates a [CoreRangeCalendarValue].
  ///
  /// Automatically normalizes so [start] <= [end].
  CoreRangeCalendarValue(DateTime a, DateTime b)
    : start = a.isBefore(b) ? a : b,
      end = a.isBefore(b) ? b : a;

  /// Range start date.
  final DateTime start;

  /// Range end date.
  final DateTime end;

  @override
  CoreCalendarValueLookup lookup(int year, [int? month, int? day]) {
    final s = _normalizeDate(start, year, month, day);
    final e = _normalizeDate(end, year, month, day);
    final current = DateTime(year, month ?? 1, day ?? 1);

    if (current.isAtSameMomentAs(s) && current.isAtSameMomentAs(e)) {
      return .selected;
    }
    if (current.isAtSameMomentAs(s)) return .start;
    if (current.isAtSameMomentAs(e)) return .end;
    if (current.isAfter(s) && current.isBefore(e)) {
      return .inRange;
    }
    return .none;
  }

  @override
  CoreSingleCalendarValue toSingle() => CoreCalendarValue.single(start);

  @override
  CoreRangeCalendarValue toRange() => this;

  @override
  CoreMultiCalendarValue toMulti() {
    final dates = <DateTime>[];
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      dates.add(date);
    }
    return CoreCalendarValue.multi(dates);
  }

  @override
  int get viewYear => start.year;

  @override
  int get viewMonth => start.month;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRangeCalendarValue &&
          other.start == start &&
          other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'CoreRangeCalendarValue($start, $end)';
}

/// Multi-date selection value.
@immutable
class CoreMultiCalendarValue extends CoreCalendarValue {
  /// Creates a [CoreMultiCalendarValue].
  const CoreMultiCalendarValue(this.dates);

  /// The selected dates.
  final List<DateTime> dates;

  @override
  CoreCalendarValueLookup lookup(int year, [int? month, int? day]) {
    final current = DateTime(year, month ?? 1, day ?? 1);
    final hasMatch = dates.any(
      (d) => _normalizeDate(d, year, month, day).isAtSameMomentAs(current),
    );
    return hasMatch ? .selected : .none;
  }

  @override
  CoreSingleCalendarValue toSingle() => CoreCalendarValue.single(dates.first);

  @override
  CoreRangeCalendarValue toRange() {
    assert(dates.isNotEmpty, 'Cannot convert empty list to range.');
    final min = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final max = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return CoreCalendarValue.range(min, max);
  }

  @override
  CoreMultiCalendarValue toMulti() => this;

  @override
  int get viewYear =>
      dates.isNotEmpty ? dates.first.year : CoreCalendarView.currentTime().year;

  @override
  int get viewMonth => dates.isNotEmpty
      ? dates.first.month
      : CoreCalendarView.currentTime().month;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreMultiCalendarValue) return false;
    if (other.dates.length != dates.length) return false;
    for (var i = 0; i < dates.length; i++) {
      if (other.dates[i] != dates[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(dates);

  @override
  String toString() => 'CoreMultiCalendarValue($dates)';
}
