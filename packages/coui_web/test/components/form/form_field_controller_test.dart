import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Minimal stateful input that reports [value] to its enclosing `FormField`
/// via [FormValueSupplier] — stands in for a real input (Checkbox / Input /
/// …) to exercise the controlled-state glue end to end.
class _ReportingInput extends StatefulComponent {
  const _ReportingInput({this.value});

  final String? value;

  @override
  State<_ReportingInput> createState() => _ReportingInputState();
}

class _ReportingInputState extends State<_ReportingInput>
    with FormValueSupplier<String, _ReportingInput> {
  @override
  void initState() {
    super.initState();
    formValue = component.value;
  }

  @override
  void didReplaceFormValue(String value) {}

  @override
  Component build(BuildContext context) {
    return Component.element(tag: 'span', children: [Component.text('input')]);
  }
}

void main() {
  group('Web FormField + FormController glue (controlled-state parity)', () {
    testComponents('surfaces the validator error for a missing required '
        'value once the input reports it', (tester) async {
      final controller = FormController();
      const key = FormKey<String>('name');

      pumpWithTheme(
        tester,
        Form(
          controller: controller,
          children: const [
            FormField(
              label: 'Name',
              required: true,
              validator: RequiredValidator<String>(),
              formKey: key,
              child: _ReportingInput(),
            ),
          ],
        ),
      );

      // The input reports null on attach; the controller validates and
      // notifies on a microtask, which rebuilds the field with the error.
      await tester.pump();

      expect(find.text('This field cannot be empty'), findsOneComponent);
      expect(controller.getSyncError(key), isA<InvalidResult>());
    });

    testComponents('shows no error when the required value is present', (
      tester,
    ) async {
      final controller = FormController();
      const key = FormKey<String>('name');

      pumpWithTheme(
        tester,
        Form(
          controller: controller,
          children: const [
            FormField(
              label: 'Name',
              required: true,
              validator: RequiredValidator<String>(),
              formKey: key,
              child: _ReportingInput(value: 'Ada'),
            ),
          ],
        ),
      );

      await tester.pump();

      expect(find.text('This field cannot be empty'), findsNothing);
      expect(controller.getValue(key), 'Ada');
    });

    testComponents('a real Toggle reports its value to the controller', (
      tester,
    ) async {
      final controller = FormController();
      const key = FormKey<bool>('agree');

      pumpWithTheme(
        tester,
        Form(
          controller: controller,
          children: [
            FormField(
              label: 'Agree',
              formKey: key,
              child: Toggle(onChanged: (_) {}, value: true),
            ),
          ],
        ),
      );

      await tester.pump();

      expect(controller.getValue(key), isTrue);
      expect(controller.hasValue(key), isTrue);
    });

    testComponents('a real Checkbox reports its state to the controller', (
      tester,
    ) async {
      final controller = FormController();
      const key = FormKey<bool?>('terms');

      pumpWithTheme(
        tester,
        Form(
          controller: controller,
          children: [
            FormField(
              label: 'Terms',
              formKey: key,
              child: Checkbox(onChanged: (_) {}, checked: true),
            ),
          ],
        ),
      );

      await tester.pump();

      expect(controller.getValue(key), isTrue);
    });

    testComponents(
      'a real RadioGroup reports its selection to the controller',
      (tester) async {
        final controller = FormController();
        const key = FormKey<String>('plan');

        pumpWithTheme(
          tester,
          Form(
            controller: controller,
            children: [
              FormField(
                label: 'Plan',
                formKey: key,
                child: RadioGroup(
                  onChanged: (_) {},
                  value: 'pro',
                  options: const [
                    (value: 'basic', label: 'Basic'),
                    (value: 'pro', label: 'Pro'),
                  ],
                ),
              ),
            ],
          ),
        );

        await tester.pump();

        expect(controller.getValue(key), 'pro');
      },
    );

    testComponents(
      'a real PhoneInput reports its value to the controller',
      (tester) async {
        final controller = FormController();
        const key = FormKey<PhoneInputValue>('phone');

        pumpWithTheme(
          tester,
          Form(
            controller: controller,
            children: [
              FormField(
                label: 'Phone',
                formKey: key,
                child: PhoneInput(
                  onChanged: (_) {},
                  // Carries no dial code / trunk zero, so the number arrives
                  // untouched: this test is about the form plumbing, and the
                  // filter semantics are pinned in `core_phone_number_test`.
                  initialNumber: '5551234',
                ),
              ),
            ],
          ),
        );

        await tester.pump();

        final value = controller.getValue(key);
        expect(value, isA<PhoneInputValue>());
        expect(value!.number, '5551234');
      },
    );

    testComponents(
      'a real InputOtp reports its value to the controller',
      (tester) async {
        final controller = FormController();
        const key = FormKey<String>('otp');

        pumpWithTheme(
          tester,
          Form(
            controller: controller,
            children: const [
              FormField(
                label: 'Code',
                formKey: key,
                child: InputOtp(initialValue: '12', length: 4),
              ),
            ],
          ),
        );

        await tester.pump();

        expect(controller.getValue(key), '12');
      },
    );

    testComponents(
      'a real ObjectInput reports its values map to the controller',
      (tester) async {
        final controller = FormController();
        const key = FormKey<Map<String, String>>('date');

        pumpWithTheme(
          tester,
          Form(
            controller: controller,
            children: const [
              FormField(
                label: 'Date',
                formKey: key,
                child: ObjectInput(
                  fields: [
                    CoreObjectInputField(key: 'year', placeholder: 'YYYY'),
                    CoreObjectInputField(key: 'month', placeholder: 'MM'),
                  ],
                  values: {'year': '2026', 'month': '06'},
                ),
              ),
            ],
          ),
        );

        await tester.pump();

        expect(controller.getValue(key), {'year': '2026', 'month': '06'});
      },
    );
  });
}
