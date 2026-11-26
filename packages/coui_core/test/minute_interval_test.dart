// CoreMinuteInterval is the arithmetic behind TimePicker.minuteInterval: where
// a typed minute lands (snap) and where an arrow key steps (up / down). The
// Flutter and Web pickers both ask it instead of keeping their own copy, and
// their own tests read the same vector table this file pins to the Core
// definition — so a change to a snapping or stepping rule fails everywhere.
//
// The table was derived by enumerating the multiples of each interval, not
// with the closed-form arithmetic under test: a table and an implementation
// built from the same formula could only ever agree.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter and Web time picker tests.
const String kMinuteIntervalVectorsPath =
    'test/fixtures/minute_interval_vectors.json';

Map<int, List<int>> _table(Map<String, Object?> doc, String key) => {
  for (final entry in (doc[key]! as Map<String, Object?>).entries)
    int.parse(entry.key): (entry.value! as List).cast<int>(),
};

void main() {
  final doc =
      jsonDecode(File(kMinuteIntervalVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final valid = (doc['validIntervals']! as List).cast<int>();
  final invalid = (doc['invalidIntervals']! as List).cast<int>();
  final snap = _table(doc, 'snap');
  final up = _table(doc, 'up');
  final down = _table(doc, 'down');

  test('the default interval is one minute', () {
    expect(CoreTimePickerContract.defaultMinuteInterval, 1);
    expect(
      CoreMinuteInterval.isValid(CoreTimePickerContract.defaultMinuteInterval),
      isTrue,
    );
  });

  group('which intervals a minute segment can step by', () {
    test('the table lists exactly the divisors of an hour', () {
      expect(valid, [
        for (var i = 1; i <= Duration.minutesPerHour; i++)
          if (Duration.minutesPerHour % i == 0) i,
      ]);
      expect(CoreMinuteInterval.validIntervals, valid);
    });

    for (final interval in valid) {
      test('$interval is accepted', () {
        expect(CoreMinuteInterval.isValid(interval), isTrue);
      });
    }

    for (final interval in invalid) {
      test('$interval is rejected', () {
        expect(CoreMinuteInterval.isValid(interval), isFalse);
      });
    }
  });

  group('snap against the shared vectors', () {
    for (final interval in valid) {
      test('every minute at a $interval-minute interval', () {
        for (var minute = 0; minute < Duration.minutesPerHour; minute++) {
          expect(
            CoreMinuteInterval.snap(minute, interval: interval),
            snap[interval]![minute],
            reason: 'minute $minute at interval $interval',
          );
        }
      });
    }

    test('one minute leaves every minute where it is', () {
      for (var minute = 0; minute < Duration.minutesPerHour; minute++) {
        expect(CoreMinuteInterval.snap(minute, interval: 1), minute);
      }
    });

    test('a tie goes to the later multiple (round half up)', () {
      // :07.5 would be the midpoint at 15, but minutes are whole — the tie
      // exists at an even interval: :02 sits between :00 and :04.
      expect(CoreMinuteInterval.snap(2, interval: 4), 4);
      expect(CoreMinuteInterval.snap(6, interval: 12), 12);
      expect(CoreMinuteInterval.snap(15, interval: 30), 30);
    });

    test('the top of the hour wraps to :00 and carries nothing', () {
      // The result is a minute in 0..59 by construction — there is no hour
      // in this arithmetic to carry into.
      expect(CoreMinuteInterval.snap(53, interval: 15), 0);
      expect(CoreMinuteInterval.snap(58, interval: 4), 0);
      expect(CoreMinuteInterval.snap(59, interval: 60), 0);
      for (final interval in valid) {
        for (var minute = 0; minute < Duration.minutesPerHour; minute++) {
          expect(
            CoreMinuteInterval.snap(minute, interval: interval),
            inInclusiveRange(0, IsoTime.maxMinute),
          );
        }
      }
    });

    test('snapping is idempotent', () {
      for (final interval in valid) {
        for (var minute = 0; minute < Duration.minutesPerHour; minute++) {
          final once = CoreMinuteInterval.snap(minute, interval: interval);

          expect(CoreMinuteInterval.snap(once, interval: interval), once);
        }
      }
    });

    test('a minute past :59 is clamped before it is snapped', () {
      // The segment holds two digits, so :75 and :99 can be typed; they have
      // always meant "the last minute".
      for (final interval in valid) {
        final last = CoreMinuteInterval.snap(
          IsoTime.maxMinute,
          interval: interval,
        );
        for (final typed in [60, 61, 75, 99]) {
          expect(
            CoreMinuteInterval.snap(typed, interval: interval),
            last,
            reason: ':$typed at interval $interval',
          );
        }
        expect(
          CoreMinuteInterval.snap(-3, interval: interval),
          CoreMinuteInterval.snap(0, interval: interval),
        );
      }
    });
  });

  group('stepUp against the shared vectors', () {
    for (final interval in valid) {
      test('every minute at a $interval-minute interval', () {
        for (var minute = 0; minute < Duration.minutesPerHour; minute++) {
          expect(
            CoreMinuteInterval.stepUp(minute, interval: interval),
            up[interval]![minute],
            reason: 'minute $minute at interval $interval',
          );
        }
      });
    }

    test('goes to the next multiple, from a multiple or from between', () {
      expect(CoreMinuteInterval.stepUp(0, interval: 15), 15);
      expect(CoreMinuteInterval.stepUp(14, interval: 15), 15);
      expect(CoreMinuteInterval.stepUp(15, interval: 15), 30);
    });

    test('wraps past the last multiple to :00 without carrying', () {
      expect(CoreMinuteInterval.stepUp(45, interval: 15), 0);
      expect(CoreMinuteInterval.stepUp(59, interval: 1), 0);
      expect(CoreMinuteInterval.stepUp(30, interval: 30), 0);
    });
  });

  group('stepDown against the shared vectors', () {
    for (final interval in valid) {
      test('every minute at a $interval-minute interval', () {
        for (var minute = 0; minute < Duration.minutesPerHour; minute++) {
          expect(
            CoreMinuteInterval.stepDown(minute, interval: interval),
            down[interval]![minute],
            reason: 'minute $minute at interval $interval',
          );
        }
      });
    }

    test('goes to the previous multiple, from a multiple or from between', () {
      expect(CoreMinuteInterval.stepDown(30, interval: 15), 15);
      expect(CoreMinuteInterval.stepDown(16, interval: 15), 15);
      expect(CoreMinuteInterval.stepDown(1, interval: 15), 0);
    });

    test('wraps below :00 to the last multiple without borrowing', () {
      expect(CoreMinuteInterval.stepDown(0, interval: 15), 45);
      expect(CoreMinuteInterval.stepDown(0, interval: 1), 59);
      expect(CoreMinuteInterval.stepDown(0, interval: 60), 0);
    });
  });

  group('stepping and snapping agree', () {
    test('a step from a multiple lands on a multiple', () {
      for (final interval in valid) {
        for (var minute = 0; minute < Duration.minutesPerHour; minute++) {
          expect(
            CoreMinuteInterval.stepUp(minute, interval: interval) % interval,
            0,
          );
          expect(
            CoreMinuteInterval.stepDown(minute, interval: interval) % interval,
            0,
          );
        }
      }
    });

    test('up then down from a multiple comes back (away from the wrap)', () {
      for (final interval in valid.where((i) => i < 30)) {
        final start = interval; // a multiple, nowhere near either end
        final up = CoreMinuteInterval.stepUp(start, interval: interval);

        expect(CoreMinuteInterval.stepDown(up, interval: interval), start);
      }
    });
  });

  group('an interval that does not divide an hour is rejected', () {
    for (final interval in invalid) {
      test('snap with $interval', () {
        expect(
          () => CoreMinuteInterval.snap(10, interval: interval),
          throwsA(isA<AssertionError>()),
        );
      });
      test('stepUp with $interval', () {
        expect(
          () => CoreMinuteInterval.stepUp(10, interval: interval),
          throwsA(isA<AssertionError>()),
        );
      });
      test('stepDown with $interval', () {
        expect(
          () => CoreMinuteInterval.stepDown(10, interval: interval),
          throwsA(isA<AssertionError>()),
        );
      });
    }
  });
}
