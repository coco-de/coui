import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  group('TextField', () {
    testComponents('renders an <input> element', (tester) async {
      pumpWithTheme(tester, TextField());

      expect(find.tag('input'), findsOneComponent);
    });

    testComponents('renders initialValue as the input value attribute', (
      tester,
    ) async {
      pumpWithTheme(tester, TextField(initialValue: 'hello'));

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?['value'], equals('hello'));
    });

    testComponents('renders placeholder as the input placeholder attribute', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TextField(placeholder: Component.text('Enter text')),
      );

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?['placeholder'], equals('Enter text'));
    });

    testComponents('renders disabled attribute when not enabled', (
      tester,
    ) async {
      pumpWithTheme(tester, TextField(enabled: false));

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?.containsKey('disabled'), isTrue);
    });

    testComponents('renders readonly attribute', (tester) async {
      pumpWithTheme(tester, TextField(readOnly: true));

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?.containsKey('readonly'), isTrue);
    });

    testComponents('renders required attribute', (tester) async {
      pumpWithTheme(tester, TextField(required: true));

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?.containsKey('required'), isTrue);
    });

    testComponents('renders type=password when obscureText is set', (
      tester,
    ) async {
      pumpWithTheme(tester, TextField(obscureText: true));

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?['type'], equals('password'));
    });

    testComponents(
      'renders a selection:bg-* class for ::selection styling',
      (tester) async {
        pumpWithTheme(tester, TextField());

        final input =
            find.tag('input').evaluate().single.component as DomComponent;
        expect(input.classes, contains('selection:bg-'));
      },
    );

    test('accepts custom id', () {
      final field = TextField(id: 'field-1');
      expect(field.id, equals('field-1'));
    });

    test('sets name attribute', () {
      final field = TextField(name: 'email');
      expect(field.name, equals('email'));
    });

    test('copyWith preserves properties', () {
      final original = TextField(
        initialValue: 'a',
        enabled: false,
        name: 'field',
        id: 'field-orig',
      );

      final copy = original.copyWith(id: 'field-new');

      expect(copy.id, equals('field-new'));
      expect(copy.initialValue, equals('a'));
      expect(copy.enabled, isFalse);
      expect(copy.name, equals('field'));
    });

    test('copyWith keeps the variant', () {
      // The style chain rebuilds through copyWith — a variant it forgets
      // is lost the moment a style is applied.
      final copy = TextField(
        variant: CoreTextFieldVariant.error,
      ).withStyle(const CoreTextFieldStyle());

      expect(copy.variant, equals(CoreTextFieldVariant.error));
    });

    test('copyWith can change the variant', () {
      final copy = TextField(
        variant: CoreTextFieldVariant.error,
      ).copyWith(variant: CoreTextFieldVariant.plain);

      expect(copy.variant, equals(CoreTextFieldVariant.plain));
    });

    test('implements CoreTextFieldContract', () {
      final field = TextField(
        initialValue: 'value',
        enabled: true,
        required: true,
        size: CoreComponentSize.lg,
      );

      expect(field.initialValue, equals('value'));
      expect(field.enabled, isTrue);
      expect(field.required, isTrue);
      expect(field.size, equals(CoreComponentSize.lg));
    });
  });

  group('TextField controlled value', () {
    // Feature visibility reads the field's own cached copy of the text,
    // which is seeded at mount and then only written by input, submit
    // and clear. The element itself follows a controlled `value` (jaspr
    // assigns the DOM property for `value` on an `<input>`), so the
    // visible text was right while every affordance derived from the
    // cache described the previous text.
    testComponents('a parent-driven change updates value-derived features', (
      tester,
    ) async {
      late _ValueHostState host;
      pumpWithTheme(
        tester,
        _ValueHost(
          onState: (state) => host = state,
          builder: (value) => TextField(
            value: value,
            features: const [CoreInputFeature.clear()],
          ),
        ),
      );
      expect(find.tag('button'), findsOneComponent);

      host.setValue('');
      await tester.pump();

      expect(find.tag('button'), findsNothing);
    });
  });

  group('TextField semantic attribute routing', () {
    // A `role` on the wrapper describes the wrapper. Screen readers land
    // on the `<input>`, so that is where semantics have to go — `Command`
    // was already passing `aria-autocomplete` here and it sat inert on the
    // root until this routing existed.

    testComponents('role and aria-* land on the input', (tester) async {
      pumpWithTheme(
        tester,
        TextField(
          attributes: const {
            'role': 'combobox',
            'aria-autocomplete': 'list',
          },
        ),
      );

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?['role'], equals('combobox'));
      expect(input.attributes?['aria-autocomplete'], equals('list'));
    });

    testComponents('and are not left duplicated on the root', (tester) async {
      // Announced twice is its own defect.
      pumpWithTheme(
        tester,
        TextField(attributes: const {'role': 'combobox'}),
      );

      final elsewhere = find
          .byComponentPredicate(
            (c) =>
                c is DomComponent &&
                c.tag != 'input' &&
                c.attributes?['role'] == 'combobox',
          )
          .evaluate();
      expect(elsewhere, isEmpty);
    });

    testComponents('non-semantic attributes stay on the root', (
      tester,
    ) async {
      // The routing is narrow on purpose: a data attribute is about the
      // element the caller handed it to.
      pumpWithTheme(
        tester,
        TextField(attributes: const {'data-testid': 'field'}),
      );

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?.containsKey('data-testid'), isFalse);
      expect(
        find.byComponentPredicate(
          (c) => c is DomComponent && c.attributes?['data-testid'] == 'field',
        ),
        findsOneComponent,
      );
    });
  });
}

/// Rebuilds its child in place so the child reaches `didUpdateComponent`.
///
/// `ComponentTester.pumpComponent` mounts a fresh root rather than
/// updating the existing tree, so a second pump runs `initState` again —
/// and a fresh mount seeds itself from whatever value it is handed,
/// which makes an assertion about the *update* path pass without that
/// path ever running.
class _ValueHost extends StatefulComponent {
  const _ValueHost({required this.builder, required this.onState});

  /// Builds the field from the current value.
  final Component Function(String value) builder;

  /// Hands the live state back on every build, since `setState` is
  /// `@protected` and a test sits outside the component tree.
  final void Function(_ValueHostState state) onState;

  @override
  State<_ValueHost> createState() => _ValueHostState();
}

class _ValueHostState extends State<_ValueHost> {
  String value = 'hello';

  void setValue(String next) => setState(() => value = next);

  @override
  Component build(BuildContext context) {
    component.onState(this);
    return component.builder(value);
  }
}
