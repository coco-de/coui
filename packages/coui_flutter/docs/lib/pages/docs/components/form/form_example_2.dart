import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart';

class FormExample2 extends StatefulWidget {
  const FormExample2({super.key});

  @override
  State<FormExample2> createState() => _FormExample2State();
}

class _FormExample2State extends State<FormExample2> {
  final _usernameKey = const TextFieldKey(#username);
  final _passwordKey = const TextFieldKey(#password);
  final _confirmPasswordKey = const TextFieldKey(#confirmPassword);
  final _agreeKey = const CheckboxKey(#agree);
  CheckboxState state = CheckboxState.unchecked;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormField(
                  hint: const Text('This is your public display name'),
                  key: _usernameKey,
                  label: const Text('Username'),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const LengthValidator(min: 4),
                  child: const TextField(),
                ),
                FormField(
                  key: _passwordKey,
                  label: const Text('Password'),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const LengthValidator(min: 8),
                  child: const TextField(obscureText: true),
                ),
                FormField(
                  key: _confirmPasswordKey,
                  label: const Text('Confirm Password'),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: CompareWith.equal(
                    _passwordKey,
                    message: 'Passwords do not match',
                  ),
                  child: const TextField(obscureText: true),
                ),
                FormInline(
                  key: _agreeKey,
                  label: const Text('I agree to the terms and conditions'),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const CompareTo.equal(
                    CheckboxState.checked,
                    message: 'You must agree to the terms and conditions',
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Checkbox(
                      onChanged: (value) {
                        setState(() {
                          state = value;
                        });
                      },
                      state: state,
                    ),
                  ),
                ),
              ],
            ).gap(24),
            const Gap(24),
            FormErrorBuilder(
              builder: (context, errors, child) {
                return PrimaryButton(
                  onPressed: errors.isEmpty ? () => context.submitForm() : null,
                  child: const Text('Submit'),
                );
              },
            ),
          ],
        ),
        onSubmit: (context, values) {
          // Get the values individually
          String? username = _usernameKey[values];
          String? password = _passwordKey[values];
          String? confirmPassword = _confirmPasswordKey[values];
          CheckboxState? agree = _agreeKey[values];
          // or just encode the whole map to JSON directly
          String json = jsonEncode(
            values.map((key, value) {
              return MapEntry(key.key, value);
            }),
          );
          showDialog(
            builder: (context) {
              return AlertDialog(
                actions: [
                  PrimaryButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Username: $username'),
                    Text('Password: $password'),
                    Text('Confirm Password: $confirmPassword'),
                    Text('Agree: $agree'),
                    Text('JSON: $json'),
                  ],
                ),
                title: const Text('Form Values'),
              );
            },
            context: context,
          );
        },
      ),
    );
  }
}
