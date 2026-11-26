// CoreCalendarGridData lays a month out for a week that starts on any
// weekday, and CoreCalendarGridData.weekdayOrder is the one statement of the
// header row that goes with it. The Flutter and Web calendars both draw the
// grid from this class and the header from that helper, and their own tests
// read the same vector table this file pins to the Core definition — so a
// change to where a week starts fails on every platform at once.
//
// The table was derived with Python's `datetime`, not with the code under
// test: a grid and its expectations computed by the same arithmetic could
// only ever agree.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter and Web calendar tests.
const String kCalendarWeekStartVectorsPath =
    'test/fixtures/calendar_week_start_vectors.json';

DateTime _iso(String date) {
  final parts = date.split('-').map(int.parse).toList();

  return DateTime(parts[0], parts[1], parts[2]);
}

void main() {
  final doc =
      jsonDecode(File(kCalendarWeekStartVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final orders = (doc['weekdayOrder']! as List).cast<Map<String, Object?>>();
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('the vector table covers every weekday a month can start on', () {
    // One month per start weekday, each under three week starts — the
    // arithmetic is a modulo, and a modulo is only pinned by the cases that
    // wrap around.
    final startWeekdays = {
      for (final c in cases)
        DateTime(c['year']! as int, c['month']! as int).weekday,
    };

    expect(startWeekdays, {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    });
    expect(
      {for (final c in cases) c['firstDayOfWeek']},
      {DateTime.sunday, DateTime.monday, DateTime.saturday},
    );
  });

  test('the default week starts on Sunday', () {
    expect(CoreCalendarContract.defaultFirstDayOfWeek, DateTime.sunday);

    // A grid that states no week start is the Sunday-first grid of the table.
    final sundayCases = cases
        .where((c) => c['firstDayOfWeek'] == DateTime.sunday)
        .toList();
    expect(sundayCases, isNotEmpty);
    for (final c in sundayCases) {
      final byDefault = CoreCalendarGridData(
        month: c['month']! as int,
        year: c['year']! as int,
      );

      expect(byDefault.firstDayOfWeek, DateTime.sunday, reason: '${c['name']}');
      expect(
        byDefault.items.map((i) => i.date.day),
        (c['dayNumbers']! as List).cast<int>(),
        reason: '${c['name']}',
      );
      expect(byDefault.items.first.date, _iso(c['firstCell']! as String));
    }
    expect(
      CoreCalendarGridData(month: 6, year: 2026).items.first.date,
      DateTime(2026, 5, 31),
    );
  });

  group('CoreCalendarGridData.weekdayOrder', () {
    for (final entry in orders) {
      final firstDay = entry['firstDayOfWeek']! as int;
      test('a week starting on weekday $firstDay', () {
        expect(
          CoreCalendarGridData.weekdayOrder(firstDay),
          (entry['order']! as List).cast<int>(),
        );
      });
    }

    test('every start yields each weekday exactly once', () {
      for (
        var firstDay = DateTime.monday;
        firstDay <= DateTime.sunday;
        firstDay++
      ) {
        final order = CoreCalendarGridData.weekdayOrder(firstDay);

        expect(order.first, firstDay);
        expect(order.toSet(), hasLength(CoreCalendarGridData.daysPerWeek));
        expect(
          order.every((d) => d >= DateTime.monday && d <= DateTime.sunday),
          isTrue,
        );
      }
    });

    test('rejects a weekday outside Monday..Sunday', () {
      expect(
        () => CoreCalendarGridData.weekdayOrder(0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CoreCalendarGridData.weekdayOrder(8),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('CoreCalendarGridData against the shared vectors', () {
    for (final c in cases) {
      test(c['name']! as String, () {
        final month = c['month']! as int;
        final year = c['year']! as int;
        final grid = CoreCalendarGridData(
          month: month,
          year: year,
          firstDayOfWeek: c['firstDayOfWeek']! as int,
        );
        final dayNumbers = (c['dayNumbers']! as List).cast<int>();
        final leading = c['leading']! as int;

        expect(grid.items.map((i) => i.date.day), dayNumbers);
        expect(grid.items.length % CoreCalendarGridData.daysPerWeek, 0);
        expect(grid.items.first.date, _iso(c['firstCell']! as String));
        expect(grid.items.last.date, _iso(c['lastCell']! as String));

        // The previous month opens the grid, the next one closes it, and
        // the month itself sits between them.
        final inMonth = grid.items.where((i) => !i.fromAnotherMonth).toList();
        expect(inMonth, hasLength(c['daysInMonth']! as int));
        expect(
          grid.items.take(leading).every((i) => i.fromAnotherMonth),
          isTrue,
        );
        expect(grid.items[leading].fromAnotherMonth, isFalse);
        expect(grid.items[leading].date, DateTime(year, month));
        expect(
          grid.items.every(
            (i) => i.fromAnotherMonth == (i.date.month != month),
          ),
          isTrue,
        );
      });

      test('${c['name']} — rows and columns', () {
        final grid = CoreCalendarGridData(
          month: c['month']! as int,
          year: c['year']! as int,
          firstDayOfWeek: c['firstDayOfWeek']! as int,
        );

        // `indexInRow` is the column counted from the first day of the
        // week, so the first cell is always column 0.
        for (var i = 0; i < grid.items.length; i++) {
          expect(
            grid.items[i].indexInRow,
            i % CoreCalendarGridData.daysPerWeek,
          );
          expect(grid.items[i].rowIndex, i ~/ CoreCalendarGridData.daysPerWeek);
        }
        // The 1st falls in the column `leading` counts.
        expect(
          grid.items.firstWhere((i) => !i.fromAnotherMonth).indexInRow,
          c['leading']! as int,
        );
      });

      test('${c['name']} — every cell is a local midnight', () {
        // Neighbouring-month cells are reached by calendar arithmetic, not
        // by adding 24-hour spans: across a daylight-saving change a span
        // lands on 23:00 of the previous day, which prints the wrong day
        // number and, when tapped, selects the wrong date.
        //
        // The failure exists only where the machine's zone observes daylight
        // saving, so this test can only bite there: run the file with
        // `TZ=Europe/Berlin` to watch the 24-hour-span arithmetic fail it.
        final grid = CoreCalendarGridData(
          month: c['month']! as int,
          year: c['year']! as int,
          firstDayOfWeek: c['firstDayOfWeek']! as int,
        );

        for (final item in grid.items) {
          expect(
            item.date,
            DateTime(item.date.year, item.date.month, item.date.day),
            reason: '${item.date} is not a local midnight',
          );
        }
      });
    }
  });

  group('CoreCalendarGridData value semantics', () {
    test('grids that start their week on different days are not equal', () {
      final sunday = CoreCalendarGridData(month: 6, year: 2026);
      final monday = CoreCalendarGridData(
        month: 6,
        year: 2026,
        firstDayOfWeek: DateTime.monday,
      );

      // Same month, different cells: a grid that compared equal here would
      // let a rebuild keyed on equality keep drawing the old week.
      expect(sunday, isNot(monday));
      expect(sunday.hashCode, isNot(monday.hashCode));
    });

    test('the same month and week start are equal', () {
      expect(
        CoreCalendarGridData(
          month: 2,
          year: 2024,
          firstDayOfWeek: DateTime.saturday,
        ),
        CoreCalendarGridData(
          month: 2,
          year: 2024,
          firstDayOfWeek: DateTime.saturday,
        ),
      );
    });
  });

  group('CoreCalendarGridData rejects an impossible week start', () {
    for (final bad in [0, 8, -1]) {
      test('firstDayOfWeek: $bad', () {
        expect(
          () => CoreCalendarGridData(month: 1, year: 2026, firstDayOfWeek: bad),
          throwsA(isA<AssertionError>()),
        );
      });
    }
  });
}
