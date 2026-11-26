import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _childKey = ValueKey<String>('child');
const _itemKey = ValueKey<String>('item');

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

Widget _indicator({
  double child = 40,
  double item = 8,
  CoreIndicatorStyle? style,
  CoreIndicatorHorizontalPosition h = CoreIndicatorHorizontalPosition.end,
  CoreIndicatorVerticalPosition v = CoreIndicatorVerticalPosition.top,
}) {
  return Indicator(
    horizontalPosition: h,
    verticalPosition: v,
    indicatorStyle: style,
    item: SizedBox(key: _itemKey, width: item, height: item),
    child: SizedBox(key: _childKey, width: child, height: child),
  );
}

void main() {
  group('Indicator', () {
    for (final size in [24.0, 40.0, 96.0]) {
      testWidgets('the item corner meets the child corner (child $size)', (
        tester,
      ) async {
        await tester.pumpWidget(_app(_indicator(child: size)));
        final child = tester.getRect(find.byKey(_childKey));
        final item = tester.getRect(find.byKey(_itemKey));
        expect(item.topRight, child.topRight);
      });
    }

    testWidgets('the ring overhangs the item by its width', (tester) async {
      await tester.pumpWidget(_app(_indicator()));
      final item = tester.getRect(find.byKey(_itemKey));
      final ring = tester.getRect(
        find
            .ancestor(
              of: find.byKey(_itemKey),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(ring.topRight - item.topRight, const Offset(2, -2));
      expect(ring.size, Size(item.width + 4, item.height + 4));
    });

    testWidgets('the ring corner comes from the style, pill by default', (
      tester,
    ) async {
      BorderRadius ringRadius() {
        final box = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.byKey(_itemKey),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return ((box.decoration as ShapeDecoration).shape
                as RoundedRectangleBorder)
            .borderRadius
            .resolve(TextDirection.ltr);
      }

      await tester.pumpWidget(_app(_indicator()));
      expect(
        ringRadius(),
        BorderRadius.circular(CoreRadius.radius9999),
      );
      await tester.pumpWidget(
        _app(
          _indicator(
            style: const CoreIndicatorStyle(
              ringBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
            ),
          ),
        ),
      );
      expect(ringRadius(), BorderRadius.circular(CoreRadius.radius4));
    });

    testWidgets('ringWidth 0 draws no ring and leaves the item in place', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_indicator(style: const CoreIndicatorStyle(ringWidth: 0))),
      );
      final child = tester.getRect(find.byKey(_childKey));
      final item = tester.getRect(find.byKey(_itemKey));
      expect(item.topRight, child.topRight);
      expect(
        find.descendant(
          of: find.byType(Indicator),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    });

    testWidgets('offset pulls the item in from the corner', (tester) async {
      await tester.pumpWidget(
        _app(_indicator(style: const CoreIndicatorStyle(offset: 4))),
      );
      final child = tester.getRect(find.byKey(_childKey));
      final item = tester.getRect(find.byKey(_itemKey));
      expect(item.topRight, child.topRight + const Offset(-4, 4));
    });
  });
}
