import 'package:meta/meta.dart';

/// Platform-independent calendar grid data.
///
/// Computes the day cells for a given month, including
/// leading days from the previous month and trailing days
/// from the next month to fill complete weeks.
///
/// The week starts on [firstDayOfWeek], so the same month is laid out
/// differently for a Sunday-first and a Monday-first calendar: the number of
/// leading days is how far the 1st sits past the first day of the week.
/// [weekdayOrder] is the header row that goes with the grid — both seats read
/// it instead of keeping their own list of weekdays.
@immutable
class CoreCalendarGridData {
  /// Creates grid data for the given [month] and [year], with a week that
  /// starts on [firstDayOfWeek] — a `DateTime.monday`…`DateTime.sunday`
  /// value, Sunday by default.
  factory CoreCalendarGridData({
    required int month,
    required int year,
    int firstDayOfWeek = DateTime.sunday,
  }) {
    assert(
      firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
      'firstDayOfWeek must be a DateTime weekday '
      '(DateTime.monday..DateTime.sunday), got $firstDayOfWeek',
    );

    final firstDayOfMonth = DateTime(year, month);
    final daysInMonth = DateTime(
      year,
      month == lastMonth ? 1 : month + 1,
      0,
    ).day;

    // How far the 1st sits past the first day of the week. Dart's `%` is
    // never negative, so a Monday-first week that meets a Sunday 1st gives
    // `(7 - 1) % 7 = 6`.
    final prevMonthDays =
        (firstDayOfMonth.weekday - firstDayOfWeek) % daysPerWeek;

    final items = <CoreCalendarGridItem>[];

    // Leading days from previous month. Each cell is a date in its own right
    // (calendar arithmetic on the day-of-month, which `DateTime` normalises
    // across month and year ends) rather than the 1st shifted by a number of
    // 24-hour spans: across a daylight-saving change a span lands on 23:00
    // of the previous day, which prints the wrong day number and selects the
    // wrong date when tapped.
    for (var i = 0; i < prevMonthDays; i++) {
      items.add(
        CoreCalendarGridItem(
          date: DateTime(year, month, 1 - prevMonthDays + i),
          fromAnotherMonth: true,
          indexInRow: items.length % daysPerWeek,
          rowIndex: items.length ~/ daysPerWeek,
        ),
      );
    }

    // Days of the current month.
    for (var i = 0; i < daysInMonth; i++) {
      items.add(
        CoreCalendarGridItem(
          date: DateTime(year, month, i + 1),
          fromAnotherMonth: false,
          indexInRow: items.length % daysPerWeek,
          rowIndex: items.length ~/ daysPerWeek,
        ),
      );
    }

    // Trailing days from next month.
    final remainingDays =
        (daysPerWeek - (items.length % daysPerWeek)) % daysPerWeek;
    for (var i = 0; i < remainingDays; i++) {
      items.add(
        CoreCalendarGridItem(
          date: DateTime(year, month + 1, 1 + i),
          fromAnotherMonth: true,
          indexInRow: items.length % daysPerWeek,
          rowIndex: items.length ~/ daysPerWeek,
        ),
      );
    }

    return CoreCalendarGridData._(items, month, year, firstDayOfWeek);
  }

  const CoreCalendarGridData._(
    this.items,
    this.month,
    this.year,
    this.firstDayOfWeek,
  );

  /// The weekdays a header row shows, left to right, for a week that starts
  /// on [firstDayOfWeek] — [DateTime] weekday numbers
  /// (`DateTime.monday`…`DateTime.sunday`), which is what the locale's
  /// weekday names are looked up by.
  ///
  /// The one statement of the order: the grid's columns are laid out by the
  /// same [firstDayOfWeek], so a header drawn from anything else would head
  /// the wrong columns.
  static List<int> weekdayOrder(int firstDayOfWeek) {
    assert(
      firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
      'firstDayOfWeek must be a DateTime weekday '
      '(DateTime.monday..DateTime.sunday), got $firstDayOfWeek',
    );

    return [
      for (var i = 0; i < daysPerWeek; i++)
        (firstDayOfWeek - DateTime.monday + i) % daysPerWeek + DateTime.monday,
    ];
  }

  /// Number of days in a calendar week — not a design token, a calendrical
  /// constant for grid row math (single source for the week-row width).
  static const int daysPerWeek = 7;

  /// First (January) month index in a calendar year (1-based).
  static const int firstMonth = 1;

  /// Last (December) month index in a calendar year (1-based) — used to wrap
  /// to the next year.
  static const int lastMonth = 12;

  /// The month this grid represents.
  final int month;

  /// The year this grid represents.
  final int year;

  /// The weekday the week starts on — a `DateTime.monday`…`DateTime.sunday`
  /// value. The first column of the grid is this weekday.
  final int firstDayOfWeek;

  /// All grid items
  /// (previous month trailing + current month + next month leading).
  final List<CoreCalendarGridItem> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCalendarGridData &&
          other.month == month &&
          other.year == year &&
          other.firstDayOfWeek == firstDayOfWeek;

  @override
  int get hashCode => Object.hash(month, year, firstDayOfWeek);
}

/// A single cell in the calendar grid.
@immutable
class CoreCalendarGridItem {
  /// Creates a [CoreCalendarGridItem].
  const CoreCalendarGridItem({
    required this.date,
    required this.fromAnotherMonth,
    required this.indexInRow,
    required this.rowIndex,
  });

  /// The date this cell represents.
  final DateTime date;

  /// Whether this date belongs to the previous or next month.
  final bool fromAnotherMonth;

  /// Column index within the week row (0-6, 0 = the first day of the week —
  /// [CoreCalendarGridData.firstDayOfWeek], not necessarily a Sunday).
  final int indexInRow;

  /// Row index within the grid.
  final int rowIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCalendarGridItem &&
          other.date.isAtSameMomentAs(date) &&
          other.indexInRow == indexInRow &&
          other.fromAnotherMonth == fromAnotherMonth &&
          other.rowIndex == rowIndex;

  @override
  int get hashCode => Object.hash(date, indexInRow, fromAnotherMonth, rowIndex);
}
