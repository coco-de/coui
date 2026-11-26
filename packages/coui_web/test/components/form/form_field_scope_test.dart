import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Web twin of Flutter's `form_field_scope_test.dart` — the disabled /
/// error constraint `FormField` and `Fieldset` publish to the input they
/// wrap, and `TextField` reading it.
///
/// Chrome is compared against a standalone `TextField` stated the same
/// way rather than against a class string: the claim is "the wrapper's
/// state reaches the input as if the input had been told directly".

/// The rendered `<input>` elements, in document order.
List<DomComponent> _inputs() => find
    .tag('input')
    .evaluate()
    .map((element) => element.component as DomComponent)
    .toList();

/// The box `<div>` that holds [input] — the element that draws the field's
/// border, fill and tone.
DomComponent _boxOf(DomComponent input) => find
    .tag('div')
    .evaluate()
    .map((element) => element.component)
    .whereType<DomComponent>()
    .firstWhere((box) => (box.children ?? const []).contains(input));

/// The parts of a field that carry its chrome and its disabled state —
/// `[box classes, box inline styles, input classes, input inline styles,
/// disabled attribute]`. Ids are per-instance and left out. A list (not a
/// record) so `equals` compares the style maps by content.
List<Object?> _chromeOf(DomComponent input) {
  final box = _boxOf(input);

  return [
    box.classes,
    box.styles?.properties,
    input.classes,
    input.styles?.properties,
    input.attributes?.containsKey('disabled') ?? false,
  ];
}

bool _isDisabled(DomComponent input) =>
    input.attributes?.containsKey('disabled') ?? false;

void main() {
  group('CoreFormFieldScope value', () {
    test('equality covers both fields', () {
      const a = CoreFormFieldScope(disabled: true, hasError: false);
      const b = CoreFormFieldScope(disabled: true, hasError: false);
      const c = CoreFormFieldScope(disabled: true, hasError: true);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('standalone use — no scope, no change', () {
    testComponents('a TextField with no wrapper reads no scope', (
      tester,
    ) async {
      CoreFormFieldScope? seen = const CoreFormFieldScope(
        disabled: true,
        hasError: true,
      );
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            seen = FormFieldScope.maybeOf(context);
            return const TextField();
          },
        ),
      );
      expect(seen, isNull);
    });

    testComponents(
      'an enabled, error-free FormField leaves its TextField exactly as a '
      'bare one',
      (tester) async {
        pumpWithTheme(
          tester,
          const div([
            TextField(),
            FormField(label: 'Name', child: TextField()),
          ]),
        );

        final inputs = _inputs();
        expect(_chromeOf(inputs[1]), equals(_chromeOf(inputs[0])));
        expect(_isDisabled(inputs[1]), isFalse);
      },
    );

    testComponents("a standalone TextField's own enabled / errorText still "
        'work', (tester) async {
      pumpWithTheme(
        tester,
        const div([
          TextField(),
          TextField(enabled: false),
          TextField(errorText: 'bad'),
        ]),
      );

      final inputs = _inputs();
      expect(_isDisabled(inputs[1]), isTrue);
      expect(_chromeOf(inputs[2]), isNot(equals(_chromeOf(inputs[0]))));
    });
  });

  group('Fieldset(enabled: false) → FormField → TextField', () {
    testComponents('the FormField and its input both read disabled', (
      tester,
    ) async {
      CoreFormFieldScope? atField;
      CoreFormFieldScope? atInput;
      pumpWithTheme(
        tester,
        div([
          const TextField(enabled: false),
          const TextField(),
          Fieldset(
            enabled: false,
            children: [
              Builder(
                builder: (context) {
                  atField = FormFieldScope.maybeOf(context);
                  return FormField(
                    label: 'Name',
                    child: Builder(
                      builder: (context) {
                        atInput = FormFieldScope.maybeOf(context);
                        return const TextField();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ]),
      );

      expect(atField?.disabled, isTrue);
      expect(atField?.hasError, isFalse);
      // The FormField states `enabled: true` itself — the enclosing
      // Fieldset still wins, and the FormField republishes that.
      expect(atInput?.disabled, isTrue);
      expect(atInput?.hasError, isFalse);

      final inputs = _inputs();
      // Disabled chrome (the `disabled:` utilities key off the native
      // attribute), identical to a TextField told `enabled: false`.
      expect(_chromeOf(inputs[2]), equals(_chromeOf(inputs[0])));
      expect(_chromeOf(inputs[2]), isNot(equals(_chromeOf(inputs[1]))));

      // The FormField group announces disabled too.
      final disabledGroups = find
          .byType(DomComponent)
          .evaluate()
          .map((element) => element.component as DomComponent)
          .where(
            (dom) =>
                dom.attributes?['role'] == 'group' &&
                dom.attributes?['aria-disabled'] == 'true',
          );
      expect(disabledGroups, hasLength(1));
    });

    testComponents('a nested enabled Fieldset cannot re-enable its fields', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const div([
          TextField(enabled: false),
          Fieldset(
            enabled: false,
            children: [
              Fieldset(
                children: [FormField(child: TextField())],
              ),
            ],
          ),
        ]),
      );

      final inputs = _inputs();
      expect(_chromeOf(inputs[1]), equals(_chromeOf(inputs[0])));
    });

    testComponents('an enabled Fieldset publishes an enabled scope', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const div([
          TextField(),
          Fieldset(children: [FormField(child: TextField())]),
        ]),
      );

      final inputs = _inputs();
      expect(_chromeOf(inputs[1]), equals(_chromeOf(inputs[0])));
    });
  });

  group('FormField(error) → TextField', () {
    testComponents('the input takes the error chrome from the wrapper', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const div([
          TextField(errorText: 'x'),
          TextField(),
          FormField(
            label: 'Email',
            error: 'Invalid email',
            child: TextField(),
          ),
        ]),
      );

      final inputs = _inputs();
      expect(_chromeOf(inputs[2]), equals(_chromeOf(inputs[0])));
      expect(_chromeOf(inputs[2]), isNot(equals(_chromeOf(inputs[1]))));
      // The message is the wrapper's to show — the input draws the tone
      // only, not a second copy of the text.
      expect(find.text('Invalid email'), findsOneComponent);
    });

    testComponents('wrapper error and input errorText combine with OR', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const div([
          TextField(errorText: 'x'),
          FormField(
            error: 'from wrapper',
            child: TextField(errorText: 'from input'),
          ),
          FormField(child: TextField(errorText: 'from input')),
        ]),
      );

      final inputs = _inputs();
      expect(_chromeOf(inputs[1]), equals(_chromeOf(inputs[0])));
      expect(_chromeOf(inputs[2]), equals(_chromeOf(inputs[0])));
    });

    testComponents('a disabled FormField disables its input', (tester) async {
      pumpWithTheme(
        tester,
        const div([
          TextField(enabled: false),
          FormField(enabled: false, child: TextField()),
        ]),
      );

      final inputs = _inputs();
      expect(_chromeOf(inputs[1]), equals(_chromeOf(inputs[0])));
    });
  });

  group('FormField footer', () {
    testComponents('an error removes the description from the DOM', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FormField(
          label: 'Email',
          description: 'We never share it.',
          error: 'Invalid email',
          child: TextField(),
        ),
      );

      expect(find.text('Invalid email'), findsOneComponent);
      expect(find.text('We never share it.'), findsNothing);
    });
  });

  group('FormField size', () {
    testComponents('defaults to md and forwards the size to its FormLabel', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const div([
          FormField(label: 'Default', child: Text('a')),
          FormField(
            label: 'Large',
            size: CoreComponentSize.lg,
            child: Text('b'),
          ),
        ]),
      );

      final labels = find
          .byType(FormLabel)
          .evaluate()
          .map((element) => element.component as FormLabel)
          .toList();
      expect(labels.map((formLabel) => formLabel.size), [
        CoreFormFieldStyle.defaultSize,
        CoreComponentSize.lg,
      ]);
      expect(CoreFormFieldStyle.defaultSize, CoreComponentSize.md);
    });

    testComponents(
      'a disabled lg field keeps the lg label rung — only the colour mutes',
      (tester) async {
        pumpWithTheme(
          tester,
          const div([
            FormField(label: 'MdOn', child: Text('a')),
            FormField(label: 'MdOff', enabled: false, child: Text('b')),
            FormField(
              label: 'LgOn',
              size: CoreComponentSize.lg,
              child: Text('c'),
            ),
            FormField(
              label: 'LgOff',
              size: CoreComponentSize.lg,
              enabled: false,
              child: Text('d'),
            ),
            // The same pose reached through the scope rather than the
            // field's own flag.
            Fieldset(
              enabled: false,
              children: [
                FormField(
                  label: 'LgInFieldset',
                  size: CoreComponentSize.lg,
                  child: Text('e'),
                ),
              ],
            ),
          ]),
        );

        // The rendered `<label>` roots, in document order — the only
        // labels here are the five FormFields' own.
        final labelClasses = find
            .tag('label')
            .evaluate()
            .map(
              (element) => ((element.component as DomComponent).classes ?? '')
                  .split(' ')
                  .where((c) => c.isNotEmpty)
                  .toSet(),
            )
            .toList();
        expect(labelClasses, hasLength(5));

        // The typography role is the one `text-label-*` class; the colour
        // is whatever `text-*` class is left.
        String roleOf(Set<String> classes) =>
            classes.singleWhere((c) => c.startsWith('text-label-'));
        Set<String> coloursOf(Set<String> classes) => classes
            .where((c) => c.startsWith('text-') && !c.startsWith('text-label-'))
            .toSet();

        final [mdOn, mdOff, lgOn, lgOff, lgInFieldset] = labelClasses;
        expect(roleOf(lgOn), isNot(roleOf(mdOn)));
        // Disabling moves the colour, never the rung.
        expect(roleOf(lgOff), roleOf(lgOn));
        expect(roleOf(lgInFieldset), roleOf(lgOn));
        expect(roleOf(mdOff), roleOf(mdOn));
        // …and the colour it moves to is the one md already mutes to.
        expect(coloursOf(lgOff), isNot(coloursOf(lgOn)));
        expect(coloursOf(lgOff), coloursOf(mdOff));
        expect(coloursOf(lgInFieldset), coloursOf(mdOff));
      },
    );
  });

  group('inputs that compose a TextField receive the scope through it', () {
    testComponents('a Select in a disabled Fieldset gets a disabled trigger', (
      tester,
    ) async {
      const items = [
        CoreSelectItem(value: 'apple', label: 'Apple'),
        CoreSelectItem(value: 'banana', label: 'Banana'),
      ];
      pumpWithTheme(
        tester,
        const div([
          Select<String>(items: items, placeholder: 'Bare'),
          Select<String>(
            items: items,
            placeholder: 'Told disabled',
            enabled: false,
          ),
          Fieldset(
            enabled: false,
            children: [
              Select<String>(items: items, placeholder: 'Grouped'),
            ],
          ),
        ]),
      );

      final inputs = _inputs();
      expect(inputs, hasLength(3));
      // The trigger is a TextField, so the group's scope reaches it: the
      // grouped Select renders exactly the trigger of one told
      // `enabled: false`.
      expect(_isDisabled(inputs[0]), isFalse);
      expect(_isDisabled(inputs[2]), isTrue);
      expect(_chromeOf(inputs[2]), equals(_chromeOf(inputs[1])));
    });
  });
}
