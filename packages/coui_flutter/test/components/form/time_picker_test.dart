import 'dart:convert';
import 'dart:io';
import 'dart:ui' show SemanticsRole;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

// Time test constants.
const _kTestHour = 10;
const _kTestMinute = 30;
const _kTestHour2 = 14;
const _kTestMinute2 = 45;
const _kTestSecond = 0;
const _kTestSecondValue = 15;
const _kTestPmHour = 2;
const _kTestPmResultHour = 14;

/// Frames to pump while waiting for the popover panel to mount — a bound
/// so a panel that never opens fails the assertion instead of hanging.
const _kPopoverMountFrames = 20;

/// The vector table shared with the Core minute-interval test and the Web
/// time picker test.
const _kMinuteIntervalVectorsPath =
    '../coui_core/test/fixtures/minute_interval_vectors.json';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
  localizationsDelegates: const [CoUILocalizationsDelegate.delegate],
);

/// The panel's hour / minute / second inputs — editable fields. The trigger
/// is a read-only `TextField` too, so a bare `byType(TextField)` would
/// count it first.
final Finder _segmentFields = find.byWidgetPredicate(
  (widget) => widget is TextField && !widget.readOnly,
  description: 'an editable TextField',
);

void main() {
  group('TimeOfDay (CoUI)', () {
    group('constructor', () {
      test('creates with hour and minute', () {
        const time = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);

        expect(time.hour, equals(_kTestHour));
        expect(time.minute, equals(_kTestMinute));
        expect(time.second, equals(_kTestSecond));
      });

      test('creates with second', () {
        const time = TimeOfDay(
          hour: _kTestHour,
          minute: _kTestMinute,
          second: _kTestSecondValue,
        );

        expect(time.second, equals(_kTestSecondValue));
      });

      test('creates with am constructor', () {
        const time = TimeOfDay.am(hour: _kTestHour, minute: _kTestMinute);

        expect(time.hour, equals(_kTestHour));
        expect(time.minute, equals(_kTestMinute));
      });

      test('creates with pm constructor adds 12 hours', () {
        const time = TimeOfDay.pm(hour: _kTestPmHour, minute: _kTestMinute);

        expect(time.hour, equals(_kTestPmResultHour));
        expect(time.minute, equals(_kTestMinute));
      });
    });

    group('copyWith', () {
      test('returns same values when no args provided', () {
        const time = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);
        final copied = time.copyWith();

        expect(copied.hour, equals(_kTestHour));
        expect(copied.minute, equals(_kTestMinute));
      });

      test('overrides hour', () {
        const time = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);
        final copied = time.copyWith(hour: () => _kTestHour2);

        expect(copied.hour, equals(_kTestHour2));
        expect(copied.minute, equals(_kTestMinute));
      });

      test('overrides minute', () {
        const time = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);
        final copied = time.copyWith(minute: () => _kTestMinute2);

        expect(copied.minute, equals(_kTestMinute2));
        expect(copied.hour, equals(_kTestHour));
      });
    });

    group('equality', () {
      test('two identical TimeOfDay instances are equal', () {
        const time1 = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);
        const time2 = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);

        expect(time1, equals(time2));
      });

      test('different hour makes instances unequal', () {
        const time1 = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);
        const time2 = TimeOfDay(hour: _kTestHour2, minute: _kTestMinute);

        expect(time1, isNot(equals(time2)));
      });

      test('different minute makes instances unequal', () {
        const time1 = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);
        const time2 = TimeOfDay(hour: _kTestHour, minute: _kTestMinute2);

        expect(time1, isNot(equals(time2)));
      });
    });

    test('toString returns descriptive string', () {
      const time = TimeOfDay(hour: _kTestHour, minute: _kTestMinute);

      expect(time.toString(), contains('TimeOfDay'));
    });
  });

  group('TimePicker widget', () {
    testWidgets('renders with key parameter', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TimePicker(
            key: Key('time_picker'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(const Key('time_picker')), findsOneWidget);
    });

    testWidgets('renders with null value', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TimePicker(),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(TimePicker), findsOneWidget);
    });

    testWidgets('renders with a time value', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TimePicker(value: '09:15'),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(TimePicker), findsOneWidget);
    });

    testWidgets('accepts a placeholder', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TimePicker(
            placeholder: 'Pick a time',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final widget = tester.widget<TimePicker>(find.byType(TimePicker));
      expect(widget.placeholder, equals('Pick a time'));
    });

    testWidgets('renders disabled state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TimePicker(
            enabled: false,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(TimePicker), findsOneWidget);
    });

    testWidgets('renders with 24-hour format', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TimePicker(
            use24HourFormat: true,
            value: '17:45',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(TimePicker), findsOneWidget);
    });

    testWidgets('renders with showSeconds true', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TimePicker(
            showSeconds: true,
            value: '09:15:30',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(TimePicker), findsOneWidget);
    });

    testWidgets('the am/pm choice is one ToggleGroup that keeps its size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: material.Center(
              child: TimePicker(
                value: '10:00',
                use24HourFormat: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open the popover (avoid pumpAndSettle — the popover schedules
      // recurring frame callbacks).
      await tester.tap(find.byType(TimePicker));
      await tester.pump(const Duration(milliseconds: 300));

      // One grouped control holding both labels — not two buttons.
      final group = find.byType(ToggleGroup<bool>);
      expect(group, findsOneWidget);
      expect(
        find.descendant(of: group, matching: find.text('AM')),
        findsWidgets,
      );
      expect(
        find.descendant(of: group, matching: find.text('PM')),
        findsWidgets,
      );
      expect(
        tester.widget<ToggleGroup<bool>>(group).value,
        isFalse,
        reason: '10:00 is before noon',
      );

      final before = tester.getSize(group);

      await tester.tap(find.text('PM').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.widget<ToggleGroup<bool>>(group).value, isTrue);
      expect(tester.getSize(group), before);
    });
  });

  // The minute segment can work in steps of an interval: the arrow keys move
  // it a step, and a minute typed into it snaps to the nearest step. The
  // arithmetic is `CoreMinuteInterval`'s; these tests read the vector table
  // the Core and Web tests read, and check the picker really asks it — at
  // every place a minute enters or leaves the segment.
  group('TimePicker minuteInterval', () {
    final vectors =
        jsonDecode(File(_kMinuteIntervalVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    List<int> table(String key, int interval) =>
        ((vectors[key]! as Map<String, Object?>)['$interval']! as List)
            .cast<int>();

    Future<void> openPicker(
      WidgetTester tester, {
      String? value = '10:30',
      int minuteInterval = 1,
      bool showSeconds = false,
      String? min,
      String? max,
      ValueChanged<String>? onChanged,
    }) async {
      // A fresh picker every time: a second `pumpWidget` of the same widget
      // type would reuse the previous one's state, popover still open, and
      // the tap below would close it.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: material.Center(
              child: TimePicker(
                value: value,
                use24HourFormat: true,
                showSeconds: showSeconds,
                minuteInterval: minuteInterval,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(TimePicker));
      for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (_segmentFields.evaluate().isNotEmpty) break;
      }
      expect(
        _segmentFields,
        findsWidgets,
        reason: 'the popover never mounted',
      );
    }

    // Segments in panel order: hour, minute, [second].
    Finder segment(int index) => _segmentFields.at(index);
    const hour = 0;
    const minute = 1;
    const second = 2;

    String textOf(WidgetTester tester, int index) => tester
        .widget<EditableText>(
          find.descendant(
            of: segment(index),
            matching: find.byType(EditableText),
          ),
        )
        .controller
        .text;

    Future<void> type(WidgetTester tester, int index, String text) async {
      await tester.enterText(segment(index), text);
      await tester.pump();
    }

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text(DefaultCoUILocalizations.instance.buttonSave));
      await tester.pump();
    }

    test('states no interval by default — one minute', () {
      expect(const TimePicker().minuteInterval, 1);
      expect(
        const TimePicker().minuteInterval,
        CoreTimePickerContract.defaultMinuteInterval,
      );
    });

    group('arrow keys step the minute segment', () {
      testWidgets('up moves a step on and wraps to :00 without the hour', (
        tester,
      ) async {
        await openPicker(tester, minuteInterval: 15);
        await type(tester, minute, '30');

        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(textOf(tester, minute), '45');
        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(textOf(tester, minute), '00');
        expect(textOf(tester, hour), '10', reason: 'no carry into the hour');
      });

      testWidgets('down moves a step back and wraps to the last step', (
        tester,
      ) async {
        await openPicker(tester, minuteInterval: 15);
        await type(tester, minute, '15');

        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(textOf(tester, minute), '00');
        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(textOf(tester, minute), '45');
        expect(textOf(tester, hour), '10', reason: 'no borrow from the hour');
      });

      testWidgets('a held key keeps stepping', (tester) async {
        await openPicker(tester, minuteInterval: 5);
        await type(tester, minute, '00');

        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(textOf(tester, minute), '15');
      });

      testWidgets('steps by one minute when no interval is stated', (
        tester,
      ) async {
        await openPicker(tester);
        await type(tester, minute, '59');

        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(textOf(tester, minute), '00');
        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(textOf(tester, minute), '59');
      });

      testWidgets('matches the shared vectors', (tester) async {
        for (final interval in [1, 5, 15, 30, 60]) {
          await openPicker(tester, minuteInterval: interval);
          for (final start in [0, 7, 29, 45, 53, 59]) {
            await type(tester, minute, '$start');
            await press(tester, LogicalKeyboardKey.arrowUp);
            expect(
              int.parse(textOf(tester, minute)),
              table('up', interval)[start],
              reason: 'up from :$start at $interval',
            );

            await type(tester, minute, '$start');
            await press(tester, LogicalKeyboardKey.arrowDown);
            expect(
              int.parse(textOf(tester, minute)),
              table('down', interval)[start],
              reason: 'down from :$start at $interval',
            );
          }
        }
      });

      testWidgets('leave the hour and second segments alone', (tester) async {
        await openPicker(tester, minuteInterval: 15, showSeconds: true);

        await type(tester, hour, '10');
        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(textOf(tester, hour), '10');

        await type(tester, second, '30');
        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(textOf(tester, second), '30');
        expect(
          textOf(tester, minute),
          '30',
          reason: 'the minute was untouched',
        );
      });
    });

    group('a typed minute snaps to the nearest step', () {
      testWidgets('when the segment loses focus', (tester) async {
        await openPicker(tester, minuteInterval: 15);

        await type(tester, minute, '07');
        await tester.tap(segment(hour));
        await tester.pump();
        expect(textOf(tester, minute), '00');

        await type(tester, minute, '08');
        await tester.tap(segment(hour));
        await tester.pump();
        expect(textOf(tester, minute), '15');
      });

      testWidgets('the top of the hour wraps to :00 of the same hour', (
        tester,
      ) async {
        await openPicker(tester, minuteInterval: 15);

        await type(tester, minute, '53');
        await tester.tap(segment(hour));
        await tester.pump();

        expect(textOf(tester, minute), '00');
        expect(textOf(tester, hour), '10');
      });

      testWidgets('on save, without ever leaving the segment', (tester) async {
        final saved = <String>[];
        await openPicker(
          tester,
          value: '10:00',
          minuteInterval: 15,
          onChanged: saved.add,
        );

        await type(tester, minute, '37');
        await save(tester);

        expect(saved, ['10:30']);
      });

      testWidgets('on save, :53 wraps without carrying into the hour', (
        tester,
      ) async {
        final saved = <String>[];
        await openPicker(
          tester,
          value: '10:00',
          minuteInterval: 15,
          onChanged: saved.add,
        );

        await type(tester, minute, '53');
        await save(tester);

        expect(saved, ['10:00']);
      });

      testWidgets('a minute past :59 is clamped first, as it always was', (
        tester,
      ) async {
        final saved = <String>[];
        await openPicker(
          tester,
          value: '10:00',
          minuteInterval: 20,
          onChanged: saved.add,
        );

        await type(tester, minute, '99');
        await save(tester);

        // :99 -> :59 -> nearest multiple of 20 is :60 -> :00
        expect(saved, ['10:00']);
      });

      testWidgets('matches the shared vectors on save', (tester) async {
        for (final interval in [2, 4, 5, 15, 20, 30]) {
          for (final typed in [0, 1, 2, 7, 8, 22, 23, 38, 53, 58, 59]) {
            final saved = <String>[];
            await openPicker(
              tester,
              value: '10:00',
              minuteInterval: interval,
              onChanged: saved.add,
            );

            await type(tester, minute, '$typed');
            await save(tester);

            final expected = table(
              'snap',
              interval,
            )[typed].toString().padLeft(2, '0');
            expect(
              saved,
              ['10:$expected'],
              reason: ':$typed at $interval',
            );
          }
        }
      });

      testWidgets('a value that is already on a step is saved as it is', (
        tester,
      ) async {
        final saved = <String>[];
        await openPicker(
          tester,
          value: '10:45',
          minuteInterval: 15,
          onChanged: saved.add,
        );

        await save(tester);

        expect(saved, ['10:45']);
      });
    });

    group('the default interval changes nothing', () {
      testWidgets('a typed minute is neither snapped nor reformatted', (
        tester,
      ) async {
        final saved = <String>[];
        await openPicker(tester, value: '10:00', onChanged: saved.add);

        await type(tester, minute, '7');
        await tester.tap(segment(hour));
        await tester.pump();
        expect(textOf(tester, minute), '7', reason: 'left as typed');

        await save(tester);
        expect(saved, ['10:07']);
      });

      testWidgets('a minute past :59 still clamps to :59', (tester) async {
        final saved = <String>[];
        await openPicker(tester, value: '10:00', onChanged: saved.add);

        await type(tester, minute, '99');
        await save(tester);

        expect(saved, ['10:59']);
      });
    });

    // The dialog is a separate construction site from the popover: it builds
    // the same panel content from its own call.
    testWidgets('in a dialog the minute segment steps and snaps too', (
      tester,
    ) async {
      final saved = <String>[];
      await tester.pumpWidget(
        material.MaterialApp(
          // `showDialog` pushes onto the root navigator, so the theme has to
          // sit above it.
          builder: (context, child) =>
              Theme(data: const ThemeData(), child: child ?? const SizedBox()),
          localizationsDelegates: const [CoUILocalizationsDelegate.delegate],
          home: Center(
            child: TimePicker(
              value: '10:00',
              use24HourFormat: true,
              minuteInterval: 15,
              mode: CorePromptMode.dialog,
              onChanged: saved.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TimePicker));
      await tester.pumpAndSettle();

      await type(tester, minute, '30');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(textOf(tester, minute), '45');

      await type(tester, minute, '37');
      await save(tester);
      await tester.pumpAndSettle();

      expect(saved, ['10:30']);
    });

    // The interval is a step, not a bound. `min` / `max` are declarations the
    // picker does not enforce (documented), and an interval must not start
    // enforcing them by accident.
    testWidgets('min and max stay unenforced alongside an interval', (
      tester,
    ) async {
      final saved = <String>[];
      await openPicker(
        tester,
        value: '12:00',
        minuteInterval: 15,
        min: '09:00',
        max: '18:00',
        onChanged: saved.add,
      );

      await type(tester, hour, '22');
      await type(tester, minute, '37');
      await save(tester);

      expect(saved, ['22:30']);
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
  });

  group('TimePicker trigger', () {
    // The trigger is a read-only `TextField` (the DatePicker / Select input
    // look), filling its parent; the picker folds only its own decisions
    // into it.
    // A non-unit scaling so a fold that hands the field a pre-scaled value
    // (the field scales its own height) fails as a double-scale.
    const kScaling = 1.25;

    Future<Finder> pumpTrigger(
      WidgetTester tester,
      CoreTimePickerStyle? style, {
      String? value = '10:00',
      bool enabled = true,
      String? errorText,
    }) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(scaling: kScaling),
            child: material.Scaffold(
              body: material.Center(
                child: TimePicker(
                  value: value,
                  enabled: enabled,
                  errorText: errorText,
                  timePickerStyle: style,
                ),
              ),
            ),
          ),
          localizationsDelegates: const [CoUILocalizationsDelegate.delegate],
        ),
      );
      await tester.pump();

      return find.descendant(
        of: find.byType(TimePicker),
        matching: find.byType(TextField),
      );
    }

    double scalingOf(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(TimePicker))).scaling;

    testWidgets('is one read-only TextField with the clock in its suffix', (
      tester,
    ) async {
      final trigger = await pumpTrigger(tester, null);

      expect(trigger, findsOneWidget);
      final field = tester.widget<TextField>(trigger);
      expect(field.readOnly, isTrue);
      expect(field.value, '10:00 AM');
      expect(field.suffix, isA<Icon>());
      expect(
        find.descendant(of: trigger, matching: find.byType(Button)),
        findsNothing,
      );
    });

    testWidgets('fills the width its parent gives it', (tester) async {
      final trigger = await pumpTrigger(tester, null);

      // `pumpTrigger` seats the picker in a 600-wide host; a fixed 132 would
      // leave the field a fraction of it.
      expect(tester.getSize(trigger).width, greaterThan(300));
      expect(
        tester.getSize(trigger).width,
        tester.getSize(find.byType(TimePicker)).width,
      );
    });

    testWidgets('triggerHeight reaches the trigger field', (tester) async {
      final trigger = await pumpTrigger(
        tester,
        const CoreTimePickerStyle(triggerHeight: CoreSpace.space56),
      );

      expect(
        tester.getSize(trigger).height,
        CoreSpace.space56 * scalingOf(tester),
      );
    });

    testWidgets('the field is 40 tall when nothing states a height', (
      tester,
    ) async {
      final trigger = await pumpTrigger(tester, null);

      expect(tester.getSize(trigger).height, 40 * scalingOf(tester));
    });

    testWidgets('triggerStyle is raw-forwarded and wins over the fold', (
      tester,
    ) async {
      final trigger = await pumpTrigger(
        tester,
        const CoreTimePickerStyle(
          triggerHeight: CoreSpace.space56,
          triggerStyle: CoreTextFieldStyle(height: CoreSpace.space48),
        ),
      );

      expect(
        tester.getSize(trigger).height,
        CoreSpace.space48 * scalingOf(tester),
      );
    });

    testWidgets('the state layer is pressed-only, as Select states it', (
      tester,
    ) async {
      final trigger = await pumpTrigger(tester, null);

      expect(
        tester.widget<TextField>(trigger).textFieldStyle?.stateLayer,
        CoreTimePickerStyle.defaultTriggerStyle.stateLayer,
      );
    });

    testWidgets('an error message reaches the field, and a disabled picker '
        'shows none', (tester) async {
      var trigger = await pumpTrigger(tester, null, errorText: 'Too early');
      expect(tester.widget<TextField>(trigger).errorText, 'Too early');

      trigger = await pumpTrigger(
        tester,
        null,
        enabled: false,
        errorText: 'Too early',
      );
      expect(tester.widget<TextField>(trigger).errorText, isNull);
    });

    testWidgets(
      'the deprecated errorTriggerStyle edge is still the error edge',
      (tester) async {
        const edge = CoreColor.token(CoreColors.tertiary);
        final trigger = await pumpTrigger(
          tester,
          const CoreTimePickerStyle(
            // ignore: deprecated_member_use — the deprecated slot stays honoured
            errorTriggerStyle: CoreButtonStyle(borderColor: edge),
          ),
          errorText: 'Too early',
        );

        expect(
          tester.widget<TextField>(trigger).textFieldStyle?.errorBorderColor,
          edge,
        );
      },
    );

    testWidgets('a disabled picker leaves the text colours to the field', (
      tester,
    ) async {
      final trigger = await pumpTrigger(tester, null, enabled: false);
      final style = tester.widget<TextField>(trigger).textFieldStyle;

      expect(style?.valueStyle, isNull);
      expect(style?.placeholderStyle, isNull);
    });
  });

  group('TimePicker segment focused face', () {
    double scalingOf(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(TimePicker))).scaling;

    Future<void> openPicker(WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: material.Center(child: TimePicker(value: '10:00')),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(TimePicker));
      for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (_segmentFields.evaluate().isNotEmpty) break;
      }
      expect(
        _segmentFields,
        findsWidgets,
        reason:
            'the popover never mounted — nothing below would be a statement '
            'about the focused face',
      );
    }

    final segmentBoxes = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).border != null &&
          w.constraints?.maxWidth == CoreTimePickerStyle.defaultSegmentSize,
    );

    Color boxFill(WidgetTester tester, int index) {
      final box = tester.widget<Container>(segmentBoxes.at(index));
      return (box.decoration! as BoxDecoration).color!;
    }

    Color schemeColor(WidgetTester tester, CoreColor color) => Theme.of(
      tester.element(find.byType(TimePicker)),
    ).colorScheme.resolve(color).toValue();

    testWidgets('a segment is 64 wide, 60 tall, corner 10', (tester) async {
      await openPicker(tester);

      final scaling = scalingOf(tester);
      final size = tester.getSize(segmentBoxes.first);
      expect(size.width, 64 * scaling);
      expect(size.height, 60 * scaling);
      final box = tester.widget<Container>(segmentBoxes.first);
      expect(
        (box.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(10 * scaling),
      );
    });

    testWidgets('the editing segment takes a face, the others rest', (
      tester,
    ) async {
      await openPicker(tester);
      final rest = schemeColor(
        tester,
        CoreTimePickerStyle.defaultSegmentSurfaceColor,
      );
      final face = schemeColor(
        tester,
        CoreTimePickerStyle.defaultSegmentFocusedSurfaceColor,
      );
      expect(face, isNot(rest));
      expect(boxFill(tester, 0), rest);
      expect(boxFill(tester, 1), rest);

      await tester.tap(_segmentFields.first);
      await tester.pump();
      expect(boxFill(tester, 0), face);
      expect(boxFill(tester, 1), rest);

      await tester.tap(_segmentFields.at(1));
      await tester.pump();
      expect(boxFill(tester, 0), rest);
      expect(boxFill(tester, 1), face);
    });

    testWidgets(
      'a tapped segment wears a 2px primaryText inside border, the others '
      'keep their rest border, and no tile moves',
      (tester) async {
        await openPicker(tester);
        final scaling = scalingOf(tester);
        BorderSide side(int index) {
          final box = tester.widget<Container>(segmentBoxes.at(index));
          return ((box.decoration! as BoxDecoration).border! as Border).top;
        }

        final restColor = schemeColor(
          tester,
          CoreTimePickerStyle.defaultSegmentBorderColor,
        );
        final focusColor = schemeColor(
          tester,
          CoreTimePickerStyle.defaultSegmentFocusedBorderColor,
        );
        expect(focusColor, isNot(restColor));
        final restRects = [
          for (var i = 0; i < segmentBoxes.evaluate().length; i++)
            tester.getRect(segmentBoxes.at(i)),
        ];
        expect(side(0).color, restColor);
        expect(side(0).width, CoreStrokeWidth.stroke1 * scaling);

        // A pointer focus, not a keyboard one — the border must show here.
        await tester.tap(_segmentFields.first);
        await tester.pump();
        final edited = side(0);
        expect(edited.color, focusColor);
        expect(edited.width, CoreStrokeWidth.stroke2 * scaling);
        expect(edited.strokeAlign, BorderSide.strokeAlignInside);
        expect(side(1).color, restColor);
        expect(side(1).width, CoreStrokeWidth.stroke1 * scaling);
        for (var i = 0; i < restRects.length; i++) {
          expect(tester.getRect(segmentBoxes.at(i)), restRects[i]);
        }

        await tester.tap(_segmentFields.at(1));
        await tester.pump();
        expect(side(0).color, restColor);
        expect(side(1).color, focusColor);
      },
    );

    testWidgets('the segments draw no focus ring of their own', (
      tester,
    ) async {
      await openPicker(tester);
      await tester.tap(_segmentFields.first);
      await tester.pump();

      // The only `FocusOutline`s left under the panel are the segment
      // `TextField`s' own (silenced: transparent edge) and the action
      // buttons' — none wraps a segment box.
      for (final box in segmentBoxes.evaluate()) {
        expect(
          find.ancestor(
            of: find.byElementPredicate((e) => e == box),
            matching: find.byType(FocusOutline),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('the edited segment text takes the on-container colour', (
      tester,
    ) async {
      await openPicker(tester);
      await tester.tap(_segmentFields.first);
      await tester.pump();

      final style = tester
          .widget<TextField>(_segmentFields.first)
          .textFieldStyle!
          .valueStyle!;
      expect(
        style.color,
        CoreTimePickerStyle.defaultSegmentFocusedContentColor,
      );
    });

    testWidgets(
      'the AM/PM column stands beside the segments, as tall as one (56) '
      'and aligned to their top',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const material.Scaffold(
              body: material.Center(
                child: TimePicker(value: '10:00', use24HourFormat: false),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.byType(TimePicker));
        for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (_segmentFields.evaluate().isNotEmpty) break;
        }

        final toggle = find.byType(ToggleGroup<bool>);
        expect(toggle, findsOneWidget);
        expect(
          tester.widget<ToggleGroup<bool>>(toggle).direction,
          CoreAxis.vertical,
        );
        final column = tester.getRect(toggle);
        final segment = tester.getRect(segmentBoxes.last);

        // `3 + 24 + 2 + 24 + 3` — the height of the segment box. Sizes are
        // read untransformed (the panel may still be scaling in); the rects
        // below are compared with each other, under the same transform.
        expect(
          tester.getSize(toggle).height,
          CoreTimePickerStyle.defaultSegmentHeight * scalingOf(tester),
        );
        expect(column.height, closeTo(segment.height, 0.01));
        expect(column.top, closeTo(segment.top, 0.01), reason: 'top-aligned');
        expect(column.left, greaterThan(segment.right), reason: 'beside');

        // AM above PM, in one column.
        final am = tester.getCenter(
          find.descendant(of: toggle, matching: find.text('AM')).last,
        );
        final pm = tester.getCenter(
          find.descendant(of: toggle, matching: find.text('PM')).last,
        );
        expect(am.dy, lessThan(pm.dy));
        expect(am.dx, closeTo(pm.dx, 0.01));
      },
    );

    testWidgets(
      'the AM/PM toggle is the sm size: 26 cells in a 32-wide track',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            const material.Scaffold(
              body: material.Center(
                child: TimePicker(value: '10:00', use24HourFormat: false),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.byType(TimePicker));
        for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (_segmentFields.evaluate().isNotEmpty) break;
        }

        final toggle = find.byType(ToggleGroup<bool>);
        expect(
          tester.widget<ToggleGroup<bool>>(toggle).size,
          CoreComponentSize.sm,
        );
        final scaling = scalingOf(tester);
        // Vertical: the 32 track is its width; two 26 cells stack to 60.
        expect(
          tester.getSize(toggle).width,
          greaterThanOrEqualTo(32 * scaling),
        );
        expect(tester.getSize(toggle).height, closeTo(60 * scaling, 0.01));
        final cell = find
            .ancestor(
              of: find.text('AM').last,
              matching: find.byType(material.AnimatedContainer),
            )
            .first;
        expect(tester.getSize(cell).height, 26 * scaling);
      },
    );
  });

  // A hovered segment wears a state layer over its tile: the layer colour
  // (`onSurface` at the ramp's hover weight) is laid over the tile's own
  // shape, on whichever face the tile wears — the edited segment's too. The
  // face colour and the border are not touched.
  group('TimePicker segment hover state layer', () {
    const kRaw = CoreColor(0xFF00FF00);

    Future<void> openPicker(
      WidgetTester tester, {
      CoreTimePickerStyle? style,
    }) async {
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: material.Center(
              child: TimePicker(value: '10:00', timePickerStyle: style),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(TimePicker));
      for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (_segmentFields.evaluate().isNotEmpty) break;
      }
      expect(
        _segmentFields,
        findsWidgets,
        reason:
            'the popover never mounted — nothing below would be a statement',
      );
    }

    // The boxes the segments draw — a `Container` with a border and the
    // segment's tight extent (the popover panel and the buttons are neither).
    final segmentBoxes = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).border != null &&
          w.constraints?.maxWidth == CoreTimePickerStyle.defaultSegmentSize,
    );

    BoxDecoration face(WidgetTester tester, int index) =>
        tester.widget<Container>(segmentBoxes.at(index)).decoration!
            as BoxDecoration;

    Color boxBorder(WidgetTester tester, int index) =>
        (face(tester, index).border! as Border).top.color;

    BoxDecoration? layer(WidgetTester tester, int index) =>
        tester.widget<Container>(segmentBoxes.at(index)).foregroundDecoration
            as BoxDecoration?;

    Color schemeColor(WidgetTester tester, CoreColor color) => Theme.of(
      tester.element(find.byType(TimePicker)),
    ).colorScheme.resolve(color).toValue();

    Future<TestGesture> mouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      return gesture;
    }

    testWidgets('the resolver states the layer at the ramp’s hover weight', (
      tester,
    ) async {
      await openPicker(tester);
      final resolved = resolveTimePicker(
        tester.element(find.byType(TimePicker)),
      );

      expect(
        resolved.segmentHoverLayerColor,
        schemeColor(
          tester,
          CoreTimePickerStyle.defaultSegmentStateLayerColor.scaleAlpha(
            CoreTimePickerStyle.defaultSegmentStateLayer.hover,
          ),
        ),
      );
    });

    testWidgets(
      'a pointer over one segment lays the layer on that segment only, '
      'face and border unchanged',
      (tester) async {
        await openPicker(tester);
        expect(segmentBoxes, findsNWidgets(2));
        final restFace = face(tester, 0).color;
        final restBorder = boxBorder(tester, 0);
        expect(layer(tester, 0), isNull);
        expect(layer(tester, 1), isNull);

        final gesture = await mouse(tester);
        await gesture.moveTo(tester.getCenter(segmentBoxes.at(0)));
        await tester.pump();

        final laid = layer(tester, 0)!;
        expect(
          laid.color,
          resolveTimePicker(
            tester.element(find.byType(TimePicker)),
          ).segmentHoverLayerColor,
        );
        expect(
          laid.borderRadius,
          face(tester, 0).borderRadius,
          reason: 'the layer takes the tile’s own shape',
        );
        expect(face(tester, 0).color, restFace, reason: 'face unchanged');
        expect(boxBorder(tester, 0), restBorder, reason: 'no border step');
        expect(layer(tester, 1), isNull);

        // Moving across hands the layer over.
        await gesture.moveTo(tester.getCenter(segmentBoxes.at(1)));
        await tester.pump();
        expect(layer(tester, 0), isNull);
        expect(layer(tester, 1), isNotNull);

        await gesture.moveTo(Offset.zero);
        await tester.pump();
        expect(layer(tester, 0), isNull);
        expect(layer(tester, 1), isNull);
      },
    );

    testWidgets('the edited segment takes the layer over its focused face', (
      tester,
    ) async {
      await openPicker(tester);

      final gesture = await mouse(tester);
      final segment = tester.getCenter(segmentBoxes.at(0));
      await gesture.moveTo(segment);
      await tester.pump();
      final restFace = face(tester, 0).color;

      // Focus it with the mouse, which then stays over the segment.
      await gesture.down(segment);
      await gesture.up();
      await tester.pump();

      expect(
        tester.widget<TextField>(_segmentFields.first).focusNode?.hasFocus ??
            true,
        isTrue,
        reason: 'the segment holds focus — its face is the focus treatment',
      );
      expect(
        face(tester, 0).color,
        isNot(restFace),
        reason: 'the focused face is the primary-container fill',
      );
      expect(
        layer(tester, 0),
        isNotNull,
        reason: 'the layer is laid on it too',
      );
      expect(
        boxBorder(tester, 0),
        schemeColor(
          tester,
          CoreTimePickerStyle.defaultSegmentFocusedBorderColor,
        ),
        reason:
            "the border is the edited segment's inside border — hover adds "
            'no border step of its own',
      );
    });

    testWidgets('the colour and weight slots reach the painted layer', (
      tester,
    ) async {
      await openPicker(
        tester,
        style: const CoreTimePickerStyle(
          segmentStateLayerColor: kRaw,
          segmentStateLayer: CoreStateLayer(
            hover: CoreOpacity.opacity16,
            focus: CoreOpacity.opacity16,
            pressed: CoreOpacity.opacity16,
          ),
        ),
      );

      final gesture = await mouse(tester);
      await gesture.moveTo(tester.getCenter(segmentBoxes.at(0)));
      await tester.pump();

      expect(
        layer(tester, 0)!.color,
        kRaw.scaleAlpha(CoreOpacity.opacity16).toValue(),
      );
    });

    // A zero-width Flutter border is a hairline, not nothing. The segment's
    // composed `TextField` takes an `onSurface` border while hovered unless
    // the chromeless style silences it — a second line inside the box that
    // already draws the segment's border.
    testWidgets(
      'the chromeless inner field paints no hover border of its own',
      (
        tester,
      ) async {
        await openPicker(tester);

        final gesture = await mouse(tester);
        await gesture.moveTo(tester.getCenter(segmentBoxes.at(0)));
        await tester.pump();

        final inner = find.descendant(
          of: _segmentFields.first,
          matching: find.byType(DecoratedBox),
        );
        expect(inner, findsWidgets);
        for (final box in tester.widgetList<DecoratedBox>(inner)) {
          final decoration = box.decoration;
          if (decoration is! BoxDecoration) continue;
          final border = decoration.border;
          if (border is Border) {
            expect(
              border.top.color.a,
              0,
              reason: 'the inner field must not draw a border while hovered',
            );
          }
        }
      },
    );
  });

  // The colon between two segments is punctuation, not a digit: its own role
  // (`headlineSmall` at medium) and the quieter `onSurfaceSubtle`, centred
  // against the segment tiles — the Web twin's `height: segmentHeight` +
  // `align-items: center`.
  group('TimePicker segment separator', () {
    Future<void> openPicker(
      WidgetTester tester, {
      CoreTimePickerStyle? style,
    }) async {
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: material.Center(
              child: TimePicker(value: '10:00', timePickerStyle: style),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(TimePicker));
      for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (_segmentFields.evaluate().isNotEmpty) break;
      }
      expect(_segmentFields, findsWidgets);
    }

    TextStyle colonStyle(WidgetTester tester) => tester
        .widget<RichText>(
          find
              .descendant(
                of: find.text(':').first,
                matching: find.byType(RichText),
              )
              .first,
        )
        .text
        .style!;

    testWidgets('draws headlineSmall at medium in onSurfaceSubtle', (
      tester,
    ) async {
      await openPicker(tester);
      final theme = Theme.of(tester.element(find.byType(TimePicker)));
      final style = colonStyle(tester);
      final role = theme.typography.resolve(
        const CoreTextStyle.token(CoreTextStyles.headlineSmall),
      );

      expect(style.fontSize, role.fontSize);
      expect(style.fontSize, CoreFontSize.s24);
      expect(style.fontWeight, FontWeight.w500);
      expect(
        style.color,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceSubtle))
            .toValue(),
      );
    });

    testWidgets('sits centred against the segment tiles', (tester) async {
      await openPicker(tester);
      final colon = tester.getRect(find.text(':').first);
      final segment = tester.getRect(_segmentFields.first);

      expect(colon.center.dy, moreOrLessEquals(segment.center.dy, epsilon: 1));
    });

    // #6201: the edited segment draws a 2 px inside border, so the digits
    // have to leave about 8 inside it — `headlineMedium` (28, a 39 px line)
    // in the 64 × 60 cell. `displaySmall` (44, a 62 px line) overran it.
    testWidgets('the digits are headlineMedium and clear the edited border', (
      tester,
    ) async {
      await openPicker(tester);
      final editable = find.descendant(
        of: _segmentFields.first,
        matching: find.byType(EditableText),
      );
      final style = tester.widget<EditableText>(editable).style;
      expect(style.fontSize, CoreFontSize.s28);
      // The line box, border 2 + room 8 above and below inside the cell.
      final lineBox = style.fontSize! * style.height!;
      expect(
        lineBox,
        lessThanOrEqualTo(CoreTimePickerStyle.defaultSegmentHeight - 2 * 10),
      );
    });

    testWidgets("follows its own fields, not the digits' role", (
      tester,
    ) async {
      await openPicker(
        tester,
        style: const CoreTimePickerStyle(
          separatorTypography: CoreTextStyle.token(CoreTextStyles.titleLarge),
          separatorColor: CoreColor.token(CoreColors.error),
          valueTypography: CoreTextStyle.token(CoreTextStyles.bodyLarge),
        ),
      );
      final theme = Theme.of(tester.element(find.byType(TimePicker)));
      final style = colonStyle(tester);

      expect(style.fontSize, CoreFontSize.s20);
      expect(
        style.color,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.error))
            .toValue(),
      );
    });
  });

  group('TimePicker popover names itself', () {
    // The Web twin puts `role="dialog"` and the localised label on the
    // panel's content; a screen reader should announce the picker the same
    // way on Flutter. The string is the locale's, not a literal here.
    testWidgets("by the locale's label, as a dialog", (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: material.Center(
              child: TimePicker(value: '10:00', use24HourFormat: false),
            ),
          ),
        ),
      );
      await tester.pump();

      // Closed, nothing carries the name — the control for the open reading.
      final label = DefaultCoUILocalizations.instance.timePickerPopoverLabel;
      expect(find.bySemanticsLabel(label), findsNothing);

      await tester.tap(find.byType(TimePicker));
      // Frame by frame, like the other popover tests: one large pump builds a
      // single frame and the panel is not in the semantics tree after it.
      for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (_segmentFields.evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData()
            .role,
        SemanticsRole.dialog,
      );
    });

    testWidgets('and the controls sit inside the named panel', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: material.Center(
              child: TimePicker(value: '10:00', use24HourFormat: false),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(TimePicker));
      for (var frame = 0; frame < _kPopoverMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (_segmentFields.evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 50));

      // The name is on the panel that holds the controls, not on a sibling:
      // the save action's own semantics node has the named panel as an
      // ancestor, so a reader entering the panel hears what it is first.
      final panel = tester.getSemantics(
        find.bySemanticsLabel(
          DefaultCoUILocalizations.instance.timePickerPopoverLabel,
        ),
      );
      var node = tester
          .getSemantics(
            find.bySemanticsLabel(
              DefaultCoUILocalizations.instance.buttonSave,
            ),
          )
          .parent;
      var inside = false;
      while (node != null) {
        if (node.id == panel.id) inside = true;
        node = node.parent;
      }
      expect(inside, isTrue);
    });
  });
}
