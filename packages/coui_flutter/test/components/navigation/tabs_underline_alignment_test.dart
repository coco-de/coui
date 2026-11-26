import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = ['Selected', 'Inactive', 'Disabled'];

Widget _app({
  required CoreTabsSize size,
  required CoreDensity density,
  required double thickness,
  double textScale = 1,
  bool closable = false,
  TextDirection direction = .ltr,
}) => CoUIApp(
  theme: const ThemeData(),
  density: density,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: direction,
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Tabs(
              variant: .underline,
              size: size,
              selectedIndex: 0,
              onChanged: (_) {},
              tabsStyle: CoreTabsStyle(activeIndicatorThickness: thickness),
              tabs: [
                for (final label in _labels)
                  CoreTabItem<Widget>(
                    label: label,
                    enabled: label != 'Disabled',
                    onClose: closable ? () {} : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);

void _expectCentered(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final label in _labels) {
    final text = find.text(label);
    final face = find
        .ancestor(of: text, matching: find.byType(AnimatedContainer))
        .first;
    final textRect = tester.getRect(text);
    final faceRect = tester.getRect(face);
    expect(
      textRect.top - faceRect.top,
      closeTo(faceRect.bottom - textRect.bottom, 0.01),
      reason:
          '$label must be centered in the whole tab, including its underline',
    );
  }
}

void main() {
  for (final size in CoreTabsSize.values) {
    for (final density in CoreDensity.values) {
      for (final thickness in [0.0, 2.0, 6.0]) {
        testWidgets(
          '${size.name}/${density.name}: underline $thickness does not move labels',
          (tester) async {
            await tester.pumpWidget(
              _app(size: size, density: density, thickness: thickness),
            );
            await tester.pumpAndSettle();
            _expectCentered(tester);
          },
        );
      }
    }
  }

  for (final direction in TextDirection.values) {
    for (final textScale in [1.0, 2.0]) {
      for (final closable in [false, true]) {
        testWidgets(
          '${direction.name}/text$textScale/close$closable: full-height label center',
          (tester) async {
            await tester.pumpWidget(
              _app(
                size: .md,
                density: .standard,
                thickness: 2,
                textScale: textScale,
                closable: closable,
                direction: direction,
              ),
            );
            await tester.pumpAndSettle();
            _expectCentered(tester);
          },
        );
      }
    }
  }
}
