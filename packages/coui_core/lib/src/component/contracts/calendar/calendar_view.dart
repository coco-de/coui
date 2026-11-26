import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

/// Last (December) month index in a calendar year — calendrical
/// constant, not a design token.
const int _kLastMonth = 12;

/// Platform-independent calendar view position.
///
/// Represents a month/year combination for calendar navigation.
/// Immutable — all navigation methods return new instances.
@immutable
class CoreCalendarView {
  /// Creates a [CoreCalendarView] for the given [year] and [month].
  const CoreCalendarView(this.year, this.month)
    : assert(
        month >= 1 && month <= _kLastMonth,
        'Month must be between 1 and 12',
      );

  /// Creates a [CoreCalendarView] for the month of [currentTime].
  factory CoreCalendarView.now() {
    final now = currentTime();
    return CoreCalendarView(now.year, now.month);
  }

  /// Creates a [CoreCalendarView] from a [DateTime].
  factory CoreCalendarView.fromDateTime(DateTime dateTime) {
    return CoreCalendarView(dateTime.year, dateTime.month);
  }

  /// The moment a calendar treats as now — the month it opens on when it is
  /// given no view or value, and the day it marks as today.
  ///
  /// Reads `clock.now()` from `package:clock`, which is `DateTime.now()`
  /// unless the caller runs under `withClock`. Both platforms read today
  /// from here, so a test or a capture harness that fixes the clock moves
  /// the opening month and the today mark on both platforms together.
  static DateTime currentTime() => clock.now();

  /// The year.
  final int year;

  /// The month (1-12).
  final int month;

  /// Returns the next month view.
  CoreCalendarView get next {
    return month == _kLastMonth
        ? CoreCalendarView(year + 1, 1)
        : CoreCalendarView(year, month + 1);
  }

  /// Returns the previous month view.
  CoreCalendarView get previous {
    return month == 1
        ? CoreCalendarView(year - 1, _kLastMonth)
        : CoreCalendarView(year, month - 1);
  }

  /// Returns the same month in the next year.
  CoreCalendarView get nextYear => .new(year + 1, month);

  /// Returns the same month in the previous year.
  CoreCalendarView get previousYear => .new(year - 1, month);

  /// Creates a copy with optional overrides.
  CoreCalendarView copyWith({
    int Function()? year,
    int Function()? month,
  }) {
    return CoreCalendarView(
      year != null ? year() : this.year,
      month != null ? month() : this.month,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCalendarView && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'CoreCalendarView($year, $month)';
}
