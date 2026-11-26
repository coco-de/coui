import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

// Keyboard-driven value changes (`_handleKeyDown`) aren't covered here —
// `dart test` runs this suite on the VM, and `universal_web`'s
// `KeyboardEvent.key` getter throws `Unsupported operation` outside a
// real browser/JS environment (no `dart_test.yaml` chrome platform is
// configured in this package). What's testable on the VM — the
// structural wiring that makes the control keyboard-*reachable* in the
// first place — is covered below.
const _kInitialValue = 50.0;

Slider _widget(ComponentTester tester) =>
    find.byType(Slider).evaluate().first.component as Slider;

void main() {
  group('Slider', () {
    testComponents('interactive root carries tabindex="0"', (tester) async {
      pumpWithTheme(
        tester,
        Slider(onChanged: (_) {}, value: _kInitialValue),
      );

      expect(_widget(tester).componentAttributes['tabindex'], '0');
    });

    testComponents('non-interactive slider has no tabindex', (tester) async {
      pumpWithTheme(tester, Slider(value: _kInitialValue));

      expect(
        _widget(tester).componentAttributes.containsKey('tabindex'),
        isFalse,
      );
    });

    testComponents('disabled slider has no tabindex', (tester) async {
      pumpWithTheme(
        tester,
        Slider(onChanged: (_) {}, value: _kInitialValue, enabled: false),
      );

      expect(
        _widget(tester).componentAttributes.containsKey('tabindex'),
        isFalse,
      );
    });
  });
}
