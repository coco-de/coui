import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// `CoreAccordionStyle.triggerStyle.backgroundColor` fills the trigger row
/// on both platforms. Before this, Web painted it (raw colours only) and
/// Flutter read only the padding, label and foreground of that style, so
/// the same accordion style drew a filled header on one platform and a
/// bare one on the other.
Future<void> _pump(WidgetTester tester, CoreAccordionStyle? style) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(
        child: SizedBox(
          width: 420,
          child: Accordion(
            accordionStyle: style,
            items: const [
              AccordionItem(title: 'Shipping', content: Text('Two days')),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _fill = CoreColor.token(CoreColors.surfaceContainer);

Iterable<Color> _fillsBehindTitle(WidgetTester tester) => tester
    .widgetList<ColoredBox>(
      find.ancestor(
        of: find.text('Shipping'),
        matching: find.byType(ColoredBox),
      ),
    )
    .map((box) => box.color);

Color _resolved(WidgetTester tester) => Theme.of(
  tester.element(find.text('Shipping')),
).colorScheme.resolve(_fill).toValue();

void main() {
  testWidgets('a trigger fill the caller states is painted behind the row', (
    tester,
  ) async {
    await _pump(
      tester,
      const CoreAccordionStyle(
        triggerStyle: CoreButtonStyle(backgroundColor: _fill),
      ),
    );

    expect(_fillsBehindTitle(tester), contains(_resolved(tester)));
  });

  testWidgets('without one the row paints no fill of its own', (tester) async {
    await _pump(tester, null);

    expect(_fillsBehindTitle(tester), isNot(contains(_resolved(tester))));
  });
}
