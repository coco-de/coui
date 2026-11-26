// TimePicker.minuteInterval — the Web half. The minute segment works in steps
// of an interval: a minute typed into it snaps to the nearest step, and the
// arrow keys move it a step. The arithmetic is `CoreMinuteInterval`'s and is
// pinned to a vector table the Core and Flutter tests read too; what these
// tests check is that the Web picker asks it at the places a minute leaves
// the segment — losing focus, and saving.
//
// The live `keydown` / `input` dispatch is not driven here: `dart test` runs
// this suite on the VM, where `universal_web`'s `KeyboardEvent.key` throws
// and an `<input>` event target cannot be synthesised (`slider_test.dart` and
// `clickable_key_press_test.dart` document the same limitation). The segment
// starts from the picker's `value`, so a value off the grid stands in for a
// typed one: the blur and save paths that snap it are the ones typing would
// reach.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The vector table shared with the Core minute-interval test and the
/// Flutter time picker test.
const _kMinuteIntervalVectorsPath =
    '../coui_core/test/fixtures/minute_interval_vectors.json';

Finder _segmentInput(String label) => find.byComponentPredicate(
  (component) =>
      component is DomComponent &&
      component.tag == 'input' &&
      component.attributes?['aria-label'] == label,
  description: '$label segment input',
);

String? _valueOf(Finder input) =>
    (input.evaluate().single.component as DomComponent).attributes?['value'];

Finder _popoverTrigger() => find.byComponentPredicate(
  (component) =>
      component is DomComponent &&
      (component.attributes?.containsKey('aria-haspopup') ?? false),
  description: 'popover trigger',
);

Future<void> _open(
  ComponentTester tester, {
  required String value,
  int minuteInterval = 1,
  bool showSeconds = false,
  String? min,
  String? max,
  CoreValueChanged<String>? onChanged,
}) async {
  pumpWithTheme(
    tester,
    TimePicker(
      value: value,
      use24HourFormat: true,
      showSeconds: showSeconds,
      minuteInterval: minuteInterval,
      min: min,
      max: max,
      onChanged: onChanged,
    ),
  );
  await tester.pump();
  await tester.click(_popoverTrigger());
  await tester.pump();
}

Future<void> _blur(ComponentTester tester, String label) async {
  tester.dispatchEvent(_segmentInput(label), 'blur');
  await tester.pump();
}

Future<void> _save(ComponentTester tester) async {
  await tester.click(
    find
        .ancestor(
          of: find.text(DefaultCouiLocalizations.instance.buttonSave),
          matching: find.tag('button'),
        )
        .first,
  );
}

void main() {
  final vectors =
      jsonDecode(File(_kMinuteIntervalVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  List<int> table(String key, int interval) =>
      ((vectors[key]! as Map<String, Object?>)['$interval']! as List)
          .cast<int>();

  group('TimePicker minuteInterval', () {
    test('states no interval by default — one minute', () {
      expect(const TimePicker().minuteInterval, 1);
      expect(
        const TimePicker().minuteInterval,
        CoreTimePickerContract.defaultMinuteInterval,
      );
    });

    test('an interval that does not divide an hour is rejected', () {
      for (final interval in [0, -5, 7, 8, 25, 45, 61]) {
        expect(
          () => TimePicker(minuteInterval: interval),
          throwsA(isA<AssertionError>()),
          reason: 'minuteInterval: $interval',
        );
      }
      for (final interval in CoreMinuteInterval.validIntervals) {
        expect(TimePicker(minuteInterval: interval), isA<TimePicker>());
      }
    });

    test('copyWith carries and replaces the interval', () {
      const picker = TimePicker(minuteInterval: 15);

      expect(picker.copyWith().minuteInterval, 15);
      expect(picker.copyWith(minuteInterval: 5).minuteInterval, 5);
    });

    group('a minute off the grid snaps when the segment loses focus', () {
      testComponents('rounds to the nearest step', (tester) async {
        await _open(tester, value: '10:07', minuteInterval: 15);
        expect(_valueOf(_segmentInput('Minute')), '07');

        await _blur(tester, 'Minute');

        expect(_valueOf(_segmentInput('Minute')), '00');
      });

      testComponents('rounds up from the midpoint', (tester) async {
        await _open(tester, value: '10:08', minuteInterval: 15);

        await _blur(tester, 'Minute');

        expect(_valueOf(_segmentInput('Minute')), '15');
      });

      testComponents('the top of the hour wraps to :00 of the same hour', (
        tester,
      ) async {
        await _open(tester, value: '10:53', minuteInterval: 15);

        await _blur(tester, 'Minute');

        expect(_valueOf(_segmentInput('Minute')), '00');
        expect(_valueOf(_segmentInput('Hour')), '10');
      });

      testComponents('leaves a minute that is already on a step alone', (
        tester,
      ) async {
        await _open(tester, value: '10:45', minuteInterval: 15);

        await _blur(tester, 'Minute');

        expect(_valueOf(_segmentInput('Minute')), '45');
      });

      testComponents('the default interval leaves every minute as it is', (
        tester,
      ) async {
        await _open(tester, value: '10:07');

        await _blur(tester, 'Minute');

        expect(_valueOf(_segmentInput('Minute')), '07');
      });

      testComponents('only the minute segment snaps — hour and second do not', (
        tester,
      ) async {
        await _open(
          tester,
          value: '10:07:33',
          minuteInterval: 15,
          showSeconds: true,
        );

        await _blur(tester, 'Hour');
        await _blur(tester, 'Second');

        expect(_valueOf(_segmentInput('Hour')), '10');
        expect(_valueOf(_segmentInput('Second')), '33');
        expect(
          _valueOf(_segmentInput('Minute')),
          '07',
          reason: 'the minute was not blurred, so it was not touched',
        );
      });
    });

    group('save reports the snapped minute', () {
      testComponents('without the segment ever having lost focus', (
        tester,
      ) async {
        final saved = <String>[];
        await _open(
          tester,
          value: '10:37',
          minuteInterval: 15,
          onChanged: saved.add,
        );

        await _save(tester);

        expect(saved, ['10:30']);
      });

      testComponents('the top of the hour wraps without carrying', (
        tester,
      ) async {
        final saved = <String>[];
        await _open(
          tester,
          value: '10:53',
          minuteInterval: 15,
          onChanged: saved.add,
        );

        await _save(tester);

        expect(saved, ['10:00']);
      });

      testComponents('matches the shared vectors', (tester) async {
        for (final interval in [2, 4, 5, 15, 20, 30]) {
          for (final minute in [0, 1, 2, 7, 8, 22, 23, 38, 53, 58, 59]) {
            final saved = <String>[];
            await _open(
              tester,
              value: '10:${minute.toString().padLeft(2, '0')}',
              minuteInterval: interval,
              onChanged: saved.add,
            );

            await _save(tester);

            final expected = table(
              'snap',
              interval,
            )[minute].toString().padLeft(2, '0');
            expect(saved, ['10:$expected'], reason: ':$minute at $interval');
          }
        }
      });

      testComponents('hour and second pass through unchanged', (tester) async {
        final saved = <String>[];
        await _open(
          tester,
          value: '10:07:33',
          minuteInterval: 15,
          showSeconds: true,
          onChanged: saved.add,
        );

        await _save(tester);

        expect(saved, ['10:00:33']);
      });

      testComponents('the default interval saves the minute as it is', (
        tester,
      ) async {
        final saved = <String>[];
        await _open(tester, value: '10:07', onChanged: saved.add);

        await _save(tester);

        expect(saved, ['10:07']);
      });
    });

    // The interval is a step, not a bound. `min` / `max` are declarations the
    // picker does not enforce (documented), and an interval must not start
    // enforcing them by accident.
    testComponents('min and max stay unenforced alongside an interval', (
      tester,
    ) async {
      final saved = <String>[];
      await _open(
        tester,
        value: '22:37',
        minuteInterval: 15,
        min: '09:00',
        max: '18:00',
        onChanged: saved.add,
      );

      await _save(tester);

      expect(saved, ['22:30']);
    });
  });
}
