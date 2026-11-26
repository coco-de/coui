/// Jaspr (coui_web) screen pattern templates.
///
/// Mirrors the Flutter patterns in `PatternGenerator`. Currently supports
/// `login`, `form`, and `dashboard` end-to-end; other patterns return null
/// so the caller can fall back to the Flutter target.
class JasprPatternTemplates {
  /// Generates Jaspr code for a named pattern. Returns `null` if the
  /// pattern is not yet supported on Jaspr (caller should fall back).
  static String? generate(String patternName, Map<String, dynamic> custom) {
    switch (patternName.toLowerCase()) {
      case 'login':
        return _login(custom);
      case 'form':
        return _form(custom);
      case 'dashboard':
        return _dashboard(custom);
      default:
        return null;
    }
  }

  static String _login(Map<String, dynamic> custom) {
    final title = custom['title'] as String? ?? 'Login';
    final showSocialLogin = custom['social_login'] as bool? ?? false;

    return """
import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart';

class LoginScreen extends StatefulComponent {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _email = '';
  String _password = '';

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield div(
      classes: 'min-h-screen flex items-center justify-center p-6',
      [
        Card(
          header: text('$title'),
          body: div(classes: 'space-y-4 w-full max-w-sm', [
            TextField(
              variant: CoreTextFieldVariant.defaultVariant,
              placeholder: 'Email',
              onChanged: (v) => setState(() => _email = v),
            ),
            TextField(
              variant: CoreTextFieldVariant.defaultVariant,
              placeholder: 'Password',
              obscureText: true,
              onChanged: (v) => setState(() => _password = v),
            ),
            div(classes: 'text-right', [
              Button.link(
                onPressed: () {
                  // TODO: Navigate to forgot password
                },
                child: text('Forgot password?'),
              ),
            ]),
          ]),
          footer: div(classes: 'space-y-3 w-full', [
            Button.primary(
              onPressed: _handleLogin,
              child: text('Login'),
            ),${showSocialLogin ? """
            div(classes: 'flex items-center gap-2', [
              div(classes: 'flex-1 border-t', []),
              span(classes: 'text-sm', [text('OR')]),
              div(classes: 'flex-1 border-t', []),
            ]),
            Button.outline(
              onPressed: () {
                // TODO: Google login
              },
              child: text('Continue with Google'),
            ),""" : ''}
            div(classes: 'text-center text-sm', [
              text("Don't have an account? "),
              Button.link(
                onPressed: () {
                  // TODO: Navigate to signup
                },
                child: text('Sign up'),
              ),
            ]),
          ]),
        ),
      ],
    );
  }

  void _handleLogin() {
    // TODO: Implement login logic with _email and _password
  }
}
""";
  }

  static String _form(Map<String, dynamic> custom) {
    final formTitle = custom['title'] as String? ?? 'Form';
    return """
import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart';

class ${_pascal(formTitle)}Form extends StatefulComponent {
  const ${_pascal(formTitle)}Form({super.key});

  @override
  State<${_pascal(formTitle)}Form> createState() => _${_pascal(formTitle)}FormState();
}

class _${_pascal(formTitle)}FormState extends State<${_pascal(formTitle)}Form> {
  final Map<String, String> _values = {};

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield div(classes: 'max-w-md mx-auto p-6 space-y-4', [
      h1(classes: 'text-2xl font-bold', [text('$formTitle')]),
      // TODO: Add form fields here, e.g.:
      // TextField(
      //   variant: CoreTextFieldVariant.defaultVariant,
      //   placeholder: 'Field name',
      //   onChanged: (v) => setState(() => _values['field'] = v),
      // ),
      div(classes: 'flex gap-2 justify-end pt-4', [
        Button.ghost(
          onPressed: () => setState(() => _values.clear()),
          child: text('Reset'),
        ),
        Button.primary(
          onPressed: _handleSubmit,
          child: text('Submit'),
        ),
      ]),
    ]);
  }

  void _handleSubmit() {
    // TODO: Submit \$_values
  }
}
""";
  }

  static String _dashboard(Map<String, dynamic> custom) {
    final title = custom['title'] as String? ?? 'Dashboard';
    return """
import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart';

class DashboardScreen extends StatelessComponent {
  const DashboardScreen({super.key});

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield div(classes: 'min-h-screen p-6 space-y-6', [
      h1(classes: 'text-3xl font-bold', [text('$title')]),
      div(classes: 'grid grid-cols-1 md:grid-cols-3 gap-4', [
        _statCard('Users', '1,234'),
        _statCard('Revenue', '\\\$12,345'),
        _statCard('Growth', '+12%'),
      ]),
      Card(
        header: text('Recent Activity'),
        body: div(classes: 'space-y-2', [
          // TODO: Render activity items
        ]),
      ),
    ]);
  }

  Component _statCard(String label, String value) {
    return Card(
      body: div(classes: 'p-4', [
        p(classes: 'text-sm opacity-70', [text(label)]),
        p(classes: 'text-2xl font-bold', [text(value)]),
      ]),
    );
  }
}
""";
  }

  static String _pascal(String text) {
    return text
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join();
  }
}
