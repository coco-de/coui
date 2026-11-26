// Resolver rules run through `testComponents` (they need a themed
// context); markup claims — roles, accessible names, which elements exist
// — run through `testServer`, because only the SSR binding hands back the
// document the browser and assistive technology read.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' as server;

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

List<CoreTrendPoint> _points(List<double> values) => [
  for (var i = 0; i < values.length; i++)
    CoreTrendPoint(
      date: DateTime(2026, 1, i + 1),
      value: values[i],
      label: '1월 ${i + 1}일',
      valueLabel: '${values[i].toInt()}건',
    ),
];

Map<String, String> _props(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

void main() {
  group('resolveTrendChart', () {
    testComponents('a bar per point, positioned with logical properties', (
      tester,
    ) async {
      final resolved = resolveTrendChart(
        _themedContext(tester),
        variant: .bar,
        points: _points([10, 20, 30, 40]),
      );
      expect(resolved.bars, hasLength(4));
      final first = _props(resolved.bars.first);
      // Logical inset → mirrors under dir="rtl" without a second code path.
      expect(first.containsKey('inset-inline-start'), isTrue);
      expect(first.containsKey('left'), isFalse);
      expect(first['width'], contains('calc(25.000%'));
      expect(resolved.bars.first.className, contains('bg-primary'));
    });

    testComponents('negative bars round their bottom corners', (tester) async {
      final resolved = resolveTrendChart(
        _themedContext(tester),
        variant: .bar,
        points: _points([-10, 10]),
      );
      expect(
        _props(resolved.bars[0]).containsKey('border-bottom-left-radius'),
        isTrue,
      );
      expect(
        _props(resolved.bars[1]).containsKey('border-top-left-radius'),
        isTrue,
      );
    });

    testComponents('a line variant draws no bars and a polyline', (
      tester,
    ) async {
      final resolved = resolveTrendChart(
        _themedContext(tester),
        variant: .line,
        points: _points([0, 100]),
      );
      expect(resolved.bars, isEmpty);
      // Slot centres at 25% / 75%; the values hit the bottom and top.
      expect(resolved.series.linePoints, '25.000,100.000 75.000,0.000');
      expect(resolved.line.className, contains('rtl:-scale-x-100'));
    });

    testComponents('geometry matches the shared Core computation', (
      tester,
    ) async {
      final points = _points([12, 47, 33]);
      final resolved = resolveTrendChart(
        _themedContext(tester),
        variant: .line,
        points: points,
      );
      final geometry = CoreTrendChartGeometry.compute(
        values: [for (final p in points) p.value],
        variant: .line,
        tickCount: CoreTrendChartStyle.defaultAxisTickCount,
      );
      expect(resolved.gridLines, hasLength(geometry.ticks.length));
      expect(
        resolved.series.tickLabels,
        geometry.ticks.reversed.map(geometry.formatTick).toList(),
      );
    });

    testComponents('point labels read date then value', (tester) async {
      final resolved = resolveTrendChart(
        _themedContext(tester),
        variant: .line,
        points: _points([3, 7]),
      );
      expect(resolved.series.pointLabels, ['1월 1일, 3건', '1월 2일, 7건']);
    });

    testComponents('date labels: start, centre, end', (tester) async {
      final resolved = resolveTrendChart(
        _themedContext(tester),
        variant: .line,
        points: _points([for (var i = 0; i < 9; i++) i.toDouble()]),
      );
      expect(resolved.series.dateLabels, ['1월 1일', '1월 5일', '1월 9일']);
      expect(resolved.dateLabels[0].className, contains('text-start'));
      expect(resolved.dateLabels[1].className, contains('text-center'));
      expect(resolved.dateLabels[2].className, contains('text-end'));
    });

    testComponents('no reference value → no reference element', (
      tester,
    ) async {
      final context = _themedContext(tester);
      expect(
        resolveTrendChart(
          context,
          variant: .line,
          points: _points([1, 2]),
        ).reference,
        isNull,
      );
      expect(
        resolveTrendChart(
          context,
          variant: .line,
          points: _points([1, 2]),
          referenceValue: 2,
        ).reference,
        isNotNull,
      );
    });

    testComponents('a raw colour override goes inline, not into a class', (
      tester,
    ) async {
      final resolved = resolveTrendChart(
        _themedContext(tester),
        variant: .bar,
        points: _points([1]),
        trendChartStyle: const CoreTrendChartStyle(
          seriesColor: CoreColor(0xFF112233),
        ),
      );
      expect(resolved.bars.first.className, isNot(contains('bg-')));
      expect(_props(resolved.bars.first)['background-color'], isNotNull);
    });

    testComponents('plot height follows the style in rem', (tester) async {
      final resolved = resolveTrendChart(
        _themedContext(tester),
        variant: .line,
        points: _points([1]),
        trendChartStyle: const CoreTrendChartStyle(plotHeight: 240),
      );
      expect(_props(resolved.plot)['min-height'], '15.0rem');
    });

    testComponents('theme variantStyles reach only their variant', (
      tester,
    ) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              trendChart: CoreTrendChartTheme(
                variantStyles: {
                  CoreTrendChartVariant.bar: CoreTrendChartStyle(
                    plotHeight: 320,
                  ),
                },
              ),
            ),
          ),
          child: _ContextCapture((c) => context = c),
        ),
      );
      expect(
        _props(
          resolveTrendChart(context, variant: .bar, points: _points([1])).plot,
        )['min-height'],
        '20.0rem',
      );
      expect(
        _props(
          resolveTrendChart(context, variant: .line, points: _points([1])).plot,
        )['min-height'],
        isNot('20.0rem'),
      );
    });
  });

  group('TrendChart markup', () {
    Future<server.DocumentResponse> render(
      server.ServerTester tester,
      Component component,
    ) {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: component));
      return tester.request('/');
    }

    server.testServer('the plot is a named group of labelled points', (
      tester,
    ) async {
      final response = await render(
        tester,
        TrendChart(semanticLabel: '일별 문의 추이', points: _points([3, 7])),
      );
      final doc = response.document!;
      final group = doc.querySelector('[role="group"]');
      expect(group?.attributes['aria-label'], '일별 문의 추이');
      final items = doc.querySelectorAll('[role="listitem"]');
      expect(items.map((e) => e.attributes['aria-label']), [
        '1월 1일, 3건',
        '1월 2일, 7건',
      ]);
      expect(doc.querySelector('polyline'), isNotNull);
    });

    server.testServer('axis labels are hidden from assistive technology', (
      tester,
    ) async {
      final response = await render(
        tester,
        TrendChart(points: _points([0, 50])),
      );
      final hidden = response.document!.querySelectorAll(
        '[aria-hidden="true"]',
      );
      // [0, 50] rounds to ticks 0 · 20 · 40 · 60.
      expect(hidden.any((e) => e.text.contains('20')), isTrue);
    });

    server.testServer('bar variant draws no polyline', (tester) async {
      final response = await render(
        tester,
        TrendChart(variant: .bar, points: _points([1, -1])),
      );
      expect(response.document!.querySelector('polyline'), isNull);
    });

    server.testServer('no points renders the empty slot, chips and summary', (
      tester,
    ) async {
      final response = await render(
        tester,
        const TrendChart(
          points: [],
          summary: div([Text('요약')]),
          periods: ['7일', '30일'],
          empty: div([Text('데이터 없음')]),
        ),
      );
      final body = response.document!.body!.text;
      expect(body, contains('데이터 없음'));
      expect(body, contains('요약'));
      expect(body, contains('30일'));
      expect(response.document!.querySelector('[role="group"]'), isNull);
    });

    server.testServer(
      'the legend renders with both reference value and label',
      (
        tester,
      ) async {
        final without = await render(
          tester,
          TrendChart(points: _points([1, 2]), referenceValue: 2),
        );
        expect(without.document!.body!.text, isNot(contains('목표')));
        final withLabel = await render(
          tester,
          TrendChart(
            points: _points([1, 2]),
            referenceValue: 2,
            referenceLabel: '목표',
          ),
        );
        expect(withLabel.document!.body!.text, contains('목표'));
        expect(withLabel.document!.querySelectorAll('line'), hasLength(2));
      },
    );
  });

  test('withStyle merges into trendChartStyle', () {
    final chart = TrendChart(
      points: _points([1]),
    ).withStyle(const CoreTrendChartStyle(plotHeight: 80));
    expect(chart.trendChartStyle?.plotHeight, 80);
  });
}
