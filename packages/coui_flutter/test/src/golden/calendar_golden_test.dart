import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

// A fixed month in the past, so "today" never lands in the frame and the
// image does not depend on the day the test runs.
const _kYear = 2024;
const _kMonth = 3;
const _kView = CoreCalendarView(_kYear, _kMonth);

/// One dot on the 5th, two on the 10th, …, six on the 30th — the cap is
/// what the 15th onwards shows.
CoreCalendarMarker? _markerFor(DateTime date) =>
    date.month == _kMonth && date.day % 5 == 0
    ? CoreCalendarMarker(count: date.day ~/ 5)
    : null;

void main() {
  group('Calendar Golden', () {
    goldenTest(
      'date markers',
      fileName: 'calendar_markers',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 720),
        children: [
          GoldenTestScenario(
            name: 'single — marked, the 10th selected',
            child: buildGoldenTestApp(
              Calendar(
                initialView: _kView,
                value: CoreCalendarValue.single(DateTime(_kYear, _kMonth, 10)),
                markerBuilder: _markerFor,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'range — check-in 5th, check-out 15th',
            child: buildGoldenTestApp(
              Calendar.range(
                initialView: _kView,
                value: CoreCalendarValue.range(
                  DateTime(_kYear, _kMonth, 5),
                  DateTime(_kYear, _kMonth, 15),
                ),
                markerBuilder: _markerFor,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'style override — cap 4, error fill',
            child: buildGoldenTestApp(
              const Calendar(
                initialView: _kView,
                markerBuilder: _markerFor,
                calendarStyle: CoreCalendarStyle(
                  markerMaxCount: 4,
                  markerColor: CoreColor.token(CoreColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
