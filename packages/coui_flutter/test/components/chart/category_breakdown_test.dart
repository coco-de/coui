import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _items = [
  CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
  CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
  CoreCategoryBreakdownItem(label: '계정', value: 33, valueLabel: '33건'),
  CoreCategoryBreakdownItem(label: '기타', value: 0, valueLabel: '0건'),
];

/// Pumps [chart] at [width] with an ambient [textScale] and [theme].
Future<void> _pump(
  WidgetTester tester,
  Widget chart, {
  double width = 360,
  double textScale = 1,
  ThemeData? theme,
  TextDirection textDirection = .ltr,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(800, 2400);
  addTearDown(tester.view.reset);
  // `buildTestApp` hosts the child in an `Overlay` whose initial entry is
  // built once; clearing first makes every pump a fresh mount.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: SizedBox(width: width, child: chart),
        ),
      ),
      theme: theme,
      textDirection: textDirection,
    ),
  );
  await tester.pump();
}

double _fillWidth(WidgetTester tester, int index) => tester
    .getSize(
      find.descendant(
        of: find.byType(FractionallySizedBox).at(index),
        matching: find.byType(DecoratedBox),
      ),
    )
    .width;

void main() {
  group('CategoryBreakdown', () {
    testWidgets('no items renders the empty slot', (tester) async {
      await _pump(
        tester,
        const CategoryBreakdown(items: [], empty: Text('데이터 없음')),
      );
      expect(find.text('데이터 없음'), findsOneWidget);
    });

    testWidgets('a zero total is empty too', (tester) async {
      await _pump(
        tester,
        const CategoryBreakdown(
          items: [CoreCategoryBreakdownItem(label: 'A', value: 0)],
          empty: Text('데이터 없음'),
        ),
      );
      expect(find.text('데이터 없음'), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });

    testWidgets('a single item takes the whole bar at 100%', (tester) async {
      await _pump(
        tester,
        const CategoryBreakdown(
          items: [CoreCategoryBreakdownItem(label: 'A', value: 5)],
        ),
      );
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('rows show label, value and share; bars scale by share', (
      tester,
    ) async {
      await _pump(tester, const CategoryBreakdown(items: _items));
      expect(find.text('결제 문의'), findsOneWidget);
      expect(find.text('128건'), findsOneWidget);
      // 128 / 222 → 57.66 · 61 → 27.48 · 33 → 14.86 → 58 · 27 · 15 · 0.
      expect(find.text('58%'), findsOneWidget);
      expect(find.text('27%'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(_fillWidth(tester, 0), greaterThan(_fillWidth(tester, 1)));
      expect(_fillWidth(tester, 3), 0);
    });

    testWidgets('negative values count as zero', (tester) async {
      await _pump(
        tester,
        const CategoryBreakdown(
          items: [
            CoreCategoryBreakdownItem(label: 'A', value: -10),
            CoreCategoryBreakdownItem(label: 'B', value: 10),
          ],
        ),
      );
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long labels wrap instead of overflowing', (tester) async {
      for (final variant in CoreCategoryBreakdownVariant.values) {
        await _pump(
          tester,
          CategoryBreakdown(
            variant: variant,
            items: const [
              CoreCategoryBreakdownItem(
                label: '아주 긴 카테고리 이름이 들어가서 한 줄에 다 들어가지 않는 경우',
                value: 3,
                valueLabel: '1,234,567건',
              ),
              CoreCategoryBreakdownItem(label: 'B', value: 1),
            ],
          ),
          width: 220,
        );
        expect(tester.takeException(), isNull, reason: variant.name);
      }
    });

    testWidgets('donut: legend beside when wide, below when narrow', (
      tester,
    ) async {
      Future<(Offset, Offset)> positions(double width) async {
        await _pump(
          tester,
          const CategoryBreakdown(variant: .donut, items: _items),
          width: width,
        );
        return (
          tester.getTopLeft(find.byType(CustomPaint).first),
          tester.getTopLeft(find.text('결제 문의')),
        );
      }

      final (wideDonut, wideLabel) = await positions(480);
      expect(wideLabel.dx, greaterThan(wideDonut.dx + 160));
      final (narrowDonut, narrowLabel) = await positions(300);
      expect(narrowLabel.dy, greaterThan(narrowDonut.dy + 160));
    });

    testWidgets('both variants answer intrinsic-size queries', (tester) async {
      // A `Table` or `IntrinsicHeight` ancestor asks for intrinsic sizes;
      // a layout callback cannot answer them and would throw here.
      for (final variant in CoreCategoryBreakdownVariant.values) {
        await _pump(
          tester,
          IntrinsicHeight(
            child: CategoryBreakdown(variant: variant, items: _items),
          ),
        );
        expect(tester.takeException(), isNull, reason: variant.name);
      }
    });

    testWidgets('donut RTL: legend sits left of the donut', (tester) async {
      await _pump(
        tester,
        const CategoryBreakdown(variant: .donut, items: _items),
        width: 480,
        textDirection: .rtl,
      );
      expect(
        tester.getTopLeft(find.text('결제 문의')).dx,
        lessThan(tester.getTopLeft(find.byType(CustomPaint).first).dx),
      );
    });

    testWidgets('donut centre slot renders', (tester) async {
      await _pump(
        tester,
        const CategoryBreakdown(
          variant: .donut,
          items: _items,
          center: Text('222건'),
        ),
      );
      expect(find.text('222건'), findsOneWidget);
    });

    testWidgets('an item colour overrides the palette', (tester) async {
      await _pump(
        tester,
        const CategoryBreakdown(
          items: [
            CoreCategoryBreakdownItem(
              label: 'A',
              value: 1,
              color: CoreColor(0xFF123456),
            ),
          ],
        ),
      );
      final fill = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (fill.decoration as BoxDecoration).color,
        const Color(0xFF123456),
      );
    });

    testWidgets('withStyle merges into categoryBreakdownStyle', (
      tester,
    ) async {
      final chart = const CategoryBreakdown(
        items: _items,
      ).withStyle(const CoreCategoryBreakdownStyle(barHeight: 12));
      expect(chart.categoryBreakdownStyle?.barHeight, 12);
    });
  });

  group('CategoryBreakdown accessibility', () {
    for (final variant in CoreCategoryBreakdownVariant.values) {
      testWidgets('${variant.name}: each row reads label, value, share', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          CategoryBreakdown(
            variant: variant,
            semanticLabel: '문의 유형별 분포',
            items: _items,
          ),
        );
        expect(find.bySemanticsLabel('문의 유형별 분포'), findsOneWidget);
        expect(find.bySemanticsLabel('결제 문의, 128건, 58%'), findsOneWidget);
        expect(find.bySemanticsLabel('기타, 0건, 0%'), findsOneWidget);
        // The visible text is not read a second time.
        expect(find.bySemanticsLabel('128건'), findsNothing);
        handle.dispose();
      });
    }
  });

  group('CategoryBreakdown RTL', () {
    testWidgets('bars grow from the start (right) edge', (tester) async {
      await _pump(
        tester,
        const CategoryBreakdown(items: _items),
        textDirection: .rtl,
      );
      final track = tester.getRect(
        find
            .ancestor(
              of: find.byType(FractionallySizedBox).first,
              matching: find.byType(SizedBox),
            )
            .first,
      );
      final fill = tester.getRect(
        find
            .descendant(
              of: find.byType(FractionallySizedBox).first,
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(fill.right, closeTo(track.right, 0.01));
      expect(fill.left, greaterThan(track.left));
    });
  });

  group('CategoryBreakdown overflow matrix', () {
    for (final variant in CoreCategoryBreakdownVariant.values) {
      for (final scaling in [1.0, 1.25]) {
        for (final textScale in [1.0, 1.3, 2.0]) {
          for (final width in [240.0, 400.0]) {
            testWidgets(
              '${variant.name} · scaling $scaling · text $textScale · '
              'width $width',
              (tester) async {
                await _pump(
                  tester,
                  CategoryBreakdown(
                    variant: variant,
                    semanticLabel: '분포',
                    center: const Text('222건'),
                    items: _items,
                  ),
                  width: width,
                  textScale: textScale,
                  theme: AdaptiveScaling(scaling).scale(const ThemeData()),
                );
                expect(tester.takeException(), isNull);
              },
            );
          }
        }
      }
    }
  });

  group('CategoryBreakdown theme', () {
    testWidgets('variantStyles apply to the matching variant only', (
      tester,
    ) async {
      const theme = CoreComponentTheme(
        categoryBreakdown: CoreCategoryBreakdownTheme(
          variantStyles: {
            CoreCategoryBreakdownVariant.bar: CoreCategoryBreakdownStyle(
              barHeight: 20,
            ),
          },
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(width: 360, child: CategoryBreakdown(items: _items)),
          componentTheme: theme,
        ),
      );
      expect(
        tester.getSize(find.byType(FractionallySizedBox).first).height,
        20,
      );
    });
  });
}
