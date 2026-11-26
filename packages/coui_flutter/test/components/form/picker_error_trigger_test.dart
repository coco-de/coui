import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The error state of a picker's trigger.
///
/// The Date / DateRange trigger is a read-only `TextField`, so its error look
/// is the field's own: an `error` edge and ring, switched on through the
/// ambient validation state (the picker draws the message itself, in its own
/// row). The edge colour is a Core default (`defaultErrorTriggerStyle`'s
/// border) a caller can override per instance (`triggerStyle.errorBorderColor`,
/// or the deprecated `errorTriggerStyle`). These tests read what reaches the
/// `TextField`, since a field that is wired through the style and never read
/// looks complete from the authoring side.
const _kError = CoreColor.token(CoreColors.error);
const _kOverride = CoreColor.token(CoreColors.tertiary);

material.Widget _app(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
  localizationsDelegates: const [CoUILocalizationsDelegate.delegate],
);

Finder _field(Type picker) =>
    find.descendant(of: find.byType(picker), matching: find.byType(TextField));

TextField _trigger(WidgetTester tester, Type picker) =>
    tester.widget<TextField>(_field(picker));

/// Whether the trigger field sits under an ambient `invalid` validation state
/// — what switches its own error variant (edge and ring) on.
bool _fieldIsInvalid(WidgetTester tester, Type picker) =>
    Data.maybeOf<CoreValidationState>(tester.element(_field(picker))) ==
    CoreValidationState.invalid;

void main() {
  group('DatePicker', () {
    testWidgets('an error trigger is a read-only field in the error tone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: (_) {},
            errorText: 'Pick a valid date',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = _trigger(tester, DatePicker);
      expect(field.readOnly, isTrue);
      expect(_fieldIsInvalid(tester, DatePicker), isTrue);
      expect(field.textFieldStyle?.errorBorderColor, _kError);
      // Never a filled control — and never a button.
      expect(
        find.descendant(
          of: find.byType(DatePicker),
          matching: find.byType(Button),
        ),
        findsNothing,
      );
      // The message is the picker's own row, drawn once (the field is told
      // the tone, not the text).
      expect(field.errorText, isNull);
      expect(find.text('Pick a valid date'), findsOneWidget);
    });

    testWidgets('without an error the field is not in the error tone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(DatePicker(value: DateTime(2024, 1, 15), onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(_fieldIsInvalid(tester, DatePicker), isFalse);
      // The error edge is stated up front, so the error tone has it ready.
      expect(
        _trigger(tester, DatePicker).textFieldStyle?.errorBorderColor,
        _kError,
      );
    });

    testWidgets('a disabled picker is the disabled field, error or not', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            enabled: false,
            errorText: 'Pick a valid date',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Disabled outranks the error: the error tone must not reach a field
      // that cannot be used, and its text colours are left to the field's
      // own disabled tone.
      final field = _trigger(tester, DatePicker);
      expect(field.enabled, isFalse);
      expect(_fieldIsInvalid(tester, DatePicker), isFalse);
      expect(field.textFieldStyle?.valueStyle, isNull);
      expect(field.textFieldStyle?.placeholderStyle, isNull);
    });

    testWidgets('the deprecated errorTriggerStyle border is the error edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: (_) {},
            errorText: 'Pick a valid date',
            // ignore: deprecated_member_use — the deprecated slot is honoured
            datePickerStyle: const CoreDatePickerStyle(
              errorTriggerStyle: CoreButtonStyle(borderColor: _kOverride),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _trigger(tester, DatePicker).textFieldStyle?.errorBorderColor,
        _kOverride,
      );
    });

    testWidgets('triggerStyle errorBorderColor outranks the deprecated slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: (_) {},
            errorText: 'Pick a valid date',
            // ignore: deprecated_member_use — the deprecated slot is honoured
            datePickerStyle: const CoreDatePickerStyle(
              errorTriggerStyle: CoreButtonStyle(borderColor: _kOverride),
              triggerStyle: CoreTextFieldStyle(errorBorderColor: _kError),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _trigger(tester, DatePicker).textFieldStyle?.errorBorderColor,
        _kError,
      );
    });

    testWidgets('triggerStyle is raw-forwarded to the field', (tester) async {
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: (_) {},
            datePickerStyle: const CoreDatePickerStyle(
              triggerStyle: CoreTextFieldStyle(height: 56),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_trigger(tester, DatePicker).textFieldStyle?.height, 56);
    });

    testWidgets('the button-era popoverStyle.triggerStyle is no longer read', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: (_) {},
            datePickerStyle: const CoreDatePickerStyle(
              popoverStyle: CorePopoverStyle(
                triggerStyle: CoreButtonStyle(height: 44),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_trigger(tester, DatePicker).textFieldStyle?.height, isNull);
    });

    testWidgets('the rendered trigger draws an error-coloured stroke', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: (_) {},
            errorText: 'Pick a valid date',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(DatePicker));
      final error = Theme.of(context).colorScheme.resolve(_kError).toValue();
      final decorations = tester
          .widgetList<material.DecoratedBox>(
            find.descendant(
              of: _field(DatePicker),
              matching: find.byType(material.DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>();

      expect(
        decorations.any((d) => d.border?.top.color == error),
        isTrue,
        reason: 'no box in the trigger draws the error stroke',
      );
      // …and no box is filled with the error colour.
      expect(decorations.any((d) => d.color == error), isFalse);
    });

    testWidgets('the rendered value is the enabled colour, in error too', (
      tester,
    ) async {
      Future<Color?> paintedValueColor({String? errorText}) async {
        await tester.pumpWidget(
          _app(
            DatePicker(
              value: DateTime(2024, 1, 15),
              onChanged: (_) {},
              errorText: errorText,
            ),
          ),
        );
        await tester.pumpAndSettle();

        return tester
            .widget<material.EditableText>(
              find.descendant(
                of: _field(DatePicker),
                matching: find.byType(material.EditableText),
              ),
            )
            .style
            .color;
      }

      final rest = await paintedValueColor();
      final inError = await paintedValueColor(errorText: 'Pick a valid date');

      // An error changes the edge, not the text.
      expect(inError, rest);
      final context = tester.element(find.byType(DatePicker));
      expect(
        inError,
        isNot(Theme.of(context).colorScheme.resolve(_kError).toValue()),
      );
    });
  });

  group('DateRangePicker', () {
    testWidgets('an error trigger is a read-only field in the error tone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          DateRangePicker(
            value: DateTimeRange(DateTime(2024, 1, 15), DateTime(2024, 1, 20)),
            onChanged: (_) {},
            errorText: 'Pick a valid range',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = _trigger(tester, DateRangePicker);
      expect(field.readOnly, isTrue);
      expect(field.value, '2024-01-15 - 2024-01-20');
      expect(_fieldIsInvalid(tester, DateRangePicker), isTrue);
      expect(field.textFieldStyle?.errorBorderColor, _kError);
      expect(field.errorText, isNull);
      expect(find.text('Pick a valid range'), findsOneWidget);
    });
  });

  group('TimePicker', () {
    // The trigger is a read-only `TextField`; its error look is the field's
    // own (an `error` edge and ring from the error message), not a button
    // bundle.
    TextField trigger(WidgetTester tester) => tester.widget<TextField>(
      find.descendant(
        of: find.byType(TimePicker),
        matching: find.byType(TextField),
      ),
    );

    testWidgets('an error message reaches the trigger field', (tester) async {
      await tester.pumpWidget(
        _app(
          TimePicker(
            value: '09:30',
            onChanged: (_) {},
            errorText: 'Pick a valid time',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(trigger(tester).errorText, 'Pick a valid time');
      expect(find.text('Pick a valid time'), findsOneWidget);
    });

    testWidgets(
      'without an error the trigger shows no message, and its error edge is the error token',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(TimePicker(value: '09:30', onChanged: (_) {})),
        );
        await tester.pumpAndSettle();

        expect(trigger(tester).errorText, isNull);
        expect(trigger(tester).textFieldStyle?.errorBorderColor, _kError);
      },
    );

    testWidgets('a disabled picker shows no error, error text or not', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const TimePicker(
            value: '09:30',
            enabled: false,
            errorText: 'Pick a valid time',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(trigger(tester).errorText, isNull);
    });

    testWidgets('the deprecated errorTriggerStyle border is the error edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TimePicker(
            value: '09:30',
            onChanged: (_) {},
            errorText: 'Pick a valid time',
            // ignore: deprecated_member_use — the deprecated slot is honoured
            timePickerStyle: const CoreTimePickerStyle(
              errorTriggerStyle: CoreButtonStyle(borderColor: _kOverride),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        trigger(tester).textFieldStyle?.errorBorderColor,
        _kOverride,
      );
    });

    testWidgets('triggerStyle errorBorderColor outranks the deprecated slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TimePicker(
            value: '09:30',
            onChanged: (_) {},
            errorText: 'Pick a valid time',
            // ignore: deprecated_member_use — the deprecated slot is honoured
            timePickerStyle: const CoreTimePickerStyle(
              errorTriggerStyle: CoreButtonStyle(borderColor: _kOverride),
              triggerStyle: CoreTextFieldStyle(errorBorderColor: _kError),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(trigger(tester).textFieldStyle?.errorBorderColor, _kError);
    });
  });
}
