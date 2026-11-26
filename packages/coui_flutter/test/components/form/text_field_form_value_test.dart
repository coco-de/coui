// TextField as a form input — it reports its text to the enclosing
// `FormField`, the way `Checkbox` / `Toggle` / `RadioGroup` do.
//
// `FormField` promises that its child input reports through the inherited
// `FormFieldHandle`, and `TextField` is the first input it names. What these
// cases pin is the whole trip: mount → attach with the initial text, edit →
// report, the validator's verdict → the field's error and the input's tone,
// a `ReplaceResult` → the text rewritten. The last group pins what must NOT
// report: a text field a composite embeds, and one that lives in an overlay
// opened from the field.

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kNameKey = FormKey<String>('name');
const _kRequired = RequiredValidator<String>(message: 'Required');

/// Frames to pump while waiting for an overlay to mount — a bound, so an
/// overlay that never opens fails an assertion instead of hanging.
const _kOverlayMountFrames = 20;

/// The theme sits ABOVE the navigator so a dialog pushed onto the root
/// navigator resolves against it too.
Widget _app(Widget child) => material.MaterialApp(
  builder: (context, navigator) =>
      Theme(data: const ThemeData(), child: navigator!),
  home: material.Scaffold(body: SingleChildScrollView(child: child)),
  localizationsDelegates: const [
    CoUILocalizationsDelegate.delegate,
    material.DefaultMaterialLocalizations.delegate,
    material.DefaultWidgetsLocalizations.delegate,
  ],
);

/// A `Form` with [controller] around one `FormField` keyed [_kNameKey].
Widget _form(
  FormController controller,
  Widget input, {
  Validator<dynamic>? validator,
  bool enabled = true,
  FormKey<dynamic> formKey = _kNameKey,
}) => _app(
  Form(
    controller: controller,
    children: [
      FormField(
        formKey: formKey,
        validator: validator,
        enabled: enabled,
        child: input,
      ),
    ],
  ),
);

FormController _newController(WidgetTester tester) {
  final controller = FormController();
  addTearDown(controller.dispose);

  return controller;
}

/// Every box decoration painted inside the [index]-th `TextField` — the
/// field box plus whatever the focus outline paints.
List<Decoration> _decorationsOf(WidgetTester tester, int index) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(TextField).at(index),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .toList();

/// Validator that rewrites surrounding whitespace away — the everyday
/// `ReplaceResult`.
class _TrimValidator extends Validator<String> {
  const _TrimValidator({this.deferred = false});

  /// Answer from a `Future` rather than synchronously.
  final bool deferred;

  @override
  FutureOr<ValidationResult?> validate(
    CoreValidationContext context,
    String? value,
    FormValidationMode lifecycle,
  ) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed == value) return null;
    final result = ReplaceResult<String>(trimmed, state: lifecycle);

    return deferred ? Future<ValidationResult?>.value(result) : result;
  }
}

/// Opens a dialog from [opener] whose body is [dialogBody].
Future<void> _openDialog(
  WidgetTester tester,
  BuildContext opener,
  Widget dialogBody,
) async {
  unawaited(
    showDialog<void>(
      context: opener,
      builder: (context) => dialogBody,
    ),
  );
  for (var frame = 0; frame < _kOverlayMountFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(TextField).evaluate().length > 1) break;
  }
}

void main() {
  group('TextField in a FormField — reports on mount', () {
    testWidgets('attaches with its initial text, not null', (tester) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _form(controller, TextField(initialValue: 'Ada')),
      );
      await tester.pumpAndSettle();

      expect(controller.values.containsKey(_kNameKey), isTrue);
      expect(controller.getValue(_kNameKey), 'Ada');
      expect(controller.hasValue(_kNameKey), isTrue);
    });

    testWidgets("attaches with a caller's controller text", (tester) async {
      final controller = _newController(tester);
      final text = TextEditingController(text: 'Grace');
      addTearDown(text.dispose);
      await tester.pumpWidget(_form(controller, TextField(controller: text)));
      await tester.pumpAndSettle();

      expect(controller.getValue(_kNameKey), 'Grace');
    });

    testWidgets('a controlled value counts as the initial text', (
      tester,
    ) async {
      final controller = _newController(tester);
      await tester.pumpWidget(_form(controller, TextField(value: 'Lin')));
      await tester.pumpAndSettle();

      expect(controller.getValue(_kNameKey), 'Lin');
    });

    testWidgets('blank text attaches as null — an unanswered field', (
      tester,
    ) async {
      final controller = _newController(tester);
      await tester.pumpWidget(_form(controller, TextField()));
      await tester.pumpAndSettle();

      // Attached (the key is known to the controller) yet holding no value.
      expect(controller.values.containsKey(_kNameKey), isTrue);
      expect(controller.getValue(_kNameKey), isNull);
      expect(controller.hasValue(_kNameKey), isFalse);
    });

    testWidgets('a disabled or read-only field still has its value', (
      tester,
    ) async {
      // Each pose is its own field (a key apart) — an uncontrolled field
      // keeps the text it mounted with, so re-posing one would test nothing.
      final poses = <(String, Widget, bool)>[
        (
          'fixed',
          TextField(
            key: const ValueKey('read-only'),
            initialValue: 'fixed',
            readOnly: true,
          ),
          true,
        ),
        (
          'off',
          TextField(
            key: const ValueKey('disabled'),
            initialValue: 'off',
            enabled: false,
          ),
          true,
        ),
        // The wrapper's `enabled: false` reaches the input as a scope and
        // makes it read-only; the value it holds is still reported.
        (
          'scoped',
          TextField(key: const ValueKey('scoped'), initialValue: 'scoped'),
          false,
        ),
      ];

      for (final (expected, input, fieldEnabled) in poses) {
        final controller = _newController(tester);
        await tester.pumpWidget(
          _form(controller, input, enabled: fieldEnabled),
        );
        await tester.pumpAndSettle();

        expect(controller.getValue(_kNameKey), expected);
      }
    });
  });

  group('TextField in a FormField — reports every change', () {
    testWidgets('typing reports the text, clearing reports null', (
      tester,
    ) async {
      final controller = _newController(tester);
      await tester.pumpWidget(_form(controller, TextField()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'hello');

      await tester.enterText(find.byType(TextField), 'hello!');
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'hello!');

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), isNull);
    });

    testWidgets("the caller's controller is where edits are heard", (
      tester,
    ) async {
      final controller = _newController(tester);
      final text = TextEditingController();
      addTearDown(text.dispose);
      await tester.pumpWidget(_form(controller, TextField(controller: text)));
      await tester.pumpAndSettle();

      // Not typed — the caller wrote to its own controller.
      text.text = 'from code';
      await tester.pumpAndSettle();

      expect(controller.getValue(_kNameKey), 'from code');
    });

    testWidgets('a controlled value follows its parent', (tester) async {
      final controller = _newController(tester);
      await tester.pumpWidget(_form(controller, TextField(value: 'one')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_form(controller, TextField(value: 'two')));
      await tester.pumpAndSettle();

      expect(controller.getValue(_kNameKey), 'two');
    });

    testWidgets('the clear affordance reports the emptied field', (
      tester,
    ) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _form(
          controller,
          TextField(
            initialValue: 'gone soon',
            features: const [CoreInputFeature.clear()],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'gone soon');

      await tester.tap(find.byType(Button));
      await tester.pumpAndSettle();

      expect(controller.getValue(_kNameKey), isNull);
    });

    testWidgets('swapping the controller reports the new text', (tester) async {
      final controller = _newController(tester);
      final first = TextEditingController(text: 'first');
      final second = TextEditingController(text: 'second');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(_form(controller, TextField(controller: first)));
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'first');

      await tester.pumpWidget(_form(controller, TextField(controller: second)));
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'second');

      // The old controller is no longer this field's business…
      first.text = 'stale';
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'second');

      // …and the new one is.
      second.text = 'fresh';
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'fresh');
    });

    testWidgets("an owned controller becomes a caller's and back", (
      tester,
    ) async {
      final controller = _newController(tester);
      final text = TextEditingController(text: 'caller');
      addTearDown(text.dispose);

      await tester.pumpWidget(
        _form(controller, TextField(initialValue: 'own')),
      );
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'own');

      await tester.pumpWidget(_form(controller, TextField(controller: text)));
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'caller');

      await tester.pumpWidget(
        _form(controller, TextField(initialValue: 'back')),
      );
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'back');

      // The caller's controller kept no listener of this field's.
      text.text = 'after';
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'back');
    });

    testWidgets("once unmounted, the caller's controller reports nowhere", (
      tester,
    ) async {
      final controller = _newController(tester);
      final text = TextEditingController(text: 'here');
      addTearDown(text.dispose);
      await tester.pumpWidget(_form(controller, TextField(controller: text)));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_app(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(() => text.text = 'unheard', returnsNormally);
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'here');
    });
  });

  group('TextField in a FormField — validation', () {
    testWidgets('a blank required field shows the error, typing clears it', (
      tester,
    ) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _form(controller, TextField(), validator: _kRequired),
      );
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      expect(controller.getSyncError(_kNameKey), isA<InvalidResult>());

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsNothing);
      expect(controller.getSyncError(_kNameKey), isNull);

      // And back: emptying the field is answering nothing again.
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('a prefilled required field starts valid', (tester) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _form(
          controller,
          TextField(initialValue: 'Ada'),
          validator: _kRequired,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNothing);
      expect(controller.getSyncError(_kNameKey), isNull);
    });

    testWidgets('the input takes the error tone while invalid, and loses it', (
      tester,
    ) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              // References: the same field stated by hand.
              TextField(errorText: 'x'),
              TextField(),
              Form(
                controller: controller,
                children: [
                  FormField(
                    formKey: _kNameKey,
                    validator: _kRequired,
                    child: TextField(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final errored = _decorationsOf(tester, 0);
      final plain = _decorationsOf(tester, 1);
      expect(errored, isNot(equals(plain)), reason: 'the premise');

      expect(_decorationsOf(tester, 2), equals(errored));

      await tester.enterText(find.byType(TextField).at(2), 'ok');
      await tester.pumpAndSettle();
      // Focus paints its own border, so let go of it before comparing with
      // the (unfocused) references.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(_decorationsOf(tester, 2), equals(plain));
    });

    testWidgets("revalidating the form re-reads the field's text", (
      tester,
    ) async {
      final controller = _newController(tester);
      late BuildContext formContext;
      await tester.pumpWidget(
        _app(
          Form(
            controller: controller,
            children: [
              FormField(
                formKey: _kNameKey,
                validator: _kRequired,
                child: TextField(initialValue: 'Ada'),
              ),
              Builder(
                builder: (context) {
                  formContext = context;
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.revalidate(
        CoUIValidationContext(formContext),
        FormValidationMode.submitted,
      );
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNothing);
      expect(controller.getValue(_kNameKey), 'Ada');
    });
  });

  group('TextField in a FormField — a validator can rewrite the text', () {
    testWidgets('a ReplaceResult rewrites the text and tells onChanged', (
      tester,
    ) async {
      final controller = _newController(tester);
      final heard = <String>[];
      await tester.pumpWidget(
        _form(
          controller,
          TextField(onChanged: heard.add),
          validator: const _TrimValidator(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  hi  ');
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'hi',
      );
      expect(controller.getValue(_kNameKey), 'hi');
      // What was typed, then what replaced it — in that order.
      expect(heard, ['  hi  ', 'hi']);
    });

    testWidgets('an asynchronous ReplaceResult does the same', (tester) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _form(
          controller,
          TextField(),
          validator: const _TrimValidator(deferred: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), ' padded ');
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'padded',
      );
      expect(controller.getValue(_kNameKey), 'padded');
    });

    testWidgets('the caret stays inside the rewritten text', (tester) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _form(controller, TextField(), validator: const _TrimValidator()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '      x');
      await tester.pumpAndSettle();

      final selection = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller
          .selection;
      expect(selection.isValid, isTrue, reason: 'no caret would be left');
      expect(selection.isCollapsed, isTrue);
      expect(selection.baseOffset, inInclusiveRange(0, 'x'.length));
    });

    testWidgets('a replacement that changes nothing is not written', (
      tester,
    ) async {
      final controller = _newController(tester);
      final heard = <String>[];
      await tester.pumpWidget(
        _form(
          controller,
          TextField(onChanged: heard.add),
          validator: const _TrimValidator(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'clean');
      await tester.pumpAndSettle();

      expect(heard, ['clean']);
    });
  });

  group('TextField outside a FormField — nothing changes', () {
    testWidgets('a bare field edits and fires onChanged once per edit', (
      tester,
    ) async {
      final heard = <String>[];
      await tester.pumpWidget(_app(TextField(onChanged: heard.add)));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      expect(heard, ['abc']);
    });

    testWidgets('a FormField with no Form controller takes edits quietly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(FormField(validator: _kRequired, child: TextField())),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('abc'), findsOneWidget);
    });
  });

  group("what must not report as the field's value", () {
    testWidgets('a text box in a dialog opened from the field', (tester) async {
      final controller = _newController(tester);
      late BuildContext opener;
      await tester.pumpWidget(
        _form(
          controller,
          Builder(
            builder: (context) {
              opener = context;
              return TextField(initialValue: 'the field');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.getValue(_kNameKey), 'the field');

      await _openDialog(tester, opener, TextField());
      expect(find.byType(TextField), findsNWidgets(2), reason: 'the premise');

      await tester.enterText(find.byType(TextField).last, 'typed in dialog');
      await tester.pumpAndSettle();

      expect(controller.getValue(_kNameKey), 'the field');
    });

    testWidgets("a PhoneInput's number field — the PhoneNumber stays", (
      tester,
    ) async {
      final controller = _newController(tester);
      const key = FormKey<PhoneNumber>('phone');
      await tester.pumpWidget(
        _form(
          controller,
          const PhoneInput(initialNumber: '5551234'),
          formKey: key,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.getValue(key), isA<PhoneNumber>());
      expect(controller.getValue(key)!.number, '5551234');

      await tester.enterText(find.byType(TextField), '5559999');
      await tester.pumpAndSettle();

      expect(controller.getValue(key), isA<PhoneNumber>());
      expect(controller.getValue(key)!.number, '5559999');
    });

    testWidgets("an InputOtp's hidden buffer — the code list stays", (
      tester,
    ) async {
      final controller = _newController(tester);
      const key = FormKey<OTPCodepointList>('otp');
      await tester.pumpWidget(
        _form(controller, const InputOtp(length: 4), formKey: key),
      );
      await tester.pumpAndSettle();

      expect(controller.getValue(key), isA<List<int?>>());

      await tester.enterText(find.byType(TextField), '12');
      await tester.pumpAndSettle();

      expect(controller.getValue(key), isA<List<int?>>());
      expect(controller.getValue(key), [49, 50, null, null]);
    });

    testWidgets('an input that is no form input of its own reports nothing', (
      tester,
    ) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _form(
          controller,
          Select<String>(
            onChanged: (_) {},
            placeholder: 'Pick one',
            items: const [
              CoreSelectItem<String>(value: 'apple', label: 'Apple'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // `Select` is not a `FormValueSupplier`, and its trigger — a
      // read-only `TextField` showing the chosen label — must not stand in
      // for it: the label is not the field's value.
      expect(controller.values.containsKey(_kNameKey), isFalse);

      await tester.enterText(find.byType(TextField), 'label');
      await tester.pumpAndSettle();
      expect(controller.values.containsKey(_kNameKey), isFalse);
    });

    testWidgets("a ChipInput's entry field reports nothing", (tester) async {
      final controller = _newController(tester);
      await tester.pumpWidget(
        _form(controller, const ChipInput(chips: ['one'])),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'partial entr');
      await tester.pumpAndSettle();

      expect(controller.values.containsKey(_kNameKey), isFalse);
    });
  });
}
