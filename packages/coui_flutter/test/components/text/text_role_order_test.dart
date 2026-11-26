import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The text style the chain's `RichText` paints with.
TextStyle _paintedStyle(WidgetTester tester) =>
    tester.widget<RichText>(find.byType(RichText).first).text.style!;

Future<TextStyle> _pump(WidgetTester tester, Widget chain) async {
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Center(child: chain),
      ),
    ),
  );
  return _paintedStyle(tester);
}

void main() {
  // #5495 — the Flutter half of the table `text_role_order_test.dart` pins on
  // Web: a role chained after a primitive replaces the size, weight, line
  // height and family that primitive set; letter spacing and slant survive.
  group('a role chained after a primitive replaces it (#5495)', () {
    testWidgets('size, line height and family come from the role', (
      tester,
    ) async {
      final role = await _pump(tester, const Text('x').codeSm);
      final chained = await _pump(tester, const Text('x').s20.sans.h180.codeSm);
      expect(chained.fontSize, role.fontSize);
      expect(chained.height, role.height);
      expect(chained.fontFamily, role.fontFamily);
    });

    testWidgets('weight comes from the role', (tester) async {
      final role = await _pump(tester, const Text('x').bodyMedium);
      final chained = await _pump(tester, const Text('x').bold.bodyMedium);
      expect(chained.fontWeight, role.fontWeight);
    });

    testWidgets('letter spacing and slant survive the role', (tester) async {
      final role = await _pump(tester, const Text('x').codeMd);
      final spaced = await _pump(tester, const Text('x').tighter.codeMd);
      expect(spaced.letterSpacing, isNot(role.letterSpacing));
      final slanted = await _pump(tester, const Text('x').italic.bodyMedium);
      expect(slanted.fontStyle, FontStyle.italic);
    });
  });
}
