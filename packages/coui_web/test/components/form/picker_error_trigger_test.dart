import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/validated/validation_state_scope.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The error state of a picker's trigger.
///
/// The Date / DateRange trigger is a read-only `TextField`, so its error look
/// is the field's own: an `error` edge and ring, switched on through the
/// ambient validation state (the picker draws the message itself, in its own
/// row). The edge colour is a Core default (`defaultErrorTriggerStyle`'s
/// border) a caller can override per instance (`triggerStyle.errorBorderColor`,
/// or the deprecated `errorTriggerStyle`). The Flutter twin has the same file;
/// the claims are the same ones, read off what reaches the `TextField`.
const _kError = CoreColor.token(CoreColors.error);
const _kOverride = CoreColor.token(CoreColors.tertiary);
const _kValue = '2024-01-15';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);

    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));

  return context;
}

TextField _field(ComponentTester tester) =>
    find.byType(TextField).evaluate().single.component as TextField;

/// Whether the trigger field sits under an ambient `invalid` validation state
/// — what switches its own error variant (edge and ring) on.
bool _fieldIsInvalid(ComponentTester tester) =>
    ValidationStateScope.maybeOf(find.byType(TextField).evaluate().single) ==
    CoreValidationState.invalid;

void main() {
  group('DatePicker', () {
    testComponents('an error trigger is a read-only field in the error tone', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DatePicker(value: _kValue, errorText: 'Pick a valid date'),
      );

      final field = _field(tester);
      expect(field.readOnly, isTrue);
      expect(_fieldIsInvalid(tester), isTrue);
      expect(field.textFieldStyle?.errorBorderColor, _kError);
      expect(find.byType(Button), findsNothing);
      // The message is the picker's own row, drawn once.
      expect(field.errorText, isNull);
    });

    testComponents('without an error the field is not in the error tone', (
      tester,
    ) async {
      pumpWithTheme(tester, const DatePicker(value: _kValue));

      expect(_fieldIsInvalid(tester), isFalse);
      expect(_field(tester).textFieldStyle?.errorBorderColor, _kError);
    });

    testComponents('a disabled picker is the disabled field, error or not', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DatePicker(
          value: _kValue,
          enabled: false,
          errorText: 'Pick a valid date',
        ),
      );

      final field = _field(tester);
      expect(field.enabled, isFalse);
      expect(_fieldIsInvalid(tester), isFalse);
      expect(field.textFieldStyle?.valueStyle, isNull);
    });

    testComponents(
      'the deprecated errorTriggerStyle border is the error edge',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          const DatePicker(
            value: _kValue,
            errorText: 'Pick a valid date',
            datePickerStyle: CoreDatePickerStyle(
              // ignore: deprecated_member_use — the deprecated slot is honoured
              errorTriggerStyle: CoreButtonStyle(borderColor: _kOverride),
            ),
          ),
        );

        expect(_field(tester).textFieldStyle?.errorBorderColor, _kOverride);
      },
    );

    testComponents(
      'triggerStyle errorBorderColor outranks the deprecated slot',
      (
        tester,
      ) async {
        final resolved = resolveDatePicker(
          _themedContext(tester),
          datePickerStyle: const CoreDatePickerStyle(
            // ignore: deprecated_member_use — the deprecated slot is honoured
            errorTriggerStyle: CoreButtonStyle(borderColor: _kOverride),
            triggerStyle: CoreTextFieldStyle(errorBorderColor: _kError),
          ),
        );

        expect(resolved.triggerStyle.errorBorderColor, _kError);
      },
    );

    testComponents('triggerStyle is raw-forwarded to the field', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DatePicker(
          value: _kValue,
          datePickerStyle: CoreDatePickerStyle(
            triggerStyle: CoreTextFieldStyle(height: 56),
          ),
        ),
      );

      expect(_field(tester).textFieldStyle?.height, 56);
    });

    testComponents('the button-era popoverStyle.triggerStyle is not read', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DatePicker(
          value: _kValue,
          datePickerStyle: CoreDatePickerStyle(
            popoverStyle: CorePopoverStyle(
              triggerStyle: CoreButtonStyle(height: 44),
            ),
          ),
        ),
      );

      expect(_field(tester).textFieldStyle?.height, isNull);
    });
  });

  group('DateRangePicker', () {
    testComponents('an error trigger is a read-only field in the error tone', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DateRangePicker(
          value: (start: _kValue, end: '2024-01-20'),
          errorText: 'Pick a valid range',
        ),
      );

      final field = _field(tester);
      expect(field.readOnly, isTrue);
      expect(_fieldIsInvalid(tester), isTrue);
      expect(field.textFieldStyle?.errorBorderColor, _kError);
      expect(field.errorText, isNull);
    });
  });

  group('TimePicker', () {
    // The trigger is a read-only `TextField`; its error look is the field's
    // own (an `error` edge and ring from the error message), not a button
    // bundle.
    TextField field(ComponentTester tester) =>
        find.byType(TextField).evaluate().single.component as TextField;

    testComponents('an error message reaches the trigger field', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TimePicker(value: '09:30', errorText: 'Pick a valid time'),
      );

      expect(field(tester).errorText, 'Pick a valid time');
    });

    testComponents(
      'without an error the trigger shows no message, edge is the error token',
      (
        tester,
      ) async {
        pumpWithTheme(tester, const TimePicker(value: '09:30'));

        expect(field(tester).errorText, isNull);
        expect(field(tester).textFieldStyle?.errorBorderColor, _kError);
      },
    );

    testComponents('a disabled picker shows no error, error text or not', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TimePicker(
          value: '09:30',
          enabled: false,
          errorText: 'Pick a valid time',
        ),
      );

      expect(field(tester).errorText, isNull);
    });

    testComponents(
      'the deprecated errorTriggerStyle border is the error edge',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          const TimePicker(
            value: '09:30',
            errorText: 'Pick a valid time',
            timePickerStyle: CoreTimePickerStyle(
              // ignore: deprecated_member_use — the deprecated slot is honoured
              errorTriggerStyle: CoreButtonStyle(borderColor: _kOverride),
            ),
          ),
        );

        expect(field(tester).textFieldStyle?.errorBorderColor, _kOverride);
      },
    );

    testComponents(
      'triggerStyle errorBorderColor outranks the deprecated slot',
      (
        tester,
      ) async {
        final resolved = resolveTimePicker(
          _themedContext(tester),
          timePickerStyle: const CoreTimePickerStyle(
            // ignore: deprecated_member_use — the deprecated slot is honoured
            errorTriggerStyle: CoreButtonStyle(borderColor: _kOverride),
            triggerStyle: CoreTextFieldStyle(errorBorderColor: _kError),
          ),
        );

        expect(resolved.triggerStyle.errorBorderColor, _kError);
      },
    );
  });
}
