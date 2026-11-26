// The DatePicker trigger wears the shared input look: a composed read-only
// `TextField` (height 40 · corner 10 · outlineVariant edge from the field's
// own `md` row) whose focus edge is `primary`, or `error` while the picker
// holds an error. Mirrors the Flutter twin.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

void main() {
  group('the DatePicker trigger look', () {
    testComponents('the field states the error edge; focus is its own row', (
      tester,
    ) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((c) => context = c));

      final resolved = resolveDatePicker(context);

      expect(
        resolved.triggerStyle.errorBorderColor,
        const CoreColor.token(CoreColors.error),
      );
      // The button-era shared chrome is no longer the trigger's.
      expect(resolved.popoverStyle?.triggerStyle, isNull);
      // The picker states the pressed-only state layer, nothing else.
      expect(
        resolved.triggerStyle.stateLayer,
        CoreDatePickerStyle.defaultTriggerStyle.stateLayer,
      );
    });

    testComponents('the trigger is one read-only TextField, not a Button', (
      tester,
    ) async {
      pumpWithTheme(tester, DatePicker(onChanged: (_) {}));

      final field =
          find.byType(TextField).evaluate().single.component as TextField;
      expect(field.readOnly, isTrue);
      expect(field.suffix, isA<Icon>());
      expect(find.byType(Button), findsNothing);
    });

    testComponents('the range trigger is the same read-only TextField', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DateRangePicker(value: (start: '2024-01-15', end: '2024-01-20')),
      );

      final field =
          find.byType(TextField).evaluate().single.component as TextField;
      expect(field.readOnly, isTrue);
      expect(field.value, '2024-01-15 - 2024-01-20');
      expect(find.byType(Button), findsNothing);
    });
  });
}
