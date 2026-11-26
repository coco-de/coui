// The country list is a combobox's listbox (#3968 · #4154): focus stays in
// the search field and the arrows move a highlight the field names through
// `aria-activedescendant`. That highlight must be visible, not only
// announced — it paints with the row's hover colour on `aria-selected`, on
// both the token path (a Tailwind `aria-selected:` class) and the raw path
// (a scoped `[aria-selected="true"]` rule, never a throwing
// `.tailwindColor`).
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.text('');
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

const _kScopeId = 'test';

void main() {
  testComponents('the keyboard highlight paints with the hover token', (
    tester,
  ) async {
    final context = _themedContext(tester);
    final resolved = resolvePhoneInput(
      context,
      enabled: true,
      scopeId: _kScopeId,
    );
    final classes = resolved.dropdownItem.className.split(' ');
    final hover = classes.firstWhere((c) => c.startsWith('hover:bg-'));

    expect(
      classes,
      contains(hover.replaceFirst('hover:', 'aria-selected:')),
      reason: 'pointer hover and keyboard highlight are one colour',
    );
  });

  testComponents('a raw hover override paints the highlight through a scoped '
      'rule instead of a class', (tester) async {
    final context = _themedContext(tester);
    const style = CorePhoneInputStyle(hoverColor: CoreColor(0xFF00FF00));
    final resolved = resolvePhoneInput(
      context,
      enabled: true,
      scopeId: _kScopeId,
      phoneInputStyle: style,
    );
    final rules = resolvePhoneInputRules(
      context,
      scopeId: _kScopeId,
      phoneInputStyle: style,
    );

    expect(resolved.dropdownItem.className, isNot(contains('aria-selected:')));
    expect(
      rules.css,
      contains(
        '.co-phone-input-h-test[aria-selected="true"]'
        '{background-color: rgb(0, 255, 0);}',
      ),
    );
  });
}
