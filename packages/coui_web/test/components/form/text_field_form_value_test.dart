// TextField as a form input on the Web — it reports its text to the
// enclosing `FormField`, matching Flutter `TextField`.
//
// The trip these cases pin is the part a server-side test can reach: mount →
// attach with the initial text, a parent-driven `value` → report, the
// validator's verdict → the field's error, a `ReplaceResult` → the text
// rewritten, and the additional form id used inside a `FormField`.
// Every field listens to preserve its own text. Typing is a browser event
// with an `HTMLInputElement` target. This environment cannot synthesise it;
// the handler that reports it is asserted to be wired.
//
// The last group pins what must NOT report: an input a composite embeds as
// an implementation detail.

import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kNameKey = FormKey<String>('name');
const _kRequired = RequiredValidator<String>();

/// A `Form` with [controller] around one `FormField` keyed [_kNameKey].
Component _form(
  FormController controller,
  Component input, {
  Validator<dynamic>? validator,
  FormKey<dynamic> formKey = _kNameKey,
}) => Form(
  controller: controller,
  children: [
    FormField(formKey: formKey, validator: validator, child: input),
  ],
);

DomComponent get _input =>
    find.tag('input').evaluate().single.component as DomComponent;

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

/// Hosts a field built from a value the test can move — a parent driving a
/// controlled `value`.
class _ValueHost extends StatefulComponent {
  const _ValueHost({required this.builder, required this.onState});

  final Component Function(String value) builder;

  /// Hands the live state back on every build, since `setState` is
  /// `@protected` and a test sits outside the component tree.
  final void Function(_ValueHostState state) onState;

  @override
  State<_ValueHost> createState() => _ValueHostState();
}

class _ValueHostState extends State<_ValueHost> {
  String value = 'one';

  void setValue(String next) => setState(() => value = next);

  @override
  Component build(BuildContext context) {
    component.onState(this);

    return component.builder(value);
  }
}

void main() {
  group('TextField in a FormField — reports on mount', () {
    testComponents('attaches with its initial text, not null', (tester) async {
      final controller = FormController();
      pumpWithTheme(
        tester,
        _form(controller, const TextField(initialValue: 'Ada')),
      );
      await tester.pump();

      expect(controller.values.containsKey(_kNameKey), isTrue);
      expect(controller.getValue(_kNameKey), 'Ada');
      expect(controller.hasValue(_kNameKey), isTrue);
    });

    testComponents('a controlled value counts as the initial text', (
      tester,
    ) async {
      final controller = FormController();
      pumpWithTheme(tester, _form(controller, const TextField(value: 'Lin')));
      await tester.pump();

      expect(controller.getValue(_kNameKey), 'Lin');
    });

    testComponents('blank text attaches as null — an unanswered field', (
      tester,
    ) async {
      final controller = FormController();
      pumpWithTheme(tester, _form(controller, const TextField()));
      await tester.pump();

      // Attached (the key is known to the controller) yet holding no value.
      expect(controller.values.containsKey(_kNameKey), isTrue);
      expect(controller.getValue(_kNameKey), isNull);
      expect(controller.hasValue(_kNameKey), isFalse);
    });

    testComponents('a disabled or read-only field still has its value', (
      tester,
    ) async {
      final controller = FormController();
      pumpWithTheme(
        tester,
        _form(
          controller,
          const TextField(initialValue: 'fixed', readOnly: true),
        ),
      );
      await tester.pump();
      expect(controller.getValue(_kNameKey), 'fixed');
    });

    testComponents('a disabled field still has its value', (tester) async {
      final controller = FormController();
      pumpWithTheme(
        tester,
        _form(controller, const TextField(initialValue: 'off', enabled: false)),
      );
      await tester.pump();
      expect(controller.getValue(_kNameKey), 'off');
    });
  });

  group('TextField in a FormField — reports every change', () {
    testComponents('a controlled value follows its parent', (tester) async {
      final controller = FormController();
      late _ValueHostState host;
      pumpWithTheme(
        tester,
        _ValueHost(
          onState: (state) => host = state,
          builder: (value) => _form(controller, TextField(value: value)),
        ),
      );
      await tester.pump();
      expect(controller.getValue(_kNameKey), 'one');

      host.setValue('two');
      await tester.pump();
      expect(controller.getValue(_kNameKey), 'two');

      // Emptied by the parent: an unanswered field again.
      host.setValue('');
      await tester.pump();
      expect(controller.getValue(_kNameKey), isNull);
    });
  });

  group('TextField in a FormField — the <input> wiring', () {
    testComponents('listens for typing, and is addressable, inside a form', (
      tester,
    ) async {
      final controller = FormController();
      pumpWithTheme(tester, _form(controller, const TextField()));
      await tester.pump();

      // The `input` listener is how the form hears the text; the id is how
      // a replacement is written back to the element.
      expect(_input.events?.containsKey('input'), isTrue);
      expect(_input.attributes?['id'], isNotNull);
    });

    testComponents('a bare field preserves text without acquiring a form id', (
      tester,
    ) async {
      pumpWithTheme(tester, const TextField());

      expect(_input.events?.containsKey('input'), isTrue);
      expect(_input.attributes?['id'], isNull);
    });

    testComponents('a FormField with no Form controller still wires them', (
      tester,
    ) async {
      pumpWithTheme(tester, const FormField(child: TextField()));
      await tester.pump();

      expect(_input.events?.containsKey('input'), isTrue);
    });
  });

  group('TextField in a FormField — validation', () {
    testComponents('a blank required field shows the error', (tester) async {
      final controller = FormController();
      pumpWithTheme(
        tester,
        _form(controller, const TextField(), validator: _kRequired),
      );
      await tester.pump();

      expect(find.text('This field cannot be empty'), findsOneComponent);
      expect(controller.getSyncError(_kNameKey), isA<InvalidResult>());
    });

    testComponents('a prefilled required field starts valid', (tester) async {
      final controller = FormController();
      pumpWithTheme(
        tester,
        _form(
          controller,
          const TextField(initialValue: 'Ada'),
          validator: _kRequired,
        ),
      );
      await tester.pump();

      expect(find.text('This field cannot be empty'), findsNothing);
      expect(controller.getSyncError(_kNameKey), isNull);
    });

    testComponents('the error goes when the parent supplies a value', (
      tester,
    ) async {
      final controller = FormController();
      late _ValueHostState host;
      pumpWithTheme(
        tester,
        _ValueHost(
          onState: (state) => host = state,
          builder: (value) => _form(
            controller,
            TextField(value: value == 'one' ? '' : value),
            validator: _kRequired,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('This field cannot be empty'), findsOneComponent);

      host.setValue('filled');
      await tester.pump();
      expect(find.text('This field cannot be empty'), findsNothing);
    });
  });

  group('TextField in a FormField — a validator can rewrite the text', () {
    testComponents('a ReplaceResult is adopted and tells onChanged', (
      tester,
    ) async {
      final controller = FormController();
      final heard = <String>[];
      pumpWithTheme(
        tester,
        _form(
          controller,
          TextField(initialValue: '  x  ', onChanged: heard.add),
          validator: const _TrimValidator(),
        ),
      );
      await tester.pump();

      expect(heard, ['x']);
      expect(controller.getValue(_kNameKey), 'x');
    });

    testComponents('an asynchronous ReplaceResult does the same', (
      tester,
    ) async {
      final controller = FormController();
      final heard = <String>[];
      pumpWithTheme(
        tester,
        _form(
          controller,
          TextField(initialValue: ' y ', onChanged: heard.add),
          validator: const _TrimValidator(deferred: true),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(heard, ['y']);
      expect(controller.getValue(_kNameKey), 'y');
    });

    testComponents('a replacement that changes nothing is not announced', (
      tester,
    ) async {
      final controller = FormController();
      final heard = <String>[];
      pumpWithTheme(
        tester,
        _form(
          controller,
          TextField(initialValue: 'clean', onChanged: heard.add),
          validator: const _TrimValidator(),
        ),
      );
      await tester.pump();

      expect(heard, isEmpty);
    });
  });

  group("what must not report as the field's value", () {
    testComponents("a PhoneInput's number field — the value stays a phone "
        'number', (tester) async {
      final controller = FormController();
      const key = FormKey<PhoneInputValue>('phone');
      pumpWithTheme(
        tester,
        _form(
          controller,
          PhoneInput(onChanged: (_) {}, initialNumber: '5551234'),
          formKey: key,
        ),
      );
      await tester.pump();

      expect(controller.getValue(key), isA<PhoneInputValue>());
      expect(controller.getValue(key)!.number, '5551234');
    });

    testComponents("an ObjectInput's fields — the value stays the map", (
      tester,
    ) async {
      final controller = FormController();
      const key = FormKey<Map<String, String>>('date');
      pumpWithTheme(
        tester,
        _form(
          controller,
          const ObjectInput(
            fields: [
              CoreObjectInputField(key: 'year', placeholder: 'YYYY'),
              CoreObjectInputField(key: 'month', placeholder: 'MM'),
            ],
            values: {'year': '2026', 'month': '06'},
          ),
          formKey: key,
        ),
      );
      await tester.pump();

      expect(controller.getValue(key), {'year': '2026', 'month': '06'});
    });

    testComponents('an input that is no form input of its own reports '
        'nothing', (tester) async {
      final controller = FormController();
      pumpWithTheme(
        tester,
        _form(
          controller,
          const Select<String>(
            items: [CoreSelectItem<String>(value: 'apple', label: 'Apple')],
            value: 'apple',
          ),
        ),
      );
      await tester.pump();

      // `Select` is not a `FormValueSupplier`, and its trigger — a
      // read-only `TextField` showing the chosen label — must not stand in
      // for it: the label is not the field's value.
      expect(controller.values.containsKey(_kNameKey), isFalse);
    });

    testComponents("a ChipInput's entry field reports nothing", (
      tester,
    ) async {
      final controller = FormController();
      pumpWithTheme(
        tester,
        _form(controller, ChipInput(chips: const ['one'], onChanged: (_) {})),
      );
      await tester.pump();

      expect(controller.values.containsKey(_kNameKey), isFalse);
    });

    testComponents('a boundary is what does it — an unwalled TextField '
        'reports', (tester) async {
      // The control for the cases above: the same kind of embedded
      // `TextField`, without the wall, does reach the form. Without it a
      // pass above could mean the field never reported at all.
      final controller = FormController();
      pumpWithTheme(
        tester,
        _form(controller, const div([TextField(initialValue: 'reaches')])),
      );
      await tester.pump();

      expect(controller.getValue(_kNameKey), 'reaches');

      final walled = FormController();
      pumpWithTheme(
        tester,
        _form(
          walled,
          const FormFieldHandleScope.boundary(
            child: div([TextField(initialValue: 'walled')]),
          ),
        ),
      );
      await tester.pump();

      expect(walled.values.containsKey(_kNameKey), isFalse);
    });
  });
}
