// Tests for CoreClockFormat — the clock arithmetic every CoUI locale on both
// platforms formats through.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter and Web locale tests.
const String kClockFormatVectorsPath =
    'test/fixtures/clock_format_vectors.json';

void main() {
  group('CoreClockFormat.isPm', () {
    test('noon is the first hour of PM, midnight the first of AM', () {
      expect(CoreClockFormat.isPm(0), isFalse);
      expect(CoreClockFormat.isPm(11), isFalse);
      expect(CoreClockFormat.isPm(12), isTrue);
      expect(CoreClockFormat.isPm(23), isTrue);
    });
  });

  group('CoreClockFormat.hourOfPeriod', () {
    test('a 12-hour clock never shows 0', () {
      expect(CoreClockFormat.hourOfPeriod(0), 12);
      expect(CoreClockFormat.hourOfPeriod(1), 1);
      expect(CoreClockFormat.hourOfPeriod(11), 11);
      expect(CoreClockFormat.hourOfPeriod(12), 12);
      expect(CoreClockFormat.hourOfPeriod(13), 1);
      expect(CoreClockFormat.hourOfPeriod(23), 11);
    });

    test('covers every hour of the day with 1-12', () {
      for (var hour = 0; hour < Duration.hoursPerDay; hour++) {
        expect(
          CoreClockFormat.hourOfPeriod(hour),
          inInclusiveRange(1, CoreClockFormat.hoursPerPeriod),
          reason: 'hour $hour',
        );
      }
    });
  });

  group('CoreClockFormat.digits against the shared vectors', () {
    final cases = _loadCases();

    test('the vector table is not empty', () {
      expect(cases, isNotEmpty);
    });

    // The locale's words and date are not CoreClockFormat's concern: pick
    // the clock digits out of the expected string. A period word can sit on
    // either side of them and with or without a space (`上午12:05`).
    for (final c in cases) {
      final expected = RegExp(
        r'\d{2}:\d{2}(:\d{2})?',
      ).firstMatch(c['expected']! as String)!.group(0)!;
      test('${c['locale']} ${c['api']} → $expected', () {
        expect(
          CoreClockFormat.digits(
            hour: c['hour']! as int,
            minute: c['minute']! as int,
            second: c['second']! as int,
            showSeconds: c['showSeconds']! as bool,
            use24HourFormat: c['use24HourFormat']! as bool,
          ),
          expected,
        );
      });
    }
  });
}

List<Map<String, Object?>> _loadCases() {
  final doc =
      jsonDecode(File(kClockFormatVectorsPath).readAsStringSync())
          as Map<String, Object?>;

  return (doc['cases']! as List).cast<Map<String, Object?>>();
}
