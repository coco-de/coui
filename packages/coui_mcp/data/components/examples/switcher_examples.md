# Switcher Examples

This document contains example code for the switcher component.

## Table of Contents

- [Example 1: Basic Example](#example-1)
- [Example 2: Variant Example](#example-2)

## Example 1

**Basic Example**

```dart
import 'package:docs/pages/docs/components/carousel_example.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class SwitcherExample1 extends StatefulWidget {
  const SwitcherExample1({super.key});

  @override
  State<SwitcherExample1> createState() => _SwitcherExample1State();
}

class _SwitcherExample1State extends State<SwitcherExample1> {
  List<AxisDirection> directions = const [
    AxisDirection.up,
    AxisDirection.down,
    AxisDirection.left,
    AxisDirection.right,
  ];
  List<Size> sizes = const [Size(200, 300), Size(300, 200)];
  int directionIndex = 0;
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          child: Text(
            '${t.docs.components.switcher.switch_direction} (${directions[directionIndex % directions.length]})',
          ),
          onPressed: () {
            setState(() {
              directionIndex++;
            });
          },
        ),
        gap(8),
        PrimaryButton(
          child: Text(t.docs.components.switcher.next_item),
          onPressed: () {
            setState(() {
              index++;
            });
          },
        ),
        gap(24),
        ClipRect(
          child: Switcher(
            direction: directions[directionIndex % directions.length],
            index: index,
            onIndexChanged: (index) {
              setState(() {
                this.index = index;
              });
            },
            children: [
              for (int i = 0; i < 100; i++)
                NumberedContainer(
                  index: i,
                  width: sizes[i % sizes.length].width,
                  height: sizes[i % sizes.length].height,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

```

## Example 2

**Variant Example**

```dart
import 'package:coui_flutter/coui_flutter.dart';
import 'package:i10n/i10n.dart';

class SwitcherExample2 extends StatefulWidget {
  const SwitcherExample2({super.key});

  @override
  State<SwitcherExample2> createState() => _SwitcherExample2State();
}

class _SwitcherExample2State extends State<SwitcherExample2> {
  bool _isRegister = false;
  final _registerController = FormController();
  final _loginController = FormController();
  @override
  Widget build(BuildContext context) {
    return Switcher(
      direction: AxisDirection.left,
      index: _isRegister ? 1 : 0,
      onIndexChanged: (index) {
        setState(() {
          _isRegister = index == 1;
        });
      },
      children: [
        Container(
          key: const Key('login'),
          padding: const EdgeInsets.all(16),
          width: 350,
          child: Form(
            controller: _loginController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                FormField(
                  key: const TextFieldKey(#email),
                  label: Text(t.docs.components.form.email),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const EmailValidator() & const NotEmptyValidator(),
                  child: TextField(
                    autocorrect: false,
                    enableSuggestions: false,
                    initialValue: _loginController.getValue(
                      const TextFieldKey(#email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                FormField(
                  key: const TextFieldKey(#password),
                  label: Text(t.docs.components.form.password_label),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const NotEmptyValidator(),
                  child: const TextField(obscureText: true),
                ),
                SubmitButton(child: Text(t.docs.components.form.login)),
                Text(t.docs.components.form.dont_have_account).thenLink(
                  href: '#register',
                  text: t.docs.components.form.sign_up,
                  onPressed: () {
                    setState(() {
                      _isRegister = true;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        Container(
          key: const Key('register-form'),
          padding: const EdgeInsets.all(16),
          width: 350,
          child: Form(
            controller: _registerController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                FormField(
                  key: const TextFieldKey(#email),
                  label: Text(t.docs.components.form.email),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const EmailValidator() & const NotEmptyValidator(),
                  child: TextField(
                    autocorrect: false,
                    enableSuggestions: false,
                    initialValue: _registerController.getValue(
                      const TextFieldKey(#email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                FormField(
                  key: const TextFieldKey(#password),
                  label: Text(t.docs.components.form.password_label),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const LengthValidator(
                    message: 'Password must be at least 6 characters',
                    min: 6,
                  ),
                  child: const TextField(obscureText: true),
                ),
                FormField(
                  key: const TextFieldKey(#confirmPassword),
                  label: Text(t.docs.components.form.confirm_password_label),
                  showErrors: const {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: const CompareWith.equal(
                    TextFieldKey(#password),
                    message: 'Passwords do not match',
                  ),
                  child: const TextField(obscureText: true),
                ),
                SubmitButton(child: Text(t.docs.components.form.register)),
                Text(t.docs.components.form.already_have_account).thenLink(
                  href: '#login',
                  text: t.docs.components.form.login,
                  onPressed: () {
                    setState(() {
                      _isRegister = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

```

