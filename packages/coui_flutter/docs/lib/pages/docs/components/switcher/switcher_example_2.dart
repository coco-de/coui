import 'package:coui_flutter/coui_flutter.dart';

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
                  label: const Text('Email'),
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
                const FormField(
                  key: TextFieldKey(#password),
                  label: Text('Password'),
                  showErrors: {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: NotEmptyValidator(),
                  child: TextField(obscureText: true),
                ),
                const SubmitButton(child: Text('Login')),
                const Text('Don\'t have an account? ').thenButton(
                  child: const Text('Sign Up!'),
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
                  label: const Text('Email'),
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
                const FormField(
                  key: TextFieldKey(#password),
                  label: Text('Password'),
                  showErrors: {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: LengthValidator(
                    message: 'Password must be at least 6 characters',
                    min: 6,
                  ),
                  child: TextField(obscureText: true),
                ),
                const FormField(
                  key: TextFieldKey(#confirmPassword),
                  label: Text('Confirm Password'),
                  showErrors: {
                    FormValidationMode.changed,
                    FormValidationMode.submitted,
                  },
                  validator: CompareWith.equal(
                    TextFieldKey(#password),
                    message: 'Passwords do not match',
                  ),
                  child: TextField(obscureText: true),
                ),
                const SubmitButton(child: Text('Register')),
                const Text('Already have an account? ').thenButton(
                  child: const Text('Login!'),
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
