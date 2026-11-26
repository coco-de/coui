// The trigger value colour on Web: the trigger is a read-only `TextField`, and
// the picker's `contentColor` is an enabled value colour — folded into the
// field's `valueStyle` for an enabled picker (in error too, since an error
// changes the trigger's edge and ring and leaves the text alone), and left out
// for disabled so the field's own disabled tone answers. "No value"
// (placeholder colour) is a different state and is not a stand-in for it.
// Mirrors the Flutter twin.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kValue = '2024-01-15';
const _kContentColor = CoreColor.token(CoreColors.primary);
const _kPlaceholderColor = CoreColor.token(CoreColors.tertiary);
const _kStyled = CoreDatePickerStyle(contentColor: _kContentColor);

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

void main() {
  group('the resolver', () {
    testComponents('folds the value and placeholder colours when enabled', (
      tester,
    ) async {
      final resolved = resolveDatePicker(
        _themedContext(tester),
        datePickerStyle: const CoreDatePickerStyle(
          contentColor: _kContentColor,
          placeholderColor: _kPlaceholderColor,
        ),
      );

      expect(resolved.triggerStyle.valueStyle?.color, _kContentColor);
      expect(resolved.triggerStyle.placeholderStyle?.color, _kPlaceholderColor);
    });

    testComponents('states the defaults when nothing is overridden', (
      tester,
    ) async {
      final resolved = resolveDatePicker(_themedContext(tester));

      expect(
        resolved.triggerStyle.valueStyle?.color,
        CoreDatePickerStyle.defaultContentColor,
      );
      expect(
        resolved.triggerStyle.placeholderStyle?.color,
        CoreDatePickerStyle.defaultPlaceholderColor,
      );
    });

    testComponents('leaves both colours to the field when disabled', (
      tester,
    ) async {
      final resolved = resolveDatePicker(
        _themedContext(tester),
        datePickerStyle: _kStyled,
        enabled: false,
      );

      expect(resolved.triggerStyle.valueStyle, isNull);
      expect(resolved.triggerStyle.placeholderStyle, isNull);
    });
  });

  group('the rendered trigger', () {
    testComponents('enabled hands contentColor to the field', (tester) async {
      pumpWithTheme(
        tester,
        const DatePicker(value: _kValue, datePickerStyle: _kStyled),
      );

      expect(_field(tester).textFieldStyle?.valueStyle?.color, _kContentColor);
    });

    testComponents('disabled hands the field no value colour', (tester) async {
      pumpWithTheme(
        tester,
        const DatePicker(
          value: _kValue,
          enabled: false,
          datePickerStyle: _kStyled,
        ),
      );

      final field = _field(tester);
      expect(field.enabled, isFalse);
      expect(field.textFieldStyle?.valueStyle, isNull);
      expect(field.textFieldStyle?.placeholderStyle, isNull);
    });

    testComponents(
      'error (enabled) hands contentColor like any enabled picker — the '
      'text is not turned error',
      (tester) async {
        pumpWithTheme(
          tester,
          const DatePicker(
            value: _kValue,
            errorText: 'Pick a valid date',
            datePickerStyle: _kStyled,
          ),
        );

        final field = _field(tester);
        expect(field.enabled, isTrue);
        expect(field.textFieldStyle?.valueStyle?.color, _kContentColor);
      },
    );
  });
}
