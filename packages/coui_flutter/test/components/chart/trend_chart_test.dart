import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

List<CoreTrendPoint> _points(
  List<double> values, {
  String Function(int)? label,
}) => [
  for (var i = 0; i < values.length; i++)
    CoreTrendPoint(
      date: DateTime(2026, 1, i + 1),
      value: values[i],
      label: label?.call(i) ?? '1월 ${i + 1}일',
      valueLabel: '${values[i].toInt()}건',
    ),
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
  // Tall enough that the whole chart fits at 2x text — a real screen
  // scrolls, and the viewport is not what this suite measures.
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(800, 2400);
  addTearDown(tester.view.reset);
  // `buildTestApp` hosts the child in an `Overlay` whose initial entry is
  // built once, so a second pump in the same test would keep the first
  // tree. Clearing the tree first makes every pump a fresh mount.
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

void main() {
  group('TrendChart', () {
    testWidgets('no points renders the empty slot and no plot', (tester) async {
      await _pump(
        tester,
        const TrendChart(points: [], empty: Text('데이터 없음')),
      );
      expect(find.text('데이터 없음'), findsOneWidget);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('no points and no empty slot renders nothing extra', (
      tester,
    ) async {
      await _pump(tester, const TrendChart(points: []));
      expect(find.byType(Tooltip), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a single point renders one slot and one date label', (
      tester,
    ) async {
      await _pump(tester, TrendChart(points: _points([42])));
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.text('1월 1일'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('many points label only the first, middle and last date', (
      tester,
    ) async {
      await _pump(
        tester,
        TrendChart(points: _points([for (var i = 0; i < 30; i++) i * 3.0])),
      );
      expect(find.byType(Tooltip), findsNWidgets(30));
      expect(find.text('1월 1일'), findsOneWidget);
      expect(find.text('1월 15일'), findsOneWidget);
      expect(find.text('1월 30일'), findsOneWidget);
      expect(find.text('1월 2일'), findsNothing);
    });

    for (final variant in CoreTrendChartVariant.values) {
      testWidgets('${variant.name}: negative and zero values render', (
        tester,
      ) async {
        await _pump(
          tester,
          TrendChart(variant: variant, points: _points([-30, 0, 45, -5])),
        );
        expect(tester.takeException(), isNull);
        // The axis spans the sign change.
        expect(find.text('0'), findsOneWidget);
      });
    }

    testWidgets('long labels ellipsize instead of overflowing', (
      tester,
    ) async {
      await _pump(
        tester,
        TrendChart(
          points: _points(
            [1, 2, 3, 4, 5],
            label: (i) => '아주 긴 날짜 라벨이 들어가는 경우 $i 번째 항목',
          ),
          referenceValue: 3,
          referenceLabel: '목표치 — 아주 길게 설명된 기준선 라벨이 줄바꿈되는지 확인',
        ),
        width: 240,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the reference legend shows only with both value and label', (
      tester,
    ) async {
      await _pump(
        tester,
        TrendChart(points: _points([1, 2]), referenceValue: 2),
      );
      expect(find.text('목표'), findsNothing);
      await _pump(
        tester,
        TrendChart(
          points: _points([1, 2]),
          referenceValue: 2,
          referenceLabel: '목표',
        ),
      );
      expect(find.text('목표'), findsOneWidget);
    });

    testWidgets('period chips report the tapped index', (tester) async {
      int? tapped;
      await _pump(
        tester,
        TrendChart(
          points: _points([1, 2, 3]),
          periods: const ['7일', '30일', '12개월'],
          selectedPeriodIndex: 0,
          onPeriodChanged: (i) => tapped = i,
        ),
      );
      await tester.tap(find.text('12개월'));
      await tester.pump();
      expect(tapped, 2);
    });

    testWidgets('chips and summary stay visible when there are no points', (
      tester,
    ) async {
      await _pump(
        tester,
        const TrendChart(
          points: [],
          summary: Text('요약'),
          periods: ['7일', '30일'],
        ),
      );
      expect(find.text('요약'), findsOneWidget);
      expect(find.text('30일'), findsOneWidget);
    });

    testWidgets('a value formatter labels the axis', (tester) async {
      await _pump(
        tester,
        TrendChart(points: _points([0, 100]), valueFormatter: (v) => '₩$v'),
      );
      expect(find.textContaining('₩'), findsWidgets);
    });

    testWidgets('withStyle merges into trendChartStyle', (tester) async {
      final chart = TrendChart(
        points: _points([1]),
      ).withStyle(const CoreTrendChartStyle(plotHeight: 80));
      expect(chart.trendChartStyle?.plotHeight, 80);
    });

    testWidgets('plot height follows the style', (tester) async {
      await _pump(
        tester,
        TrendChart(
          points: _points([1, 2]),
          trendChartStyle: const CoreTrendChartStyle(plotHeight: 240),
        ),
      );
      final plot = tester.getSize(
        find
            .descendant(
              of: find.byType(TrendChart),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(plot.height, greaterThanOrEqualTo(240));
    });
  });

  group('TrendChart accessibility', () {
    testWidgets('the plot is named and each point reads date and value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        TrendChart(semanticLabel: '일별 문의 추이', points: _points([3, 7])),
      );
      expect(find.bySemanticsLabel('일별 문의 추이'), findsOneWidget);
      expect(find.bySemanticsLabel('1월 1일, 3건'), findsOneWidget);
      expect(find.bySemanticsLabel('1월 2일, 7건'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('fallback labels are locale-neutral', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        TrendChart(
          points: [CoreTrendPoint(date: DateTime(2026, 3, 7), value: 12)],
        ),
      );
      expect(find.bySemanticsLabel(RegExp('^2026-03-07, ')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('axis labels are hidden from assistive technology', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, TrendChart(points: _points([0, 50])));
      final root = tester.getSemantics(find.byType(TrendChart));
      var axisReachable = false;
      void visit(SemanticsNode node) {
        if (node.label == '50') axisReachable = true;
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(root);
      expect(axisReachable, isFalse);
      handle.dispose();
    });
  });

  group('TrendChart RTL', () {
    testWidgets('slots mirror: the first point sits at the right edge', (
      tester,
    ) async {
      await _pump(
        tester,
        TrendChart(points: _points([1, 2, 3])),
        textDirection: .rtl,
      );
      final tooltips = find.byType(Tooltip);
      final first = tester.getCenter(tooltips.at(0)).dx;
      final last = tester.getCenter(tooltips.at(2)).dx;
      expect(first, greaterThan(last));
      expect(tester.takeException(), isNull);
    });
  });

  group('TrendChart overflow matrix', () {
    for (final variant in CoreTrendChartVariant.values) {
      for (final scaling in [1.0, 1.25]) {
        for (final textScale in [1.0, 1.3, 2.0]) {
          for (final width in [240.0, 400.0]) {
            testWidgets(
              '${variant.name} · scaling $scaling · text $textScale · '
              'width $width',
              (tester) async {
                await _pump(
                  tester,
                  TrendChart(
                    variant: variant,
                    semanticLabel: '추이',
                    summary: const Stat(label: '합계', value: '12,480'),
                    periods: const ['7일', '30일', '12개월'],
                    selectedPeriodIndex: 1,
                    referenceValue: 40,
                    referenceLabel: '목표 40건',
                    points: _points([12, 47, 33, -8, 0, 25, 61]),
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

  group('TrendChart theme', () {
    testWidgets('variantStyles apply to the matching variant only', (
      tester,
    ) async {
      const theme = CoreComponentTheme(
        trendChart: CoreTrendChartTheme(
          variantStyles: {
            CoreTrendChartVariant.bar: CoreTrendChartStyle(plotHeight: 300),
          },
        ),
      );
      Future<double> heightOf(CoreTrendChartVariant variant) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              width: 360,
              child: TrendChart(variant: variant, points: _points([1, 2])),
            ),
            componentTheme: theme,
          ),
        );
        return tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(TrendChart),
                    matching: find.byType(CustomPaint),
                  )
                  .first,
            )
            .height;
      }

      final bar = await heightOf(.bar);
      final line = await heightOf(.line);
      expect(bar, greaterThanOrEqualTo(300));
      expect(line, lessThan(300), reason: 'line=$line bar=$bar');
    });
  });
}
