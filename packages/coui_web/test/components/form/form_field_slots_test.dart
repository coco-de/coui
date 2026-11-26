import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Web twin of the `labelAction` / `counterText` group in Flutter's
/// `form_field_test.dart` — the same claims, checked on this platform.
///
/// Both files pin the one thing that is easy to get wrong in either
/// direction: the counter holds the footer open BY ITSELF (a length-capped
/// field with nothing else to say still shows its tally), and an error
/// still outranks the description beside it.
void main() {
  group('FormField labelAction / counterText', () {
    testComponents('labelAction renders beside the label', (tester) async {
      pumpWithTheme(
        tester,
        const FormField(
          label: 'Password',
          labelAction: Text('Forgot password?'),
          child: Text('input'),
        ),
      );

      expect(find.text('Password'), findsOneComponent);
      expect(find.text('Forgot password?'), findsOneComponent);
    });

    testComponents('counterText renders in the footer', (tester) async {
      pumpWithTheme(
        tester,
        const FormField(
          label: 'Bio',
          counterText: '0 / 20',
          child: Text('input'),
        ),
      );

      expect(find.text('0 / 20'), findsOneComponent);
    });

    // The footer used to collapse on "no error and no description", and a
    // length-capped field with nothing else to say is exactly that case —
    // the tally would have gone with them.
    testComponents('counter alone keeps the footer from collapsing', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FormField(
          label: 'Bio',
          counterText: '12 / 20',
          child: Text('input'),
        ),
      );

      expect(find.text('12 / 20'), findsOneComponent);
    });

    testComponents('counter sits alongside a description', (tester) async {
      pumpWithTheme(
        tester,
        const FormField(
          label: 'Bio',
          description: 'Tell us about yourself.',
          counterText: '0 / 20',
          child: Text('input'),
        ),
      );

      expect(find.text('Tell us about yourself.'), findsOneComponent);
      expect(find.text('0 / 20'), findsOneComponent);
    });

    // `error` outranks `description` — that predates this change, and the
    // counter must not have quietly resurrected the description beside it.
    testComponents('error still hides the description, counter still shows', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FormField(
          label: 'Bio',
          description: 'Tell us about yourself.',
          error: 'Too long.',
          counterText: '21 / 20',
          child: Text('input'),
        ),
      );

      expect(find.text('Too long.'), findsOneComponent);
      expect(find.text('Tell us about yourself.'), findsNothing);
      expect(find.text('21 / 20'), findsOneComponent);
    });

    testComponents('neither slot given leaves the field as it was', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FormField(label: 'Plain', child: Text('input')),
      );

      expect(find.text('Plain'), findsOneComponent);
    });
  });
}
