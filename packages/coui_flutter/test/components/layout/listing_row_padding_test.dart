import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _firstKey = ValueKey<String>('first');

void main() {
  group('ListRow padding', () {
    testWidgets('rows reach the container edge and keep 12 above and below', (
      tester,
    ) async {
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            scaling = Theme.of(context).scaling;
            return const SizedBox(
              width: 300,
              child: Listing(
                children: [
                  ListRow(
                    children: [
                      ListCol(child: Icon(LucideIcons.x, key: _firstKey)),
                      ListCol(child: Text('Row')),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final listing = tester.getRect(find.byType(Listing));
      final first = tester.getRect(find.byKey(_firstKey));

      expect(first.left, moreOrLessEquals(listing.left, epsilon: 0.01));
      expect(
        first.top - listing.top,
        greaterThanOrEqualTo(CoreSpace.space12 * scaling - 0.01),
      );
      expect(
        tester.getSize(find.byType(ListRow)).height,
        greaterThanOrEqualTo(2 * CoreSpace.space12 * scaling),
      );
    });
  });

  group('Listing row rule', () {
    Widget rows({bool? itemBorder}) => SizedBox(
      width: 300,
      child: Listing(
        itemBorder: itemBorder,
        children: const [
          ListRow(children: [ListCol(child: Text('A'))]),
          ListRow(children: [ListCol(child: Text('B'))]),
          ListRow(children: [ListCol(child: Text('C'))]),
        ],
      ),
    );

    testWidgets('a Divider sits between rows when nothing is stated', (
      tester,
    ) async {
      await pumpTestApp(tester, rows());

      // Three rows, two gaps — none above the first or below the last.
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('itemBorder: false draws no rule', (tester) async {
      await pumpTestApp(tester, rows(itemBorder: false));

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('the rule paints the Divider default, outlineVariant', (
      tester,
    ) async {
      late Color expected;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            expected = Theme.of(
              context,
            ).colorScheme.resolve(CoreDividerStyle.defaultColor).toValue();
            return rows();
          },
        ),
      );

      final painted = <Color>{
        for (final box in tester.widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(Divider),
            matching: find.byType(ColoredBox),
          ),
        ))
          box.color,
        for (final box in tester.widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Divider),
            matching: find.byType(DecoratedBox),
          ),
        ))
          if ((box.decoration as BoxDecoration).color != null)
            (box.decoration as BoxDecoration).color!,
      };
      expect(painted, contains(expected));
    });
  });
}
