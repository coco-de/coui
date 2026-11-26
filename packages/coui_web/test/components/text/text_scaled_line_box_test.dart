import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Arbitrary factor — not a token.
const _kTestScaler = 2.0;

/// The single `<span>` a bare `Text` chain renders.
DomComponent _span(ComponentTester tester) =>
    find.byType(DomComponent).evaluate().single.component as DomComponent;

void main() {
  // #5496 — a role with a fixed line box grows that box with the component's
  // text scale, as Flutter's does. The factor rides `--coui-text-scale`; the
  // role class multiplies only a length box by it (`ThemeConfig`), which was
  // measured in Chrome: code-md at 2 → 26px on a 42px line, a nested code
  // span keeps 21px, and body-medium stays a 1.5 multiplier.
  testComponents('a scaled role states the scale for its line box', (
    tester,
  ) async {
    pumpWithTheme(tester, const Text('x', textScaler: _kTestScaler).codeMd);

    final styles = _span(tester).styles?.properties ?? const {};
    expect(styles['--coui-text-scale'], '$_kTestScaler');
    expect(styles.containsKey('line-height'), isFalse);
  });

  testComponents('an unscaled role states no scale', (tester) async {
    pumpWithTheme(tester, const Text('x').codeMd);

    final styles = _span(tester).styles?.properties ?? const {};
    expect(styles.containsKey('--coui-text-scale'), isFalse);
  });
}
