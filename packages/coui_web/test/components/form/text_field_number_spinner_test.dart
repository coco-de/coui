// A number input's native spinner is dropped.
//
// Chrome puts a ~15px up/down control inside `<input type="number">` and keeps
// that space reserved when the control is not shown, so a value centred in the
// field sat about 7px left of the middle of a `NumberInput` — whose input is
// exactly the width between its `−` / `+` buttons. The Flutter twin has no such
// control, and `NumberInput` steps with its own buttons.
library;

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
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

Iterable<DomComponent> _inputs() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((c) => c.tag == 'input');

void main() {
  group('the scoped rule', () {
    testComponents('drops the native spinner of the marked input', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final css = resolveTextFieldRules(
        context,
        scopeId: 'tf',
        stateLayerId: 'tf-box',
        hasError: false,
        enabled: true,
        numeric: true,
      ).css;

      expect(css, contains(kTextFieldNumberRule));
      expect(css, contains('::-webkit-inner-spin-button'));
      expect(css, contains('::-webkit-outer-spin-button'));
      expect(css, contains('appearance:textfield'));
    });

    testComponents('is not written for any other input type', (tester) async {
      final context = _themedContext(tester);

      final css = resolveTextFieldRules(
        context,
        scopeId: 'tf',
        stateLayerId: 'tf-box',
        hasError: false,
        enabled: true,
      ).css;

      expect(css, isNot(contains('spin-button')));
    });
  });

  group('the input', () {
    testComponents('a number field carries the marker class', (tester) async {
      pumpWithTheme(tester, const TextField(type: CoreInputType.number));

      expect(
        _inputs().single.classes!.split(' '),
        contains(kTextFieldNumberClass),
      );
    });

    testComponents('a text field does not', (tester) async {
      pumpWithTheme(tester, const TextField());

      expect(
        _inputs().single.classes!.split(' '),
        isNot(contains(kTextFieldNumberClass)),
      );
    });

    testComponents('a NumberInput\'s field carries it', (tester) async {
      pumpWithTheme(tester, NumberInput(value: 2));

      expect(
        _inputs().single.classes!.split(' '),
        contains(kTextFieldNumberClass),
      );
    });
  });
}
