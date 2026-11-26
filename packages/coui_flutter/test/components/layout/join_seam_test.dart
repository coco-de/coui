import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(
  material.Widget child, {
  TextDirection direction = TextDirection.ltr,
}) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Directionality(
      textDirection: direction,
      child: Center(child: child),
    ),
  ),
);

Join _strip({bool vertical = false, CoreJoinStyle? joinStyle}) => Join(
  vertical: vertical,
  joinStyle: joinStyle,
  children: [
    Button(variant: .outline, onPressed: () {}, child: const Text('1')),
    Button(variant: .outline, onPressed: () {}, child: const Text('2')),
    Button(variant: .outline, onPressed: () {}, child: const Text('3')),
  ],
);

Rect _rectOf(WidgetTester tester, String label) =>
    tester.getRect(find.widgetWithText(Button, label));

void main() {
  const overlap = CoreJoinStyle.defaultItemOverlap;

  testWidgets('each item overlaps the one before it by one border', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(_strip()));

    final one = _rectOf(tester, '1');
    final two = _rectOf(tester, '2');
    final three = _rectOf(tester, '3');
    expect(two.left, moreOrLessEquals(one.right - overlap));
    expect(three.left, moreOrLessEquals(two.right - overlap));

    // The strip is as wide as what it paints — the overlaps come out.
    final strip = tester.getRect(find.byType(Join));
    expect(strip.left, moreOrLessEquals(one.left));
    expect(strip.right, moreOrLessEquals(three.right));
  });

  testWidgets('a vertical strip overlaps along its height', (tester) async {
    await tester.pumpWidget(_buildApp(_strip(vertical: true)));

    final one = _rectOf(tester, '1');
    final two = _rectOf(tester, '2');
    expect(two.top, moreOrLessEquals(one.bottom - overlap));
    final strip = tester.getRect(find.byType(Join));
    expect(strip.bottom, moreOrLessEquals(_rectOf(tester, '3').bottom));
  });

  testWidgets('a right-to-left strip overlaps toward its own start', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(_strip(), direction: TextDirection.rtl),
    );

    final one = _rectOf(tester, '1');
    final two = _rectOf(tester, '2');
    final three = _rectOf(tester, '3');
    expect(two.right, moreOrLessEquals(one.left + overlap));
    expect(three.right, moreOrLessEquals(two.left + overlap));
    final strip = tester.getRect(find.byType(Join));
    expect(strip.right, moreOrLessEquals(one.right));
    expect(strip.left, moreOrLessEquals(three.left));
  });

  // A parent that sizes the strip by its intrinsic width hands back exactly
  // that much room — the docs preview and the parity capture do. The strip
  // must fit it without the flex inside reporting an overflow.
  for (final vertical in [false, true]) {
    testWidgets('sized to its own intrinsic extent it does not overflow '
        '(vertical: $vertical)', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          vertical
              ? IntrinsicHeight(child: _strip(vertical: true))
              : IntrinsicWidth(child: _strip()),
        ),
      );

      expect(tester.takeException(), isNull);
      final strip = tester.getRect(find.byType(Join));
      final first = _rectOf(tester, '1');
      final last = _rectOf(tester, '3');
      if (vertical) {
        expect(strip.height, moreOrLessEquals(last.bottom - first.top));
      } else {
        expect(strip.width, moreOrLessEquals(last.right - first.left));
      }
    });
  }

  testWidgets('itemOverlap 0 lays the items edge to edge', (tester) async {
    await tester.pumpWidget(
      _buildApp(_strip(joinStyle: const CoreJoinStyle(itemOverlap: 0))),
    );

    expect(
      _rectOf(tester, '2').left,
      moreOrLessEquals(_rectOf(tester, '1').right),
    );
  });
}
