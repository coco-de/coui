// A calendar's notion of now comes from the clock, so a test or a capture
// harness that fixes the clock with `withClock` fixes the month the calendar
// opens on and the day it marks as today.

import 'package:clock/clock.dart';
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  // A date far from any wall clock this test runs on: read from
  // `DateTime.now()`, every expectation below would see another month.
  final fixed = DateTime(2024, 3, 15);

  group('CoreCalendarView reads the clock', () {
    test('currentTime is the clock', () {
      withClock(Clock.fixed(fixed), () {
        expect(CoreCalendarView.currentTime(), fixed);
      });
    });

    test('now opens on the month of the clock', () {
      withClock(Clock.fixed(fixed), () {
        expect(CoreCalendarView.now(), const CoreCalendarView(2024, 3));
      });
    });

    test('an empty multi value views the month of the clock', () {
      withClock(Clock.fixed(fixed), () {
        final value = CoreCalendarValue.multi([]);
        expect((value.viewYear, value.viewMonth), (2024, 3));
      });
    });
  });
}
