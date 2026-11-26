import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  testComponents(
    'number slot reaches the real input CSS without changing behavior',
    (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const PhoneInput(
          initialCountry: CoreCountry.unitedStates,
          initialNumber: '2025550151',
          phoneInputStyle: CorePhoneInputStyle(
            numberFieldStyle: CoreTextFieldStyle(
              valueStyle: CoreTextStyle(
                fontSize: 17,
                fontWeight: 600,
                lineHeight: 1.4,
              ),
            ),
          ),
        ),
      );
      final field =
          find.byType(TextField).evaluate().single.component as TextField;
      expect(field.textFieldStyle?.valueStyle?.fontSize, 17);
      expect(field.textFieldStyle?.valueStyle?.fontWeight, 600);
      expect(field.textFieldStyle?.borderWidth, 0);
      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.styles?.properties['font-size'], '1.0625rem');
      expect(input.styles?.properties['font-weight'], '600');
      expect(input.attributes?['type'], 'tel');
      expect(input.attributes?['value'], '2025550151');
    },
  );

  testComponents('absent number slot preserves the chromeless disabled input', (
    tester,
  ) async {
    pumpWithTheme(tester, const PhoneInput(enabled: false));
    final field =
        find.byType(TextField).evaluate().single.component as TextField;
    expect(field.textFieldStyle?.valueStyle, isNull);
    expect(field.textFieldStyle?.borderWidth, 0);
    expect(field.enabled, isFalse);
  });
}
