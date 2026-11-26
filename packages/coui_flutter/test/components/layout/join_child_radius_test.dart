import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(child: child),
  ),
);

/// Radius of the button's main chrome container (the animated state
/// decoration) — skips the focus-overlay boxes, which are invisible at
/// rest.
BorderRadius _buttonRadiusOf(WidgetTester tester, String label) {
  final decorated = tester
      .widgetList<material.AnimatedContainer>(
        find.descendant(
          of: find.widgetWithText(Button, label),
          matching: find.byType(material.AnimatedContainer),
        ),
      )
      .map((w) => w.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.borderRadius != null);
  return decorated.borderRadius! as BorderRadius;
}

void main() {
  testWidgets('Join squares the buttons\' own corners at the seams', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        Join(
          children: [
            Button(variant: .outline, onPressed: () {}, child: const Text('1')),
            Button(variant: .outline, onPressed: () {}, child: const Text('2')),
            Button(variant: .outline, onPressed: () {}, child: const Text('3')),
          ],
        ),
      ),
    );

    final first = _buttonRadiusOf(tester, '1');
    final middle = _buttonRadiusOf(tester, '2');
    final last = _buttonRadiusOf(tester, '3');

    // Middle item paints fully squared — no notch at either seam.
    expect(middle, BorderRadius.zero);
    // First keeps only its leading corners, last only its trailing ones.
    expect(first.topLeft, isNot(Radius.zero));
    expect(first.topRight, Radius.zero);
    expect(first.bottomRight, Radius.zero);
    expect(last.topLeft, Radius.zero);
    expect(last.bottomLeft, Radius.zero);
    expect(last.topRight, isNot(Radius.zero));
  });

  testWidgets('Join squares a middle TextField too', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        material.SizedBox(
          width: 480,
          child: Join(
            children: [
              Button(
                variant: .outline,
                onPressed: () {},
                child: const Text('L'),
              ),
              material.SizedBox(width: 200, child: TextField()),
              Button(
                variant: .outline,
                onPressed: () {},
                child: const Text('R'),
              ),
            ],
          ),
        ),
      ),
    );

    // The field's main chrome box (the bordered decoration) paints
    // fully squared between two neighbours.
    final fieldRadius = tester
        .widgetList<material.DecoratedBox>(
          find.descendant(
            of: find.byType(TextField),
            matching: find.byType(material.DecoratedBox),
          ),
        )
        .map((w) => w.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.border != null)
        .borderRadius;
    expect(fieldRadius, BorderRadius.zero);
  });

  testWidgets('a lone Button keeps its own radius outside a Join', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        Button(variant: .outline, onPressed: () {}, child: const Text('솔로')),
      ),
    );
    final radius = _buttonRadiusOf(tester, '솔로');
    expect(radius.topLeft, isNot(Radius.zero));
    expect(radius.bottomRight, isNot(Radius.zero));
  });
}
