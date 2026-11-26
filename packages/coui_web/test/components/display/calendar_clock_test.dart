// The Web calendar reads today from `CoreCalendarView.currentTime`, the clock
// a test or a capture harness can fix with `withClock` — the same seam the
// Flutter calendar reads.

import 'package:clock/clock.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The `Button` that draws the date cell labelled [day].
Button _dayButton(String day) =>
    find
            .ancestor(of: find.text(day), matching: find.byType(Button))
            .evaluate()
            .first
            .component
        as Button;

void main() {
  testComponents('a fixed clock moves the opening month and the today mark', (
    tester,
  ) async {
    // A month far from the wall clock: read from `DateTime.now()`, the
    // calendar would open on another month and mark another day.
    withClock(
      Clock.fixed(DateTime(2024, 3, 15)),
      () => pumpWithTheme(tester, const Calendar()),
    );

    expect(find.text('March 2024'), findsOneComponent);
    expect(
      _dayButton('15').buttonStyle?.borderColor,
      CoreCalendarStyle.defaultTodayBorderColor,
    );
    expect(
      _dayButton('16').buttonStyle?.borderColor,
      isNot(CoreCalendarStyle.defaultTodayBorderColor),
    );
  });
}
