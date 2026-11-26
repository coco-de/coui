// The frame's ring is the ChipInput's focus indicator. The `TextField` inside
// it is chromeless, and a chromeless field that keeps its focus border draws a
// second, `primary`, box around the line being typed on — read back here from
// the borders the field actually paints, at rest and focused.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The borders the inline entry field paints right now.
List<Border> _innerBorders(WidgetTester tester) => [
  for (final box in tester.widgetList<Container>(
    find.descendant(
      of: find.byType(TextField),
      matching: find.byType(Container),
    ),
  ))
    for (final decoration in [box.decoration, box.foregroundDecoration])
      if (decoration is BoxDecoration && decoration.border is Border)
        decoration.border! as Border,
];

void main() {
  testWidgets('focusing the input paints no border around it', (tester) async {
    await tester.pumpWidget(
      material.MaterialApp(
        home: material.Scaffold(
          body: Theme(
            data: const ThemeData(),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: ChipInput(
                  chips: const ['Flutter', 'Dart'],
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      _innerBorders(tester).where((b) => b.top.color.a > 0),
      isEmpty,
      reason: 'at rest the entry field paints no visible edge',
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(
      _innerBorders(tester).where((b) => b.top.color.a > 0),
      isEmpty,
      reason: 'focused, the frame\'s ring says so — not a box on the input',
    );
  });
}
