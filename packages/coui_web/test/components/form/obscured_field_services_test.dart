import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The attributes on the rendered `<input>`, which is where the browser's
/// text services are turned on or off.
Map<String, String> _inputAttrs(ComponentTester tester) {
  final input = find.tag('input').evaluate().single.component as DomComponent;

  return input.attributes ?? const {};
}

Map<String, String> _textareaAttrs(ComponentTester tester) {
  final area = find.tag('textarea').evaluate().single.component as DomComponent;

  return area.attributes ?? const {};
}

void main() {
  group('an obscured field opts out of the browser text services', () {
    testComponents('spellcheck, autocorrect and autocapitalize all go off', (
      tester,
    ) async {
      // Unlike Flutter, these default to *on* for a text input, so the
      // platform that needed the explicit statement was this one. The two
      // disagreed in the direction that leaks: Flutter's equivalents
      // default to off, so the same password field was quiet on one
      // platform and spell-checked on the other.
      pumpWithTheme(tester, TextField(obscureText: true));
      final attrs = _inputAttrs(tester);

      expect(attrs['spellcheck'], equals('false'));
      expect(attrs['autocorrect'], equals('off'));
      expect(attrs['autocapitalize'], equals('none'));
    });

    testComponents('a password type counts as obscured', (tester) async {
      pumpWithTheme(tester, TextField(type: CoreInputType.password));

      expect(_inputAttrs(tester)['spellcheck'], equals('false'));
    });

    testComponents('and it says what kind of field it is', (tester) async {
      // Without a hint the browser sees an input it cannot place and may
      // offer ordinary autofill and text services instead of a password
      // manager — the path this whole branch exists to close.
      pumpWithTheme(tester, TextField(obscureText: true));

      expect(_inputAttrs(tester)['autocomplete'], equals('current-password'));
    });

    testComponents('a stated hint is still the caller\'s', (tester) async {
      pumpWithTheme(
        tester,
        TextField(obscureText: true, autofillHints: const ['new-password']),
      );

      expect(_inputAttrs(tester)['autocomplete'], equals('new-password'));
    });

    testComponents('and a stated capitalization does not get back in', (
      tester,
    ) async {
      // The emission order matters: capitalization is written later from
      // its own field, and would have overwritten the `none` above.
      pumpWithTheme(
        tester,
        TextField(obscureText: true, textCapitalization: 'characters'),
      );

      expect(_inputAttrs(tester)['autocapitalize'], equals('none'));
    });
  });

  group('a plain field is left to the browser', () {
    testComponents('no text-service attributes are emitted', (tester) async {
      // Null means "let the platform decide". Emitting `spellcheck="true"`
      // here would be stating a default the browser already has, and
      // would make the attribute stop meaning "someone decided this".
      pumpWithTheme(tester, TextField());
      final attrs = _inputAttrs(tester);

      expect(attrs.containsKey('spellcheck'), isFalse);
      expect(attrs.containsKey('autocorrect'), isFalse);
      expect(attrs.containsKey('autocapitalize'), isFalse);
    });

    testComponents('and a stated autocorrect is taken at its word', (
      tester,
    ) async {
      pumpWithTheme(tester, TextField(autocorrect: false));

      expect(_inputAttrs(tester)['autocorrect'], equals('off'));
    });
  });

  group('a text area states what it was given', () {
    testComponents('autocorrect reaches the element', (tester) async {
      // It did not before. A comment in this file claimed the mapping
      // while nothing emitted it, which is the failure that hides best:
      // a reader checking where a text area's contents can reach would
      // have stopped at the comment and found an answer.
      pumpWithTheme(tester, TextArea(autocorrect: false));

      expect(_textareaAttrs(tester)['autocorrect'], equals('off'));
    });

    testComponents('and says nothing when nothing was stated', (tester) async {
      pumpWithTheme(tester, TextArea());

      expect(_textareaAttrs(tester).containsKey('autocorrect'), isFalse);
    });

    testComponents('the keyboard hints reach the element', (tester) async {
      pumpWithTheme(
        tester,
        TextArea(
          keyboardType: 'text',
          textInputAction: 'done',
          textCapitalization: 'sentences',
        ),
      );
      final attrs = _textareaAttrs(tester);

      expect(attrs['inputmode'], equals('text'));
      expect(attrs['enterkeyhint'], equals('done'));
      expect(attrs['autocapitalize'], equals('sentences'));
    });
  });

  group('an obscured text area opts out too', () {
    testComponents('spellcheck, autocorrect and autocapitalize all go off', (
      tester,
    ) async {
      // A `<textarea>` can be masked — `-webkit-text-security` is the
      // browser's surface for it — so the same leak the single-line field
      // had is possible here, and the same three services close it.
      pumpWithTheme(tester, TextArea(obscureText: true));
      final attrs = _textareaAttrs(tester);

      expect(attrs['spellcheck'], equals('false'));
      expect(attrs['autocorrect'], equals('off'));
      expect(attrs['autocapitalize'], equals('none'));
    });

    testComponents('and a stated capitalization does not get back in', (
      tester,
    ) async {
      // The emission order matters: capitalization is written later from
      // its own field, and would have overwritten the `none` above.
      pumpWithTheme(
        tester,
        TextArea(obscureText: true, textCapitalization: 'characters'),
      );

      expect(_textareaAttrs(tester)['autocapitalize'], equals('none'));
    });

    testComponents('and reports the services off on the contract as well', (
      tester,
    ) async {
      // Nothing on the web reads these — a `<textarea>` has no per-element
      // switch — but the two platforms must not state different values for
      // the same field, and Flutter's effective value is `false`.
      const area = TextArea(obscureText: true);

      expect(area.enableSuggestions, isFalse);
      expect(area.enableIMEPersonalizedLearning, isFalse);
    });
  });
}
