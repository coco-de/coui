// Tests for Web `NumberInput` — structure, resolved chrome, and the
// arithmetic seams. `jaspr_test`'s `ComponentTester` has no real DOM events,
// so a button press / key press cannot be simulated here; the value
// arithmetic they call is covered in
// `packages/coui_core/test/number_input_math_test.dart`.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

String? _attr(DomComponent dom, String name) => dom.attributes?[name];

Iterable<DomComponent> _buttons() => find
    .tag('button')
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>();

void _expectDisabled(bool disabled) {
  final input = find.tag('input').evaluate().single.component as DomComponent;
  expect(_attr(input, 'disabled') != null, disabled);
  final buttons = _buttons().toList();
  expect(buttons, hasLength(2));
  for (final button in buttons) {
    expect(_attr(button, 'disabled') != null, disabled);
  }
}

class _ScopeHost extends StatefulComponent {
  const _ScopeHost({required this.onMount, this.child});

  final void Function(_ScopeHostState) onMount;
  final Component? child;

  @override
  State<_ScopeHost> createState() => _ScopeHostState();
}

class _ScopeHostState extends State<_ScopeHost> {
  bool _enabled = true;
  double _value = 2;
  final changes = <double>[];

  @override
  void initState() {
    super.initState();
    component.onMount(this);
  }

  void update({bool? enabled, double? value}) {
    setState(() {
      _enabled = enabled ?? _enabled;
      _value = value ?? _value;
    });
  }

  @override
  Component build(BuildContext context) => Fieldset(
    enabled: _enabled,
    children: [
      component.child ??
          NumberInput(
            key: const ValueKey('controlled-number'),
            value: _value,
            onChanged: changes.add,
          ),
    ],
  );
}

void main() {
  testComponents('error replaces helper and marks the field invalid', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const NumberInput(
        description: 'Choose a count',
        errorText: 'Too many guests',
      ),
    );
    expect(find.text('Choose a count'), findsNothing);
    expect(find.text('Too many guests'), findsOneComponent);
    final input = find.tag('input').evaluate().single.component as DomComponent;
    expect(input.attributes?['aria-invalid'], 'true');
    pumpWithTheme(tester, const NumberInput(description: 'Choose a count'));
    expect(find.text('Too many guests'), findsNothing);
    expect(find.text('Choose a count'), findsOneComponent);
    final validInput =
        find.tag('input').evaluate().single.component as DomComponent;
    expect(validInput.attributes?['aria-invalid'], isNull);
  });

  group('NumberInput resolver', () {
    testComponents('field widths are the 90 · 114 · 138 the design states', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const expected = {
        CoreNumberInputSize.sm: '5.625rem',
        CoreNumberInputSize.md: '7.125rem',
        CoreNumberInputSize.lg: '8.625rem',
      };
      for (final entry in expected.entries) {
        final resolved = resolveNumberInput(
          context,
          size: entry.key,
          variant: CoreNumberInputVariant.defaultVariant,
        );
        expect(
          resolved.root.inlineStyles?.properties['width'],
          entry.value,
          reason: '${entry.key.name} width',
        );
      }
    });

    testComponents('the composed field is centred, value in bodyMedium', (
      tester,
    ) async {
      final resolved = resolveNumberInput(
        _themedContext(tester),
        size: CoreNumberInputSize.md,
        variant: CoreNumberInputVariant.defaultVariant,
      );
      expect(resolved.fieldStyle.textAlign, CoreTextAlign.center);
      expect(
        resolved.fieldStyle.valueStyle?.token,
        CoreTextStyles.bodyMedium,
      );
    });

    testComponents('an instance style wins over the size row', (tester) async {
      final resolved = resolveNumberInput(
        _themedContext(tester),
        size: CoreNumberInputSize.md,
        variant: CoreNumberInputVariant.defaultVariant,
        numberInputStyle: const CoreNumberInputStyle(width: 200),
      );
      expect(resolved.root.inlineStyles?.properties['width'], '12.5rem');
    });
  });

  group('NumberInput render', () {
    testComponents('draws two step buttons named by the locale', (
      tester,
    ) async {
      pumpWithTheme(tester, const NumberInput(initialValue: 3));
      final names = _buttons()
          .map((node) => _attr(node, 'aria-label'))
          .toList();
      expect(names, ['Decrease', 'Increase']);
    });

    testComponents('a button is disabled exactly at its bound', (tester) async {
      pumpWithTheme(
        tester,
        const NumberInput(initialValue: 1, min: 1, max: 3),
      );
      final byName = {
        for (final b in _buttons()) _attr(b, 'aria-label'): b,
      };
      expect(_attr(byName['Decrease']!, 'disabled'), isNotNull);
      expect(_attr(byName['Increase']!, 'disabled'), isNull);
    });

    testComponents('the value shows as a number input with the bounds', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const NumberInput(initialValue: 4, min: 0, max: 9),
      );
      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(_attr(input, 'type'), 'number');
      expect(_attr(input, 'min'), '0');
      expect(_attr(input, 'max'), '9');
      expect(_attr(input, 'value'), '4');
    });

    // #5762 — the designer's caret is 2 wide, corner 2, no gap, the value's
    // line box tall, in `primary`. The value is a native `<input>`, whose
    // caret the browser draws: only its colour is CSS-settable, so the colour
    // is the one value that reaches the screen. The width and corner still
    // ride `--coui-caret-*` from the same Core defaults the Flutter caret
    // paints, for tooling — nothing in the stylesheet reads them.
    testComponents('the caret is primary, and states the Core width / corner', (
      tester,
    ) async {
      pumpWithTheme(tester, const NumberInput(initialValue: 4));
      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      final caretClass =
          'caret-${CoreTextFieldStyle.defaultCursorColor.tailwindColor}';
      expect(caretClass, 'caret-primary');
      expect(input.classes?.split(' '), contains(caretClass));
      final css = input.styles!.properties;
      expect(css['--coui-caret-width'], '0.125rem');
      expect(css['--coui-caret-radius'], '0.125rem');
      expect(css.containsKey('caret-color'), isFalse);
    });

    // #5762 — the value is Body/Medium (Regular 14 · 150%), so the line box
    // the caret stands in is 21. The role class carries the role's own 150%
    // (`--coui-text-body-medium-line-height`); nothing lays another inline.
    testComponents('the value paints in bodyMedium at 150%', (tester) async {
      for (final size in CoreNumberInputSize.values) {
        pumpWithTheme(tester, NumberInput(size: size, initialValue: 4));
        final input =
            find.tag('input').evaluate().single.component as DomComponent;
        final classes = input.classes!.split(' ');
        expect(classes, contains('text-body-medium'), reason: '$size');
        expect(classes, isNot(contains('text-label-large')), reason: '$size');
        expect(
          input.styles!.properties.containsKey('line-height'),
          isFalse,
          reason: '$size',
        );
        expect(input.styles!.properties['text-align'], 'center');
      }
    });

    testComponents('a disabled input disables both buttons', (tester) async {
      pumpWithTheme(
        tester,
        const NumberInput(initialValue: 2, enabled: false),
      );
      for (final b in _buttons()) {
        expect(_attr(b, 'disabled'), isNotNull);
      }
    });
  });

  group('NumberInput form scope', () {
    testComponents('a disabled Fieldset disables the input and both buttons', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Fieldset(
          enabled: false,
          children: [NumberInput(value: 2, enabled: true)],
        ),
      );
      _expectDisabled(true);
    });

    testComponents('a disabled FormField disables the input and both buttons', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FormField(
          enabled: false,
          child: NumberInput(value: 2, enabled: true),
        ),
      );
      _expectDisabled(true);
    });

    testComponents('an enabled inner scope cannot override disabled Fieldset', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Fieldset(
          enabled: false,
          children: [
            Fieldset(
              children: [
                FormField(child: NumberInput(value: 2, enabled: true)),
              ],
            ),
          ],
        ),
      );
      _expectDisabled(true);
    });

    testComponents('an enabled Fieldset cannot override own disabled input', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Fieldset(children: [NumberInput(value: 2, enabled: false)]),
      );
      _expectDisabled(true);
    });

    testComponents('ancestor-only changes update the same mounted input', (
      tester,
    ) async {
      late _ScopeHostState host;
      const number = NumberInput(value: 2, enabled: true);
      pumpWithTheme(
        tester,
        _ScopeHost(onMount: (state) => host = state, child: number),
      );
      final original = find.byType(NumberInput).evaluate().single;
      expect(identical(original.component, number), isTrue);
      _expectDisabled(false);

      host.update(enabled: false);
      await tester.pump();
      expect(
        identical(find.byType(NumberInput).evaluate().single, original),
        isTrue,
      );
      _expectDisabled(true);

      host.update(enabled: true);
      await tester.pump();
      expect(
        identical(find.byType(NumberInput).evaluate().single, original),
        isTrue,
      );
      _expectDisabled(false);
    });

    testComponents('controlled values still synchronize while disabled', (
      tester,
    ) async {
      late _ScopeHostState host;
      pumpWithTheme(tester, _ScopeHost(onMount: (state) => host = state));
      final original = find.byType(NumberInput).evaluate().single;

      host.update(enabled: false);
      await tester.pump();
      _expectDisabled(true);
      host.update(value: 7);
      await tester.pump();
      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(_attr(input, 'value'), '7');
      expect(host.changes, isEmpty);
      expect(
        identical(find.byType(NumberInput).evaluate().single, original),
        isTrue,
      );
      _expectDisabled(true);

      host.update(enabled: true);
      await tester.pump();
      _expectDisabled(false);
      final enabledInput =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(_attr(enabledInput, 'value'), '7');
      expect(host.changes, isEmpty);
    });
  });
}
