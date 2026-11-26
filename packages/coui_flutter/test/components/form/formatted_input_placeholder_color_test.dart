import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    for (final enabled in [false, true]) {
      testWidgets('nested placeholder color paints with dark=$dark, '
          'enabled=$enabled', (tester) async {
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: ThemeData.fromCore(
                dark ? CoreThemePresets.dark : CoreThemePresets.light,
              ),
              child: FormattedInput.phone(
                enabled: enabled,
                formattedInputStyle: const CoreFormattedInputStyle(
                  segmentInputStyle: CoreTextFieldStyle(
                    placeholderStyle: CoreTextStyle(
                      color: CoreColor(0xFF123456),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final placeholder = find.text('(___) ___-____');
        expect(placeholder, findsOneWidget);
        expect(
          DefaultTextStyle.of(tester.element(placeholder)).style.color,
          const Color(0xFF123456),
        );
      });
    }
  }
}
