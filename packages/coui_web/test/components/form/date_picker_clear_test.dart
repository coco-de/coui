import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The clickable cell for day-of-month [day] in the rendered grid.
Finder _dayCell(String day) =>
    find.ancestor(of: find.text(day), matching: find.tag('button')).first;

void main() {
  group('Clearing a date selection', () {
    // Tapping the selected day deselects it, and the calendar reports
    // that as a null value. `DatePicker` used to drop the report on the
    // floor — its `onChanged` took a non-nullable payload, so both emit
    // sites guarded on non-null — which left a host's copy of the value
    // permanently ahead of the picker's with no signal that the two had
    // diverged. Flutter has always reported it. This pins the source of
    // that report; the picker now forwards it unguarded.
    testComponents('emits null when the selected day is tapped', (
      tester,
    ) async {
      final calls = <CoreCalendarValue?>[];
      var called = false;
      pumpWithTheme(
        tester,
        Calendar(
          value: CoreCalendarValue.single(DateTime(2024, 3, 15)),
          initialView: const CoreCalendarView(2024, 3),
          onChanged: (next) {
            called = true;
            calls.add(next);
          },
        ),
      );

      await tester.click(_dayCell('15'));

      expect(called, isTrue);
      expect(calls, equals(<CoreCalendarValue?>[null]));
    });

    // The picker's own half: its callback has to be able to carry the
    // clear at all. While the payload was non-nullable both emit sites
    // had to guard on non-null, so the report had nowhere to go — this
    // line does not compile against the narrower type.
    test('DatePicker.onChanged can carry a cleared selection', () {
      String? seen = 'unset';
      final picker = DatePicker(onChanged: (next) => seen = next);

      picker.onChanged!(null);

      expect(seen, isNull);
    });
  });
}
