// Tests for Web `FormattedInput` — the single real `<input>` architecture
// from Story #3869. Structural / attribute / resolver-level coverage;
// the AsYouType reformat + caret-restore algorithm itself (backspace
// through a literal boundary, range deletion, heterogeneous per-slot
// patterns …) is exhaustively covered at the platform-neutral engine
// level in `packages/coui_core/test/formatted_input_mask_engine_test.dart`
// — `jaspr_test`'s `ComponentTester` has no real DOM, so a native `input`
// event with `selectionStart`/`selectionEnd` cannot be simulated here.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the [BuildContext] a real component tree resolves under (with
/// the ambient `Theme.defaults` [pumpWithTheme] installs) so resolver-level
/// tests can call `resolveFormattedInput` directly instead of re-deriving
/// chrome assertions by digging through rendered DOM nodes.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

/// Pumps a [_ContextCapture] under [pumpWithTheme] and returns the
/// captured context.
BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// Returns the sole rendered `<input>` `DomComponent`.
DomComponent _findInput() =>
    find.tag('input').evaluate().single.component as DomComponent;

/// The class list as a set of whole classes, so `flex` and `inline-flex`
/// stay distinguishable (a substring check matches the first inside the
/// second).
Set<String> _classesOf(String? classes) =>
    (classes ?? '').split(RegExp(r'\s+')).where((c) => c.isNotEmpty).toSet();

/// The framed row that holds the `<input>` — the one `<div>` carrying the
/// border colour token.
DomComponent _findRoot() => find
    .tag('div')
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere(
      (d) => _classesOf(d.classes).contains('border-outline-variant'),
    );

void main() {
  group('FormattedInput construction', () {
    test('enabled flag defaults to true', () {
      const input = FormattedInput(parts: CoreFormattedInputMasks.phone);
      expect(input.enabled, isTrue);
    });

    test('value defaults to null', () {
      const input = FormattedInput(parts: CoreFormattedInputMasks.phone);
      expect(input.value, isNull);
    });

    test('.phone uses the phone mask and defaults autocomplete to tel', () {
      const input = FormattedInput.phone();
      expect(input.parts, equals(CoreFormattedInputMasks.phone));
      expect(input.autofillHints, equals(['tel']));
    });

    test(
      '.koreanPhone uses the Korean mobile mask and defaults autocomplete '
      'to tel',
      () {
        const input = FormattedInput.koreanPhone();
        expect(input.parts, equals(CoreFormattedInputMasks.koreanPhone));
        expect(input.autofillHints, equals(['tel']));
      },
    );

    test(
      '.creditCard uses the credit-card mask and defaults autocomplete to '
      'cc-number',
      () {
        const input = FormattedInput.creditCard();
        expect(input.parts, equals(CoreFormattedInputMasks.creditCard));
        expect(input.autofillHints, equals(['cc-number']));
      },
    );

    test('.date uses the date mask and has no autocomplete default', () {
      const input = FormattedInput.date();
      expect(input.parts, equals(CoreFormattedInputMasks.date));
      expect(input.autofillHints, isNull);
    });

    test('an explicit autofillHints overrides the .phone default', () {
      const input = FormattedInput.phone(autofillHints: ['username']);
      expect(input.autofillHints, equals(['username']));
    });
  });

  group('FormattedInput single real <input> architecture (Story #3869)', () {
    testComponents(
      'renders exactly one real <input> regardless of mask length',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.creditCard());
        // A single real input backs the whole field — no per-segment
        // `<input>` instances (the pre-#3869 architecture).
        expect(find.tag('input'), findsOneComponent);
      },
    );

    testComponents('renders leading / trailing composition slots', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FormattedInput.phone(
          leading: Text('+1'),
          trailing: Text('ext'),
        ),
      );
      expect(find.tag('input'), findsOneComponent);
      expect(find.text('+1'), findsOneComponent);
      expect(find.text('ext'), findsOneComponent);
    });

    testComponents(
      'seeds the <input> value attribute from the formatted value',
      (tester) async {
        pumpWithTheme(
          tester,
          const FormattedInput.phone(value: '3334567890'),
        );
        expect(_findInput().attributes?['value'], equals('(333) 456-7890'));
      },
    );

    testComponents(
      'omits the value attribute entirely for an empty/null value',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.phone());
        expect(_findInput().attributes?.containsKey('value'), isFalse);
      },
    );

    testComponents(
      'the placeholder shows the full mask shape, not a per-segment hint',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.phone());
        expect(
          _findInput().attributes?['placeholder'],
          equals('(___) ___-____'),
        );
      },
    );

    testComponents(
      'the placeholder for the Korean mobile mask is 3-4-4 (DDR-03)',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.koreanPhone());
        expect(
          _findInput().attributes?['placeholder'],
          equals('___-____-____'),
        );
      },
    );

    testComponents(
      'maxlength matches the fully-formatted mask length, not the raw '
      'digit capacity',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.phone());
        // '(333) 456-7890' — 14 characters including the 3 literals.
        expect(_findInput().attributes?['maxlength'], equals('14'));
      },
    );
  });

  group('FormattedInput autocomplete / inputmode attributes (DDR-04)', () {
    testComponents(
      '.phone renders autocomplete="tel"',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.phone());
        expect(_findInput().attributes?['autocomplete'], equals('tel'));
      },
    );

    testComponents(
      '.creditCard renders autocomplete="cc-number"',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.creditCard());
        expect(
          _findInput().attributes?['autocomplete'],
          equals('cc-number'),
        );
      },
    );

    testComponents(
      '.date has no autocomplete attribute by default',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.date());
        expect(_findInput().attributes?.containsKey('autocomplete'), isFalse);
      },
    );

    testComponents(
      'an explicit autofillHints list joins multiple tokens with a space',
      (tester) async {
        pumpWithTheme(
          tester,
          const FormattedInput(
            parts: CoreFormattedInputMasks.phone,
            autofillHints: ['tel', 'mobile'],
          ),
        );
        expect(
          _findInput().attributes?['autocomplete'],
          equals('tel mobile'),
        );
      },
    );

    testComponents(
      'digit-only masks (.phone) render inputmode="numeric"',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.phone());
        expect(_findInput().attributes?['inputmode'], equals('numeric'));
      },
    );

    testComponents(
      'a custom non-digit mask does not render inputmode="numeric"',
      (tester) async {
        pumpWithTheme(
          tester,
          const FormattedInput(
            parts: [
              CoreFormattedInputPart.editable(length: 2, pattern: '[A-Z]'),
              CoreFormattedInputPart.static('-'),
              CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
            ],
          ),
        );
        expect(
          _findInput().attributes?.containsKey('inputmode'),
          isFalse,
        );
      },
    );
  });

  group('FormattedInput disabled state', () {
    testComponents(
      'sets the disabled attribute and attaches no interaction events '
      'when enabled is false',
      (tester) async {
        pumpWithTheme(
          tester,
          const FormattedInput.phone(enabled: false),
        );
        final input = _findInput();
        expect(input.attributes?.containsKey('disabled'), isTrue);
        expect(input.events, anyOf(isNull, isEmpty));
      },
    );

    testComponents(
      'does not set the disabled attribute and attaches events when '
      'enabled is true',
      (tester) async {
        pumpWithTheme(tester, const FormattedInput.phone());
        final input = _findInput();
        expect(input.attributes?.containsKey('disabled'), isFalse);
        expect(input.events, isNotNull);
        expect(input.events, isNotEmpty);
      },
    );
  });

  group('FormattedInput segmentInputStyle — the surviving nested slot', () {
    testComponents(
      'segmentInputStyle is still fully applied to the single real input',
      (tester) async {
        final context = _themedContext(tester);
        const customValueStyle = CoreTextStyle(fontSize: 20);
        final resolved = resolveFormattedInput(
          context,
          enabled: true,
          focused: false,
          formattedInputStyle: const CoreFormattedInputStyle(
            segmentInputStyle: CoreTextFieldStyle(valueStyle: customValueStyle),
          ),
        );
        expect(
          resolved.field.inlineStyles?.properties['font-size'],
          equals('${20 / kRemDivisor}rem'),
        );
      },
    );
  });

  // The field fills its parent — the same rule every other text-entry field
  // follows, and what the Flutter twin does (its `Row` takes the available
  // width). A shrink-to-fit root (`inline-flex`) collapses to the `<input>`'s
  // own default width, so a wider parent never reaches the field.
  group('FormattedInput width — fills the parent', () {
    testComponents('the root row is a block-level, full-width flex row', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final enabled in [true, false]) {
        for (final focused in [true, false]) {
          final root = _classesOf(
            resolveFormattedInput(
              context,
              enabled: enabled,
              focused: focused,
            ).root.className,
          );
          final reason = 'enabled=$enabled focused=$focused';
          expect(
            root,
            containsAll(['flex', 'w-full', 'items-center']),
            reason: reason,
          );
          expect(root, isNot(contains('inline-flex')), reason: reason);
        }
      }
    });

    testComponents('the rendered root fills, with or without affixes', (
      tester,
    ) async {
      pumpWithTheme(tester, const FormattedInput.phone());
      var root = _classesOf(_findRoot().classes);
      expect(root, containsAll(['flex', 'w-full']));
      expect(root, isNot(contains('inline-flex')));

      pumpWithTheme(
        tester,
        const FormattedInput.phone(
          leading: Text('+1'),
          trailing: Text('ext'),
        ),
      );
      root = _classesOf(_findRoot().classes);
      expect(root, containsAll(['flex', 'w-full']));
      expect(root, isNot(contains('inline-flex')));
    });

    testComponents('the <input> takes the width the affixes leave over', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const FormattedInput.phone(
          leading: Text('+1'),
          trailing: Text('ext'),
        ),
      );
      expect(
        _classesOf(_findInput().classes),
        containsAll(['flex-1', 'min-w-0']),
      );
    });
  });

  group('FormattedInput chrome (#resolveFormattedInput)', () {
    testComponents('idle border uses the outline-variant token', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveFormattedInput(
        context,
        enabled: true,
        focused: false,
      );
      expect(resolved.root.className, contains('border-outline-variant'));
    });

    testComponents(
      'focused border switches to the primary focus-ring token',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveFormattedInput(
          context,
          enabled: true,
          focused: true,
        );
        expect(resolved.root.className, contains('border-primary'));
      },
    );

    // Was `disabled state adds the muted-opacity classes`, asserting
    // `opacity-50`. The disabled pair now comes from its own tokens —
    // an alpha survives a colour-forcing accessibility mode unchanged,
    // so a field dimmed that way keeps the enabled palette and reads as
    // enabled there. The cursor half is unchanged and still checked.
    // Further angles (disabled outranks focus; geometry stays shared)
    // live in `formatted_input_disabled_test.dart`.
    testComponents('disabled state swaps to the disabled tokens', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveFormattedInput(
        context,
        enabled: false,
        focused: false,
      );
      expect(resolved.root.className, contains('bg-disabled-container'));
      expect(resolved.root.className, contains('border-disabled-outline'));
      expect(resolved.root.className, isNot(contains('opacity-50')));
      expect(resolved.root.className, contains('cursor-not-allowed'));
    });

    testComponents(
      'a project-level CoreFormattedInputTheme.style override recolours '
      'the idle border',
      (tester) async {
        final themedData = ThemeData.coui.copyWith(
          coreComponentTheme: const CoreComponentTheme(
            formattedInput: CoreFormattedInputTheme(
              style: CoreFormattedInputStyle(
                borderColor: CoreColor.token(CoreColors.tertiary),
              ),
            ),
          ),
        );
        late BuildContext context;
        tester.pumpComponent(
          Theme(data: themedData, child: _ContextCapture((c) => context = c)),
        );
        final resolved = resolveFormattedInput(
          context,
          enabled: true,
          focused: false,
        );
        expect(resolved.root.className, contains('border-tertiary'));
      },
    );
  });
}
