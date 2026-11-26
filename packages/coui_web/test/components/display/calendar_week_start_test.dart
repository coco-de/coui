// Calendar.firstDayOfWeek — the Web half of the shared week-start vectors.
//
// `coui_core` owns the arithmetic (`CoreCalendarGridData` lays the month out
// for a week that starts on any weekday, `weekdayOrder` is the header that
// goes with it) and pins it to a vector table; the Flutter calendar test and
// this file read the same table, so the two seats cannot disagree about
// where a week starts without a test saying so.
//
// The rendered structure is read from the server-rendered document — the
// weekday header (`role="columnheader"`) and the date cells
// (`role="gridcell"`) in document order. Which *date* a cell holds is read
// by tapping the first one, because a day number alone cannot tell
// "28 March" from "28 April".
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The vector table shared with the Core grid test and the Flutter calendar
/// test.
const _kWeekStartVectorsPath =
    '../coui_core/test/fixtures/calendar_week_start_vectors.json';

final _doc =
    jsonDecode(File(_kWeekStartVectorsPath).readAsStringSync())
        as Map<String, Object?>;

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

/// The day number a date cell prints. A button emits its pseudo-state rules
/// as a `<style>` element in front of its label, so the label is the text at
/// the end of the cell, after that CSS.
int _dayNumber(String cellText) =>
    int.parse(RegExp(r'\d+\s*$').firstMatch(cellText)!.group(0)!.trim());

List<String> _expectedHeader(Iterable<int> order) => [
  for (final weekday in order)
    DefaultCouiLocalizations.instance.getAbbreviatedWeekday(weekday),
];

/// Renders [calendar] and reads its structure back from the server-rendered
/// document: the weekday header (left to right, as the labels the active
/// locale draws) and the day number in every date cell (row by row).
Future<({List<String> header, List<int> dayNumbers})> _structureOf(
  ServerTester tester,
  Component calendar,
) async {
  tester.pumpComponent(_host(calendar));
  final document = (await tester.request('/')).document!;

  return (
    header: [
      for (final cell in document.querySelectorAll('[role="columnheader"]'))
        cell.text.trim(),
    ],
    dayNumbers: [
      for (final cell in document.querySelectorAll('[role="gridcell"]'))
        _dayNumber(cell.text),
    ],
  );
}

Future<({List<String> header, List<int> dayNumbers})> _render(
  ServerTester tester, {
  required int year,
  required int month,
  int? firstDayOfWeek,
}) => _structureOf(
  tester,
  firstDayOfWeek == null
      ? Calendar(id: 'c', initialView: CoreCalendarView(year, month))
      : Calendar(
          id: 'c',
          initialView: CoreCalendarView(year, month),
          firstDayOfWeek: firstDayOfWeek,
        ),
);

void main() {
  final orders = (_doc['weekdayOrder']! as List).cast<Map<String, Object?>>();
  final cases = (_doc['cases']! as List).cast<Map<String, Object?>>();

  group('Calendar firstDayOfWeek', () {
    testServer('a calendar that states no week start begins on Sunday', (
      tester,
    ) async {
      final rendered = await _render(tester, year: 2026, month: 6);

      expect(
        rendered.header,
        _expectedHeader(CoreCalendarGridData.weekdayOrder(DateTime.sunday)),
      );
      expect(
        rendered.dayNumbers.first,
        31,
        reason: 'May 31 opens June 2026',
      );
    });

    for (final entry in orders) {
      final firstDay = entry['firstDayOfWeek']! as int;
      testServer('the header of a week starting on weekday $firstDay', (
        tester,
      ) async {
        final rendered = await _render(
          tester,
          year: 2026,
          month: 6,
          firstDayOfWeek: firstDay,
        );

        expect(
          rendered.header,
          _expectedHeader((entry['order']! as List).cast<int>()),
        );
      });
    }

    for (final c in cases) {
      final year = c['year']! as int;
      final month = c['month']! as int;
      final firstDay = c['firstDayOfWeek']! as int;
      final dayNumbers = (c['dayNumbers']! as List).cast<int>();

      testServer('${c['name']}', (tester) async {
        final rendered = await _render(
          tester,
          year: year,
          month: month,
          firstDayOfWeek: firstDay,
        );

        expect(rendered.dayNumbers, dayNumbers);
        expect(
          rendered.header,
          _expectedHeader(CoreCalendarGridData.weekdayOrder(firstDay)),
        );
      });

      // The first cell is the date the table says, not just a number that
      // happens to print the same: tapping it reports the date.
      testComponents('${c['name']} — the first cell holds ${c['firstCell']}', (
        tester,
      ) async {
        final changes = <CoreCalendarValue?>[];
        pumpWithTheme(
          tester,
          Calendar(
            initialView: CoreCalendarView(year, month),
            firstDayOfWeek: firstDay,
            onChanged: changes.add,
          ),
        );
        await tester.pump();

        await tester.click(
          find
              .ancestor(
                of: find.text('${dayNumbers.first}'),
                matching: find.tag('button'),
              )
              .first,
        );

        final picked = changes.single! as CoreSingleCalendarValue;
        final first = (c['firstCell']! as String).split('-').map(int.parse);
        expect([
          picked.date.year,
          picked.date.month,
          picked.date.day,
        ], first.toList());
      });
    }

    testServer('a range calendar heads both months with the same week', (
      tester,
    ) async {
      final header = (await _structureOf(
        tester,
        const Calendar.range(
          id: 'c',
          initialView: CoreCalendarView(2024, 3),
          firstDayOfWeek: DateTime.monday,
        ),
      )).header;
      final monday = DefaultCouiLocalizations.instance.getAbbreviatedWeekday(
        DateTime.monday,
      );

      expect(header, hasLength(14));
      expect(header[0], monday);
      expect(header[7], monday);
    });

    test('a week start outside Monday..Sunday is rejected', () {
      expect(
        () => Calendar(firstDayOfWeek: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Calendar.single(firstDayOfWeek: 8),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Calendar.range(firstDayOfWeek: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Calendar.multi(firstDayOfWeek: 9),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith carries and replaces the week start', () {
      const calendar = Calendar(firstDayOfWeek: DateTime.monday);

      expect(calendar.copyWith().firstDayOfWeek, DateTime.monday);
      expect(
        calendar.copyWith(firstDayOfWeek: DateTime.saturday).firstDayOfWeek,
        DateTime.saturday,
      );
    });
  });

  group('firstDayOfWeek reaches the calendar the picker opens', () {
    // The pickers own no calendar of their own: each builds a `Calendar` in
    // a popover or a dialog and hands it the props it was given. A week
    // start declared on the picker and not handed on would leave the
    // calendar on Sunday while the field claimed otherwise. The popover and
    // the dialog are separate construction sites, so both are opened.
    Finder popoverTrigger() => find.byComponentPredicate(
      (component) =>
          component is DomComponent &&
          (component.attributes?.containsKey('aria-haspopup') ?? false),
    );

    // Dialog mode has no popover wrapper: the trigger field's own `click`
    // handler (on its `<input>`) opens the dialog.
    Finder dialogTrigger() => find.byComponentPredicate(
      (component) => component is DomComponent && component.tag == 'input',
      description: 'trigger field input',
    );

    int weekStartOf() =>
        (find.byType(Calendar).evaluate().first.component as Calendar)
            .firstDayOfWeek;

    testComponents('DatePicker in a popover', (tester) async {
      pumpWithTheme(
        tester,
        DatePicker(
          firstDayOfWeek: DateTime.saturday,
          mode: CorePromptMode.popover,
          onChanged: (_) {},
        ),
      );
      await tester.pump();
      await tester.click(popoverTrigger());
      await tester.pump();

      expect(weekStartOf(), DateTime.saturday);
    });

    testComponents('DatePicker in a dialog', (tester) async {
      pumpWithTheme(
        tester,
        DatePicker(
          firstDayOfWeek: DateTime.monday,
          mode: CorePromptMode.dialog,
          onChanged: (_) {},
        ),
      );
      await tester.pump();
      await tester.click(dialogTrigger());
      await tester.pump();

      expect(weekStartOf(), DateTime.monday);
    });

    testComponents('DateRangePicker in a popover', (tester) async {
      pumpWithTheme(
        tester,
        DateRangePicker(
          firstDayOfWeek: DateTime.saturday,
          mode: CorePromptMode.popover,
          onChanged: (_) {},
        ),
      );
      await tester.pump();
      await tester.click(popoverTrigger());
      await tester.pump();

      expect(weekStartOf(), DateTime.saturday);
    });

    testComponents('DateRangePicker in a dialog', (tester) async {
      pumpWithTheme(
        tester,
        DateRangePicker(
          firstDayOfWeek: DateTime.monday,
          onChanged: (_) {},
        ),
      );
      await tester.pump();
      await tester.click(dialogTrigger());
      await tester.pump();

      expect(weekStartOf(), DateTime.monday);
    });

    testComponents('a picker that states none opens a Sunday-first calendar', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        DatePicker(mode: CorePromptMode.dialog, onChanged: (_) {}),
      );
      await tester.pump();
      await tester.click(dialogTrigger());
      await tester.pump();

      expect(weekStartOf(), DateTime.sunday);
    });

    test('a week start outside Monday..Sunday is rejected', () {
      expect(
        () => DatePicker(firstDayOfWeek: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => DateRangePicker(firstDayOfWeek: 8),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith carries and replaces the week start', () {
      const picker = DatePicker(firstDayOfWeek: DateTime.monday);

      expect(picker.copyWith().firstDayOfWeek, DateTime.monday);
      expect(
        picker.copyWith(firstDayOfWeek: DateTime.friday).firstDayOfWeek,
        DateTime.friday,
      );
    });
  });
}
