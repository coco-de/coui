import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

void main() {
  group('FormController + FormField validation', () {
    testWidgets('surfaces the validator error for a missing required value', (
      tester,
    ) async {
      final controller = FormController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          Form(
            controller: controller,
            children: const [
              FormField(
                label: 'Choice',
                validator: RequiredValidator<String>(message: 'Required'),
                child: _ReportingField(value: null),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The field reported `null` to the form handle, which ran the
      // validator through the controller and surfaced the result as the
      // field's error.
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('clears the error once a value is supplied', (tester) async {
      final controller = FormController();
      addTearDown(controller.dispose);

      Widget build(String? value) => _app(
        Form(
          controller: controller,
          children: [
            FormField(
              validator: const RequiredValidator<String>(message: 'Required'),
              child: _ReportingField(value: value),
            ),
          ],
        ),
      );

      await tester.pumpWidget(build(null));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);

      await tester.pumpWidget(build('hello'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsNothing);
    });

    testWidgets('collects field values into the controller by FormKey', (
      tester,
    ) async {
      final controller = FormController();
      addTearDown(controller.dispose);
      const key = FormKey<String>('name');

      await tester.pumpWidget(
        _app(
          Form(
            controller: controller,
            children: const [
              FormField(
                formKey: key,
                child: _ReportingField(value: 'Ada'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.getValue(key), 'Ada');
    });
  });
}

/// Minimal form input that reports a [String] value to the ambient
/// [FormFieldHandle] via [FormValueSupplier] — stands in for real inputs
/// (Checkbox / RadioGroup / …) so the controller↔field wiring can be tested
/// in isolation.
class _ReportingField extends material.StatefulWidget {
  const _ReportingField({required this.value});

  final String? value;

  @override
  material.State<_ReportingField> createState() => _ReportingFieldState();
}

class _ReportingFieldState extends material.State<_ReportingField>
    with FormValueSupplier<String, _ReportingField> {
  @override
  void initState() {
    super.initState();
    formValue = widget.value;
  }

  @override
  void didUpdateWidget(_ReportingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      formValue = widget.value;
    }
  }

  @override
  void didReplaceFormValue(String value) {}

  @override
  material.Widget build(material.BuildContext context) =>
      const material.SizedBox.shrink();
}
