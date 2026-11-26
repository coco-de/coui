import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kTestYear = 2024;
const _kTestMonth = 3;
const _kTestDay = 15;
const _kTestEndDay = 20;
const _kWeekdayColumnCount = 7;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: material.Scaffold(
      body: Theme(data: const ThemeData(), child: child),
    ),
  );
}

/// Every descendant of [node] (inclusive) carrying [role].
List<SemanticsNode> _collectByRole(SemanticsNode node, SemanticsRole role) {
  final matches = <SemanticsNode>[
    if (node.role == role) node,
  ];
  node.visitChildren((child) {
    matches.addAll(_collectByRole(child, role));
    return true;
  });
  return matches;
}

/// The vector table shared with the Core grid test and the Web calendar
/// test.
const _kWeekStartVectorsPath =
    '../coui_core/test/fixtures/calendar_week_start_vectors.json';

Map<String, Object?> _readWeekStartVectors() =>
    jsonDecode(File(_kWeekStartVectorsPath).readAsStringSync())
        as Map<String, Object?>;

/// Every `Text` the calendar draws, in tree order — the month heading, the
/// weekday header left to right, then the day numbers row by row.
List<Text> _calendarTexts(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(Calendar), matching: find.byType(Text)),
    )
    .toList();

final _kDayNumber = RegExp(r'^\d{1,2}$');

/// The weekday header, left to right, as the labels the active locale draws.
List<String> _weekdayHeader(WidgetTester tester) {
  final labels = {
    for (var d = DateTime.monday; d <= DateTime.sunday; d++)
      DefaultCoUILocalizations.instance.getAbbreviatedWeekday(d),
  };

  return [
    for (final text in _calendarTexts(tester))
      if (labels.contains(text.data)) text.data!,
  ];
}

/// The day number in every date cell, row by row.
List<int> _dayNumbers(WidgetTester tester) => [
  for (final text in _calendarTexts(tester))
    if (_kDayNumber.hasMatch(text.data ?? '')) int.parse(text.data!),
];

List<String> _expectedHeader(Iterable<int> order) => [
  for (final weekday in order)
    DefaultCoUILocalizations.instance.getAbbreviatedWeekday(weekday),
];

void main() {
  testWidgets('navigation has names in day, month and year views', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _buildApp(const Calendar(initialView: CoreCalendarView(2024, 3))),
      );
      for (var view = 0; view < 3; view++) {
        expect(find.bySemanticsLabel('Previous period'), findsOneWidget);
        expect(find.bySemanticsLabel('Next period'), findsOneWidget);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Next period'))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        if (view < 2) {
          final title = find.textContaining('2024');
          await tester.tap(title.first);
          await tester.pumpAndSettle();
        }
      }
    } finally {
      semantics.dispose();
    }
  });

  group('CoreCalendarView', () {
    test('stores year and month', () {
      const view = CoreCalendarView(_kTestYear, _kTestMonth);

      expect(view.year, equals(_kTestYear));
      expect(view.month, equals(_kTestMonth));
    });

    test('fromDateTime derives year and month', () {
      final view = CoreCalendarView.fromDateTime(
        DateTime(_kTestYear, _kTestMonth, _kTestDay),
      );

      expect(view.year, equals(_kTestYear));
      expect(view.month, equals(_kTestMonth));
    });
  });

  group('CoreCalendarValue', () {
    test('single stores the date', () {
      final value = CoreCalendarValue.single(
        DateTime(_kTestYear, _kTestMonth, _kTestDay),
      );

      expect(value, isA<CoreSingleCalendarValue>());
    });

    test('range stores start and end', () {
      final value = CoreCalendarValue.range(
        DateTime(_kTestYear, _kTestMonth, _kTestDay),
        DateTime(_kTestYear, _kTestMonth, _kTestEndDay),
      );

      expect(value, isA<CoreRangeCalendarValue>());
    });

    test('multi stores a list of dates', () {
      final value = CoreCalendarValue.multi([
        DateTime(_kTestYear, _kTestMonth, _kTestDay),
        DateTime(_kTestYear, _kTestMonth, _kTestEndDay),
      ]);

      expect(value, isA<CoreMultiCalendarValue>());
    });
  });

  group('Calendar widget', () {
    testWidgets('renders with an initial view', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Calendar(
            initialView: CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Calendar), findsOneWidget);
    });

    testWidgets(
      'date grid exposes a table > row > columnheader/cell semantics tree',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _buildApp(
            const Calendar(
              initialView: CoreCalendarView(_kTestYear, _kTestMonth),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final calendarNode = tester.getSemantics(find.byType(Calendar));

        final tableNodes = _collectByRole(calendarNode, .table);
        expect(tableNodes, hasLength(1));

        // One weekday-header row plus the visible weeks of the month.
        final rowNodes = _collectByRole(tableNodes.single, .row);
        expect(rowNodes.length, greaterThan(1));

        final columnHeaderNodes = _collectByRole(
          tableNodes.single,
          .columnHeader,
        );
        expect(columnHeaderNodes, hasLength(_kWeekdayColumnCount));

        final cellNodes = _collectByRole(tableNodes.single, .cell);
        expect(cellNodes, isNotEmpty);

        handle.dispose();
      },
    );

    testWidgets('renders with a single selection value', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            value: CoreCalendarValue.single(
              DateTime(_kTestYear, _kTestMonth, _kTestDay),
            ),
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Calendar), findsOneWidget);
    });

    testWidgets('renders with the none selection mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Calendar(
            selectionMode: CoreCalendarSelectionMode.none,
            initialView: CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Calendar), findsOneWidget);
    });

    testWidgets('renders a range selection', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            selectionMode: CoreCalendarSelectionMode.range,
            value: CoreCalendarValue.range(
              DateTime(_kTestYear, _kTestMonth, _kTestDay),
              DateTime(_kTestYear, _kTestMonth, _kTestEndDay),
            ),
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Calendar), findsOneWidget);
    });

    testWidgets('onChanged callback is wired up', (tester) async {
      CoreCalendarValue? changed;

      await tester.pumpWidget(
        _buildApp(
          Calendar(
            onChanged: (value) {
              changed = value;
            },
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Calendar), findsOneWidget);
      expect(changed, isNull);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = Key('calendar-key');

      await tester.pumpWidget(
        _buildApp(
          const Calendar(
            key: testKey,
            initialView: CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(testKey), findsOneWidget);
    });
  });

  group('Calendar range band', () {
    // The inner range cells sit on the `primaryContainer` band, so their
    // text takes the foreground that pairs with that fill.
    testWidgets('should_paint_inner_range_text_in_the_band_foreground', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Calendar.range(
            value: CoreCalendarValue.range(
              DateTime(_kTestYear, _kTestMonth, 10),
              DateTime(_kTestYear, _kTestMonth, _kTestEndDay),
            ),
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );

      final context = tester.element(find.byType(Calendar));
      final scheme = Theme.of(context).colorScheme;
      final expected = scheme
          .resolve(const CoreColor.token(CoreColors.onPrimaryContainer))
          .toValue();
      final light = scheme
          .resolve(const CoreColor.token(CoreColors.onSecondary))
          .toValue();
      expect(expected, isNot(light));

      // The range shows two months; the first `15` is the inner March cell.
      final label = find
          .byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == '$_kTestDay',
          )
          .first;
      final painted = (tester.widget<RichText>(label).text as TextSpan).style;
      expect(painted?.color, expected);
    });
  });

  group('Calendar firstDayOfWeek', () {
    final doc = _readWeekStartVectors();
    final orders = (doc['weekdayOrder']! as List).cast<Map<String, Object?>>();
    final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

    Future<void> pumpGrid(
      WidgetTester tester, {
      required int year,
      required int month,
      int? firstDayOfWeek,
      ValueChanged<CoreCalendarValue?>? onChanged,
    }) async {
      await tester.pumpWidget(
        _buildApp(
          firstDayOfWeek == null
              ? Calendar(
                  initialView: CoreCalendarView(year, month),
                  onChanged: onChanged,
                )
              : Calendar(
                  initialView: CoreCalendarView(year, month),
                  firstDayOfWeek: firstDayOfWeek,
                  onChanged: onChanged,
                ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a calendar that states no week start begins on Sunday', (
      tester,
    ) async {
      await pumpGrid(tester, year: 2026, month: 6);

      expect(
        tester.widget<Calendar>(find.byType(Calendar)).firstDayOfWeek,
        DateTime.sunday,
      );
      expect(
        _weekdayHeader(tester),
        _expectedHeader(CoreCalendarGridData.weekdayOrder(DateTime.sunday)),
      );
      expect(_dayNumbers(tester).first, 31, reason: 'May 31 opens June 2026');
    });

    for (final entry in orders) {
      final firstDay = entry['firstDayOfWeek']! as int;
      testWidgets('the header of a week starting on weekday $firstDay', (
        tester,
      ) async {
        await pumpGrid(
          tester,
          year: 2026,
          month: 6,
          firstDayOfWeek: firstDay,
        );

        expect(
          _weekdayHeader(tester),
          _expectedHeader((entry['order']! as List).cast<int>()),
        );
      });
    }

    for (final c in cases) {
      final year = c['year']! as int;
      final month = c['month']! as int;
      final firstDay = c['firstDayOfWeek']! as int;
      final dayNumbers = (c['dayNumbers']! as List).cast<int>();

      testWidgets('${c['name']}', (tester) async {
        final changes = <CoreCalendarValue?>[];
        await pumpGrid(
          tester,
          year: year,
          month: month,
          firstDayOfWeek: firstDay,
          onChanged: changes.add,
        );

        expect(_dayNumbers(tester), dayNumbers);

        // The first cell is the date the table says, not just a number
        // that happens to print the same: tapping it reports the date.
        await tester.tap(find.text('${dayNumbers.first}').first);
        await tester.pump();

        final picked = changes.single! as CoreSingleCalendarValue;
        final first = (c['firstCell']! as String).split('-').map(int.parse);
        expect(
          [picked.date.year, picked.date.month, picked.date.day],
          first.toList(),
        );
      });
    }

    testWidgets('every date sits under the weekday that heads its column', (
      tester,
    ) async {
      await pumpGrid(
        tester,
        year: 2026,
        month: 4,
        firstDayOfWeek: DateTime.monday,
      );

      final header = _expectedHeader(
        CoreCalendarGridData.weekdayOrder(DateTime.monday),
      ).toSet();
      final texts = find.descendant(
        of: find.byType(Calendar),
        matching: find.byType(Text),
      );
      final headerCenters = <double>[];
      final dayCenters = <double>[];
      for (var i = 0; i < texts.evaluate().length; i++) {
        final data = tester.widget<Text>(texts.at(i)).data ?? '';
        final dx = tester.getCenter(texts.at(i)).dx;
        if (header.contains(data)) headerCenters.add(dx);
        if (_kDayNumber.hasMatch(data)) dayCenters.add(dx);
      }

      expect(headerCenters, hasLength(7));
      for (var i = 0; i < dayCenters.length; i++) {
        expect(
          dayCenters[i],
          closeTo(headerCenters[i % 7], 0.01),
          reason: 'cell $i is not under its column heading',
        );
      }
    });

    testWidgets('changing the week start re-lays the grid out', (tester) async {
      await pumpGrid(tester, year: 2026, month: 6);
      final before = _dayNumbers(tester);

      await pumpGrid(
        tester,
        year: 2026,
        month: 6,
        firstDayOfWeek: DateTime.monday,
      );

      expect(before.first, 31);
      expect(_dayNumbers(tester).first, 1);
      expect(
        _weekdayHeader(tester).first,
        DefaultCoUILocalizations.instance.getAbbreviatedWeekday(
          DateTime.monday,
        ),
      );
    });

    testWidgets('a range calendar heads both months with the same week', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Calendar.range(
            initialView: CoreCalendarView(_kTestYear, _kTestMonth),
            firstDayOfWeek: DateTime.monday,
          ),
        ),
      );
      await tester.pump();

      final header = _weekdayHeader(tester);
      final monday = DefaultCoUILocalizations.instance.getAbbreviatedWeekday(
        DateTime.monday,
      );
      expect(header, hasLength(14));
      expect(header[0], monday);
      expect(header[7], monday);
    });

    // A range band runs from the edge of one cell to the next, so the cell
    // at the end of a row has nothing to its side to join: a range that ends
    // in the first column (or starts in the last) is drawn as a plain
    // selected day. "First column" is the first day of the week, whatever
    // weekday that is — Monday June 8th 2026 is the first column of a
    // Monday-first week and the second of a Sunday-first one, so the same
    // range draws one band fewer when the week starts on Monday.
    testWidgets('the range band follows the first column, not Sunday', (
      tester,
    ) async {
      Future<int> rangeFills(int firstDay) async {
        await tester.pumpWidget(
          _buildApp(
            Calendar.range(
              initialView: const CoreCalendarView(2026, 6),
              value: CoreCalendarValue.range(
                DateTime(2026, 6, 3),
                DateTime(2026, 6, 8),
              ),
              firstDayOfWeek: firstDay,
            ),
          ),
        );
        await tester.pump();

        final fill = resolveCalendar(
          tester.element(find.byType(Calendar)),
        ).rangeSelectionColor;

        return find
            .descendant(
              of: find.byType(Calendar),
              matching: find.byType(DecoratedBox),
            )
            .evaluate()
            .map((element) => (element.widget as DecoratedBox).decoration)
            .whereType<BoxDecoration>()
            .where((decoration) => decoration.color == fill)
            .length;
      }

      // Four dates between the ends are filled in both layouts; on top of
      // those, the start always draws a band, and the end draws one unless
      // it opens a row.
      const inBetween = 4;
      expect(await rangeFills(DateTime.sunday), inBetween + 1 + 1);
      expect(await rangeFills(DateTime.monday), inBetween + 1);
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

  group('Calendar #5881 rendered labels and range ends', () {
    // The painted span of the first date cell whose number is [day].
    TextStyle? paintedDay(WidgetTester tester, int day) {
      final label = find
          .byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == '$day',
          )
          .first;
      return (tester.widget<RichText>(label).text as TextSpan).style;
    }

    Color resolve(WidgetTester tester, CoreColorToken token) {
      final scheme = Theme.of(
        tester.element(find.byType(Calendar)),
      ).colorScheme;
      return scheme.resolve(CoreColor.token(token)).toValue();
    }

    testWidgets('today paints SemiBold in primary', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildApp(Calendar(initialView: CoreCalendarView(now.year, now.month))),
      );
      // A neighbouring month can draw the same number; today's is the one
      // marked.
      final spans = [
        for (final w in tester.widgetList<RichText>(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == '${now.day}',
          ),
        ))
          (w.text as TextSpan).style,
      ];
      final primary = resolve(tester, CoreColors.primary);
      expect(
        spans.any(
          (s) =>
              s?.fontWeight == FontWeight.w600 &&
              s?.color == primary &&
              s?.fontSize == 13,
        ),
        isTrue,
      );
    });

    testWidgets('a fixed clock moves the opening month and the today mark', (
      tester,
    ) async {
      // A month far from the wall clock: read from `DateTime.now()`, the
      // calendar would open on another month and mark another day.
      await withClock(
        Clock.fixed(DateTime(_kTestYear, _kTestMonth, _kTestDay)),
        () => tester.pumpWidget(_buildApp(const Calendar())),
      );
      final today = paintedDay(tester, _kTestDay);
      expect(today?.fontWeight, FontWeight.w600);
      expect(today?.color, resolve(tester, CoreColors.primary));
      expect(paintedDay(tester, _kTestDay + 1)?.fontWeight, FontWeight.w400);
    });

    testWidgets('a selected date paints Medium in onPrimary', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            value: CoreCalendarValue.single(
              DateTime(_kTestYear, _kTestMonth, _kTestDay),
            ),
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      final painted = paintedDay(tester, _kTestDay);
      expect(painted?.fontWeight, FontWeight.w500);
      expect(painted?.color, resolve(tester, CoreColors.onPrimary));
      expect(painted?.fontSize, 13);
      // A plain date stays Regular.
      expect(paintedDay(tester, _kTestDay + 1)?.fontWeight, FontWeight.w400);
    });

    testWidgets('a selected date that is today keeps the selected label', (
      tester,
    ) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            value: CoreCalendarValue.single(now),
            initialView: CoreCalendarView(now.year, now.month),
          ),
        ),
      );
      final painted = paintedDay(tester, now.day);
      expect(painted?.fontWeight, FontWeight.w500);
      expect(painted?.color, resolve(tester, CoreColors.onPrimary));
    });

    testWidgets('range endpoints paint Medium onPrimary over a half band', (
      tester,
    ) async {
      // March 2024 opens on a Friday with Sunday first: the 12th (Tue) and
      // the 14th (Thu) sit mid-row, so neither folds back to a lone pill.
      await tester.pumpWidget(
        _buildApp(
          Calendar.range(
            value: CoreCalendarValue.range(
              DateTime(_kTestYear, _kTestMonth, 12),
              DateTime(_kTestYear, _kTestMonth, 14),
            ),
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      for (final day in [12, 14]) {
        final painted = paintedDay(tester, day);
        expect(painted?.fontWeight, FontWeight.w500);
        expect(painted?.color, resolve(tester, CoreColors.onPrimary));
      }

      final band = resolve(tester, CoreColors.primaryContainer);
      final cellSize = resolveCalendar(
        tester.element(find.byType(Calendar)),
      ).dayCellSize;
      // Every band fill under the grid; the full-width ones are the inner
      // dates, the half-width ones the endpoint halves.
      final halves = [
        for (final element
            in find
                .byWidgetPredicate(
                  (w) =>
                      w is DecoratedBox &&
                      w.decoration is BoxDecoration &&
                      (w.decoration as BoxDecoration).color == band,
                )
                .evaluate())
          tester.getRect(find.byElementPredicate((e) => e == element)),
      ].where((r) => r.width < cellSize).toList();
      expect(halves, hasLength(2));
      for (final half in halves) {
        expect(half.width, cellSize / 2);
        expect(half.height, cellSize);
      }
      double centreOf(int day) => tester
          .getCenter(
            find
                .byWidgetPredicate(
                  (w) => w is RichText && w.text.toPlainText() == '$day',
                )
                .first,
          )
          .dx;
      // Start band: the inner (right) half, starting at the date's centre.
      // End band: the inner (left) half, ending at the date's centre.
      expect(
        halves.any((r) => (r.left - centreOf(12)).abs() < 0.5),
        isTrue,
      );
      expect(
        halves.any((r) => (r.right - centreOf(14)).abs() < 0.5),
        isTrue,
      );
    });

    testWidgets('the month title paints labelMedium (13 Medium)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Calendar(
            initialView: CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );
      final title = find
          .byWidgetPredicate(
            (w) =>
                w is RichText && w.text.toPlainText().contains('$_kTestYear'),
          )
          .first;
      final painted = (tester.widget<RichText>(title).text as TextSpan).style;
      expect(painted?.fontWeight, FontWeight.w500);
      expect(painted?.fontSize, 13);
    });
  });

  group('resolveCalendar title button label', () {
    // Resolves the calendar inside a real theme and hands back the
    // title Button's label slot — the value the month/year title paints.
    Future<CoreTextStyle?> resolveTitleLabel(
      WidgetTester tester,
      CoreCalendarStyle calendarStyle,
    ) async {
      CoreTextStyle? label;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              label = resolveCalendar(
                context,
                calendarStyle: calendarStyle,
              ).headerButtonStyle.labelStyle;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      return label;
    }

    testWidgets('a cellTextStyle-only override does not reach the title', (
      tester,
    ) async {
      final label = await resolveTitleLabel(
        tester,
        const CoreCalendarStyle(
          cellTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
        ),
      );

      expect(label, CoreCalendarStyle.defaultHeaderTextStyle);
      expect(label?.fontWeight, isNot(CoreFontWeight.bold));
    });

    testWidgets('a headerTextStyle override reaches the title', (
      tester,
    ) async {
      final label = await resolveTitleLabel(
        tester,
        const CoreCalendarStyle(
          headerTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
        ),
      );

      expect(label?.fontWeight, CoreFontWeight.bold);
      expect(label?.token, CoreCalendarStyle.defaultHeaderTextStyle.token);
    });
  });

  group('resolveCalendar today cell', () {
    testWidgets('is a ghost cell marked by an outline, not by a fill', (
      tester,
    ) async {
      CoreButtonStyle? today;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              today = resolveCalendar(context).dateCellTodayStyle;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(today?.backgroundColor, isNull);
      expect(today?.borderColor, CoreCalendarStyle.defaultTodayBorderColor);
      expect(today?.borderWidth, CoreCalendarStyle.defaultTodayBorderWidth);
    });
  });

  group('Calendar markers', () {
    // The dots of every marked cell: each marked cell is the only place the
    // calendar puts a `MergeSemantics`, and inside it the dots are the only
    // thing wrapped in `ExcludeSemantics`.
    Finder dotsIn(Finder markedCell) => find.descendant(
      of: find.descendant(
        of: markedCell,
        matching: find.byType(ExcludeSemantics),
      ),
      matching: find.byType(DecoratedBox),
    );

    Finder markedCellOf(String day) => find.ancestor(
      of: find.text(day),
      matching: find.byType(MergeSemantics),
    );

    Color dotColor(WidgetTester tester, Finder dot) =>
        ((tester.widget<DecoratedBox>(dot).decoration) as BoxDecoration).color!;

    CoreCalendarMarker? markerFor(DateTime date) => switch (date) {
      DateTime(year: _kTestYear, month: _kTestMonth, day: 10) =>
        const CoreCalendarMarker(),
      DateTime(year: _kTestYear, month: _kTestMonth, day: _kTestDay) =>
        const CoreCalendarMarker(
          count: 2,
          semanticsLabel: '2 vaccinations due',
        ),
      DateTime(year: _kTestYear, month: _kTestMonth, day: _kTestEndDay) =>
        const CoreCalendarMarker(count: 7),
      _ => null,
    };

    testWidgets('should_draw_no_marker_when_builder_is_null', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Calendar(
            initialView: CoreCalendarView(_kTestYear, _kTestMonth),
          ),
        ),
      );

      expect(find.byType(MergeSemantics), findsNothing);
    });

    testWidgets('should_draw_one_dot_per_item_up_to_the_cap', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
            markerBuilder: markerFor,
          ),
        ),
      );

      expect(find.byType(MergeSemantics), findsNWidgets(3));
      expect(dotsIn(markedCellOf('10')), findsOneWidget);
      expect(dotsIn(markedCellOf('$_kTestDay')), findsNWidgets(2));
      // Seven items, three dots — the default cap.
      expect(
        dotsIn(markedCellOf('$_kTestEndDay')),
        findsNWidgets(CoreCalendarStyle.defaultMarkerMaxCount),
      );
    });

    testWidgets('should_honour_a_style_override_of_the_cap', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
            markerBuilder: markerFor,
            calendarStyle: const CoreCalendarStyle(markerMaxCount: 5),
          ),
        ),
      );

      expect(dotsIn(markedCellOf('$_kTestEndDay')), findsNWidgets(5));
    });

    testWidgets('should_keep_the_day_cell_size_when_marked', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
            markerBuilder: markerFor,
          ),
        ),
      );

      final marked = tester.getSize(markedCellOf('$_kTestDay'));
      final plain = tester.getSize(
        find.ancestor(of: find.text('11'), matching: find.byType(Button)),
      );
      expect(marked, plain);
    });

    testWidgets('should_read_the_marker_label_with_the_date', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
            markerBuilder: markerFor,
          ),
        ),
      );

      // The caller's label, merged into the date's own node.
      expect(
        tester.getSemantics(markedCellOf('$_kTestDay')).label,
        allOf(contains('$_kTestDay'), contains('2 vaccinations due')),
      );
      // No label of its own → the localized count, the full count and not
      // the number of dots drawn.
      expect(
        tester.getSemantics(markedCellOf('$_kTestEndDay')).label,
        allOf(contains('$_kTestEndDay'), contains('7 items')),
      );
      expect(
        tester.getSemantics(markedCellOf('10')).label,
        contains('1 item'),
      );
      handle.dispose();
    });

    testWidgets('should_still_select_a_marked_date_on_tap', (tester) async {
      CoreCalendarValue? changed;
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
            markerBuilder: markerFor,
            onChanged: (value) => changed = value,
          ),
        ),
      );

      await tester.tap(markedCellOf('$_kTestDay'));
      await tester.pump();

      expect(changed, isA<CoreSingleCalendarValue>());
      expect(
        (changed! as CoreSingleCalendarValue).date,
        DateTime(_kTestYear, _kTestMonth, _kTestDay),
      );
    });

    testWidgets(
      'should_paint_the_selection_fill_dot_colour_across_a_range',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Calendar.range(
              value: CoreCalendarValue.range(
                DateTime(_kTestYear, _kTestMonth, 10),
                DateTime(_kTestYear, _kTestMonth, _kTestEndDay),
              ),
              initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
              markerBuilder: markerFor,
              // Distinct fills — the theme defaults `onPrimary` and
              // `onSecondary` can resolve to the same colour.
              calendarStyle: const CoreCalendarStyle(
                selectedMarkerColor: CoreColor.token(CoreColors.success),
                rangeMarkerColor: CoreColor.token(CoreColors.warning),
              ),
            ),
          ),
        );

        // The range layout shows two months; markers land in the first.
        final start = dotColor(tester, dotsIn(markedCellOf('10')).first);
        final inside = dotColor(
          tester,
          dotsIn(markedCellOf('$_kTestDay')).first,
        );
        final end = dotColor(
          tester,
          dotsIn(markedCellOf('$_kTestEndDay')).first,
        );

        expect(start, end);
        expect(inside, isNot(start));
      },
    );

    testWidgets('should_prefer_the_marker_colour_off_selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Calendar(
            initialView: const CoreCalendarView(_kTestYear, _kTestMonth),
            value: CoreCalendarValue.single(
              DateTime(_kTestYear, _kTestMonth, _kTestDay),
            ),
            markerBuilder: (date) => const CoreCalendarMarker(
              color: CoreColor.token(CoreColors.error),
            ),
          ),
        ),
      );

      final selected = dotColor(
        tester,
        dotsIn(markedCellOf('$_kTestDay')).first,
      );
      final plain = dotColor(tester, dotsIn(markedCellOf('11')).first);
      expect(plain, isNot(selected));
    });
  });

  group('resolveCalendarMarker', () {
    Future<ResolvedCalendarMarker> resolve(
      WidgetTester tester, {
      required CoreCalendarMarker marker,
      required CoreCalendarValueLookup lookup,
      CoreCalendarStyle? calendarStyle,
    }) async {
      late ResolvedCalendarMarker resolved;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveCalendarMarker(
                context,
                marker: marker,
                lookup: lookup,
                calendarStyle: calendarStyle,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return resolved;
    }

    testWidgets('should_cap_the_dot_count', (tester) async {
      final resolved = await resolve(
        tester,
        marker: const CoreCalendarMarker(count: 9),
        lookup: .none,
      );
      expect(resolved.dotCount, CoreCalendarStyle.defaultMarkerMaxCount);
    });

    testWidgets('should_ignore_the_marker_colour_on_a_selection_fill', (
      tester,
    ) async {
      const marker = CoreCalendarMarker(
        color: CoreColor.token(CoreColors.error),
      );
      // Three distinct fills — the theme defaults `onPrimary` and
      // `onSecondary` can resolve to the same colour.
      const style = CoreCalendarStyle(
        selectedMarkerColor: CoreColor.token(CoreColors.success),
        rangeMarkerColor: CoreColor.token(CoreColors.warning),
      );
      Future<Color> fill(CoreCalendarMarker m, CoreCalendarValueLookup l) =>
          resolve(
            tester,
            marker: m,
            lookup: l,
            calendarStyle: style,
          ).then((r) => r.dotColor);

      const plain = CoreCalendarMarker();
      // A selection fill decides the dot colour, not the marker.
      expect(await fill(marker, .selected), await fill(plain, .selected));
      expect(await fill(marker, .start), await fill(plain, .selected));
      expect(await fill(marker, .end), await fill(plain, .selected));
      expect(await fill(marker, .inRange), await fill(plain, .inRange));
      // Off the selection the marker's own colour shows.
      expect(await fill(marker, .none), isNot(await fill(plain, .none)));
      // And the three fills are three different colours.
      expect(await fill(plain, .inRange), isNot(await fill(plain, .selected)));
      expect(await fill(plain, .none), isNot(await fill(plain, .selected)));
    });
  });
}
