import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `EditableText` a field or area builds, which is where the three
/// input-service flags actually land.
EditableText _editableIn(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 320, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('an obscured field reaches no text service', () {
    testWidgets('even when the caller states a spell check config', (
      tester,
    ) async {
      // The leak in its plainest form. A caller that configures spell
      // check and obscures the same field sends the password to the
      // platform's checker, and the field renders identically either way
      // — so there is nothing to notice.
      await _pump(
        tester,
        TextField(
          obscureText: true,
          spellCheckConfiguration: SpellCheckConfiguration(),
        ),
      );

      expect(
        _editableIn(tester).spellCheckConfiguration,
        const SpellCheckConfiguration.disabled(),
      );
    });

    testWidgets('and states nothing to the keyboard either', (tester) async {
      // Autocorrect and suggestions are the same leak with a longer
      // memory: they hand the text to the keyboard's dictionary, where it
      // can resurface in another app's field.
      await _pump(tester, TextField(obscureText: true));
      final editable = _editableIn(tester);

      expect(editable.autocorrect, isFalse);
      expect(editable.enableSuggestions, isFalse);
      expect(editable.enableIMEPersonalizedLearning, isFalse);
    });

    testWidgets('a password type counts as obscured', (tester) async {
      // `obscureText` is not the only way in. A password type obscures
      // too, and a gate keyed on the parameter rather than the state
      // misses every field written this way.
      await _pump(tester, TextField(type: CoreInputType.password));
      final editable = _editableIn(tester);

      expect(editable.obscureText, isTrue);
      expect(editable.autocorrect, isFalse);
      expect(editable.enableSuggestions, isFalse);
      expect(editable.enableIMEPersonalizedLearning, isFalse);
    });

    testWidgets('and a caller that asks for them anyway does not get them', (
      tester,
    ) async {
      // Stating `true` is not a way around it. The field's contents are
      // the reason, and the caller does not know better than that.
      await _pump(
        tester,
        TextField(
          obscureText: true,
          autocorrect: true,
          enableSuggestions: true,
          enableIMEPersonalizedLearning: true,
        ),
      );
      final editable = _editableIn(tester);

      expect(editable.autocorrect, isFalse);
      expect(editable.enableSuggestions, isFalse);
      expect(editable.enableIMEPersonalizedLearning, isFalse);
    });
  });

  group('an obscured field capitalises nothing', () {
    // Not a leak but the same rule: what is masked is a password, and a
    // keyboard that capitalises its first letter has typed something the
    // person did not. The Web twin forces `autocapitalize` off; the contract
    // says masking wins on both platforms.
    testWidgets('whatever a field is told', (tester) async {
      await _pump(
        tester,
        TextField(obscureText: true, textCapitalization: .words),
      );

      expect(_editableIn(tester).textCapitalization, TextCapitalization.none);
    });

    testWidgets('and a password type counts', (tester) async {
      await _pump(
        tester,
        TextField(type: CoreInputType.password, textCapitalization: .words),
      );

      expect(_editableIn(tester).textCapitalization, TextCapitalization.none);
    });

    testWidgets('and neither does an area', (tester) async {
      await _pump(
        tester,
        // `EditableText` only masks a single line, so the area is one row.
        TextArea(obscureText: true, rows: 1, textCapitalization: .words),
      );

      expect(_editableIn(tester).textCapitalization, TextCapitalization.none);
    });

    testWidgets('revealing gives back what was stated, hiding takes it', (
      tester,
    ) async {
      await _pump(
        tester,
        TextField(
          obscureText: true,
          textCapitalization: .words,
          features: const [CoreInputFeature.passwordToggle()],
        ),
      );
      expect(_editableIn(tester).textCapitalization, TextCapitalization.none);

      final toggle = find.byType(Button);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(_editableIn(tester).obscureText, isFalse);
      expect(_editableIn(tester).textCapitalization, TextCapitalization.words);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(_editableIn(tester).textCapitalization, TextCapitalization.none);
    });
  });

  group('the reveal toggle carries the services with it', () {
    testWidgets('revealed lets them back on, re-hiding takes them away', (
      tester,
    ) async {
      // The state the gate is keyed on flips at runtime, so a check that
      // only ever reads the first build proves nothing about the field a
      // user actually types into. Both directions are here because the
      // dangerous one is the second: a field the user re-hides has to
      // stop from that moment, and an implementation that computed this
      // once at init would pass the first half and fail the second.
      await _pump(
        tester,
        TextField(
          obscureText: true,
          features: [CoreInputFeature.passwordToggle()],
        ),
      );

      expect(_editableIn(tester).autocorrect, isFalse);

      final toggle = find.byType(Button);
      expect(toggle, findsOneWidget, reason: 'no reveal affordance rendered');

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(
        _editableIn(tester).obscureText,
        isFalse,
        reason: 'the toggle did not reveal, so the rest proves nothing',
      );
      expect(
        _editableIn(tester).autocorrect,
        isTrue,
        reason: 'revealing did not let the services back on',
      );

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(_editableIn(tester).obscureText, isTrue);
      expect(_editableIn(tester).autocorrect, isFalse);
      expect(_editableIn(tester).enableSuggestions, isFalse);
      expect(_editableIn(tester).enableIMEPersonalizedLearning, isFalse);
    });
  });

  group('a plain field is left alone', () {
    testWidgets('nothing is turned off', (tester) async {
      await _pump(tester, TextField());
      final editable = _editableIn(tester);

      expect(editable.autocorrect, isTrue);
      expect(editable.enableSuggestions, isTrue);
      expect(editable.enableIMEPersonalizedLearning, isTrue);
    });

    testWidgets('and a stated value is taken at its word', (tester) async {
      await _pump(tester, TextField(autocorrect: false));

      expect(_editableIn(tester).autocorrect, isFalse);
    });

    testWidgets('and so is a stated capitalisation, in a field and an area', (
      tester,
    ) async {
      await _pump(tester, TextField(textCapitalization: .sentences));
      expect(
        _editableIn(tester).textCapitalization,
        TextCapitalization.sentences,
      );

      await _pump(tester, TextArea(textCapitalization: .words));
      expect(_editableIn(tester).textCapitalization, TextCapitalization.words);
    });
  });

  group("the platform's own inference runs again", () {
    // The half that is easy to lose while fixing the other half, and the
    // one no obscured-field check can see. `EditableText` turns
    // autocorrect off for a username or password autofill hint on iOS —
    // and it does that only when it receives null. Stating `true` was
    // silently replacing a behaviour the framework already shipped.
    //
    // A username field is the case that proves it: password-related to
    // the platform, but not obscured, so the gate above never touches it.
    // Every other test here would pass with the inference still dead.
    // Reset inside the body, not in `tearDown` — the binding checks the
    // foundation debug variables before tearDown runs and fails the test
    // for leaving one set.
    testWidgets('a username field stops autocorrecting on iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await _pump(
          tester,
          TextField(autofillHints: const [AutofillHints.username]),
        );

        expect(_editableIn(tester).autocorrect, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('and a caller that states otherwise still wins', (
      tester,
    ) async {
      // Null means "decide for me", not "ignore me". A stated value is
      // still the caller's to make.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await _pump(
          tester,
          TextField(
            autocorrect: true,
            autofillHints: const [AutofillHints.username],
          ),
        );

        expect(_editableIn(tester).autocorrect, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('a text area follows the same rule', () {
    testWidgets('obscured means no services', (tester) async {
      // `rows: 1` (which becomes `maxLines`) because `EditableText` asserts an obscured field is
      // single-line — so this is the only shape an obscured area can
      // legally take, and the gate still has to hold in it.
      await _pump(
        tester,
        TextArea(
          rows: 1,
          obscureText: true,
          spellCheckConfiguration: SpellCheckConfiguration(),
        ),
      );
      final editable = _editableIn(tester);

      expect(
        editable.spellCheckConfiguration,
        const SpellCheckConfiguration.disabled(),
      );
      expect(editable.autocorrect, isFalse);
      expect(editable.enableSuggestions, isFalse);
      expect(editable.enableIMEPersonalizedLearning, isFalse);
    });

    testWidgets('and a plain one keeps the inference open', (tester) async {
      await _pump(tester, TextArea());

      expect(_editableIn(tester).autocorrect, isTrue);
    });
  });
}
