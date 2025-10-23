import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart';

class FormExample3 extends StatefulWidget {
  const FormExample3({super.key});

  @override
  State<FormExample3> createState() => _FormExample3State();
}

class _FormExample3State extends State<FormExample3> {
  final _dummyData = ['coco-de', 'septogeddon', 'coui'];

  final _usernameKey = const TextFieldKey('username');
  final _passwordKey = const TextFieldKey('password');
  final _confirmPasswordKey = const TextFieldKey('confirmPassword');
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FormTableLayout(
              rows: [
                FormField(
                  hint: const Text('This is your public display name'),
                  key: _usernameKey,
                  label: const Text('Username'),
                  validator: const LengthValidator(min: 4) &
                      ValidationMode(
                        ConditionalValidator((value) async {
                          // simulate a network delay for example purpose
                          await Future.delayed(const Duration(seconds: 1));
                          return !_dummyData.contains(value);
                        }, message: 'Username already taken'),
                        // only validate when the form is submitted
                        mode: {FormValidationMode.submitted},
                      ),
                  child: const TextField(initialValue: 'coco-de'),
                ),
                FormField(
                  key: _passwordKey,
                  label: const Text('Password'),
                  showErrors: const {
                    FormValidationMode.submitted,
                    FormValidationMode.changed,
                  },
                  validator: const LengthValidator(min: 8),
                  child: const TextField(obscureText: true),
                ),
                FormField<String>(
                  key: _confirmPasswordKey,
                  label: const Text('Confirm Password'),
                  showErrors: const {
                    FormValidationMode.submitted,
                    FormValidationMode.changed,
                  },
                  validator: CompareWith.equal(
                    _passwordKey,
                    message: 'Passwords do not match',
                  ),
                  child: const TextField(obscureText: true),
                ),
              ],
            ),
            const Gap(24),
            const SubmitButton(
              loadingTrailing: AspectRatio(
                aspectRatio: 1,
                child: CircularProgressIndicator(onSurface: true),
              ),
              child: Text('Register'),
            ),
          ],
        ),
        onSubmit: (context, values) {
          showDialog(
            builder: (context) {
              return AlertDialog(
                actions: [
                  PrimaryButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
                content: Text(
                  jsonEncode(
                    values.map((key, value) {
                      return MapEntry(key.key, value);
                    }),
                  ),
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
