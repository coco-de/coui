# Form Examples

This document contains example code for the form component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)
- [Example 3: Custom Example](#example-3)

## Example 1

**Basic Example**

```dart
import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class FormExample1 extends StatefulWidget {
  const FormExample1({super.key});

  @override
  State<FormExample1> createState() => _FormExample1State();
}

class _FormExample1State extends State<FormExample1> {
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
                  hint: Text(t.docs.components.form.username_hint),
                  key: _usernameKey,
                  label: Text(t.docs.components.form.username_label),
                  validator: const LengthValidator(min: 4),
                  child: const TextField(initialValue: 'coco-de'),
                ),
                FormField(
                  key: _passwordKey,
                  label: Text(t.docs.components.form.password_label),
                  validator: const LengthValidator(min: 8),
                  child: const TextField(obscureText: true),
                ),
                FormField(
                  key: _confirmPasswordKey,
                  label: Text(t.docs.components.form.confirm_password_label),
                  validator: CompareWith.equal(
                    _passwordKey,
                    message: t.docs.components.form.passwords_do_not_match,
                  ),
                  child: const TextField(obscureText: true),
                ),
              ],
            ),
            const Gap(size: 24),
            FormErrorBuilder(
              builder: (context, errors, child) {
                return PrimaryButton(
                  onPressed: errors.isEmpty ? () => context.submitForm() : null,
                  child: Text(t.docs.components.button.submit),
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
                    child: Text(t.docs.components.button.close),
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
                    Text('JSON: $json'),
                  ],
                ),
                title: Text(t.docs.components.form.form_values_title),
              );
            },
            context: context,
          );
        },
      ),
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

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
                  hint: Text(t.docs.components.form.username_hint),
                  key: _usernameKey,
                  label: Text(t.docs.components.form.username_label),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const LengthValidator(min: 4),
                  child: const TextField(),
                ),
                FormField(
                  key: _passwordKey,
                  label: Text(t.docs.components.form.password_label),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const LengthValidator(min: 8),
                  child: const TextField(obscureText: true),
                ),
                FormField(
                  key: _confirmPasswordKey,
                  label: Text(t.docs.components.form.confirm_password_label),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: CompareWith.equal(
                    _passwordKey,
                    message: t.docs.components.form.passwords_do_not_match,
                  ),
                  child: const TextField(obscureText: true),
                ),
                FormInline(
                  key: _agreeKey,
                  label: Text(t.docs.components.form.agree_terms),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: CompareTo.equal(
                    CheckboxState.checked,
                    message: t.docs.components.form.must_agree_terms,
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
            const Gap(size: 24),
            FormErrorBuilder(
              builder: (context, errors, child) {
                return PrimaryButton(
                  onPressed: errors.isEmpty ? () => context.submitForm() : null,
                  child: Text(t.docs.components.button.submit),
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
                    child: Text(t.docs.components.button.close),
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
                title: Text(t.docs.components.form.form_values_title),
              );
            },
            context: context,
          );
        },
      ),
    );
  }
}

```

## Example 3

**Custom Example**

```dart
import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

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
                  hint: Text(t.docs.components.form.username_hint),
                  key: _usernameKey,
                  label: Text(t.docs.components.form.username_label),
                  validator: const LengthValidator(min: 4) &
                      ValidationMode(
                        ConditionalValidator(
                          (value) async {
                            // simulate a network delay for example purpose
                            await Future.delayed(const Duration(seconds: 1));
                            return !_dummyData.contains(value);
                          },
                          message:
                              t.docs.components.form.username_already_taken,
                        ),
                        // only validate when the form is submitted
                        mode: {FormValidationMode.submitted},
                      ),
                  child: const TextField(initialValue: 'coco-de'),
                ),
                FormField(
                  key: _passwordKey,
                  label: Text(t.docs.components.form.password_label),
                  showErrors: const {
                    FormValidationMode.submitted,
                    FormValidationMode.changed,
                  },
                  validator: const LengthValidator(min: 8),
                  child: const TextField(obscureText: true),
                ),
                FormField<String>(
                  key: _confirmPasswordKey,
                  label: Text(t.docs.components.form.confirm_password_label),
                  showErrors: const {
                    FormValidationMode.submitted,
                    FormValidationMode.changed,
                  },
                  validator: CompareWith.equal(
                    _passwordKey,
                    message: t.docs.components.form.passwords_do_not_match,
                  ),
                  child: const TextField(obscureText: true),
                ),
              ],
            ),
            const Gap(size: 24),
            SubmitButton(
              loadingTrailing: const AspectRatio(
                aspectRatio: 1,
                child: CircularProgressIndicator(onSurface: true),
              ),
              child: Text(t.docs.components.form.register),
            ),
          ],
        ),
        onSubmit: (context, values) {
          showDialog(
            builder: (context) {
              return AlertDialog(
                actions: [
                  PrimaryButton(
                    child: Text(t.docs.components.button.close),
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
                title: Text(t.docs.components.form.form_values_title),
              );
            },
            context: context,
          );
        },
      ),
    );
  }
}

```

