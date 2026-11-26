import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {CorePhoneInputStyle? style}) => material.MaterialApp(
  home: Theme(
    data: ThemeData(
      coreComponentTheme: CoreComponentTheme(
        phoneInput: CorePhoneInputTheme(style: style),
      ),
    ),
    child: child,
  ),
);

void main() {
  testWidgets(
    'number slot paints typography while preserving input semantics',
    (
      tester,
    ) async {
      PhoneNumber? reported;
      await tester.pumpWidget(
        _app(
          PhoneInput(
            initialCountry: CoreCountry.unitedStates,
            onChanged: (value) => reported = value,
            phoneInputStyle: const CorePhoneInputStyle(
              numberFieldStyle: CoreTextFieldStyle(
                valueStyle: CoreTextStyle(fontSize: 17, fontWeight: 600),
              ),
            ),
          ),
          style: const CorePhoneInputStyle(
            numberFieldStyle: CoreTextFieldStyle(
              valueStyle: CoreTextStyle(lineHeight: 1.4),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '2025550151');
      await tester.pumpAndSettle();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontSize, 17);
      expect(editable.style.fontWeight, FontWeight.w600);
      expect(editable.style.height, 1.4);
      expect(editable.keyboardType, TextInputType.phone);
      expect(editable.readOnly, isFalse);
      expect(reported?.fullNumber, '+12025550151');
      final inner = tester.widget<TextField>(find.byType(TextField));
      expect(inner.textFieldStyle?.borderWidth, 0);
      expect(inner.textFieldStyle?.borderColor, CoreColor.transparent);
    },
  );

  testWidgets('absent slot keeps existing typography and disabled semantics', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const PhoneInput(enabled: false)));
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    // The number reads at the dial code's size (bodyLarge).
    expect(editable.style.fontSize, 15);
    expect(editable.style.fontWeight, FontWeight.w400);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('custom typography respects scaling and disabled input', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SizedBox(
            width: 320,
            child: PhoneInput(
              enabled: false,
              initialNumber: '2025550151',
              phoneInputStyle: CorePhoneInputStyle(
                numberFieldStyle: CoreTextFieldStyle(
                  valueStyle: CoreTextStyle(fontSize: 17, fontWeight: 600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.style.fontSize, 17);
    final state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.renderEditable.textScaler.scale(17), 34);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
