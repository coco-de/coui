// Resolver rules run through `testComponents` (they need a themed
// context); markup claims — roles, accessible names, which elements exist
// — run through `testServer`, because only the SSR binding hands back the
// document assistive technology reads.
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

const _items = [
  CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
  CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
  CoreCategoryBreakdownItem(label: '계정', value: 33, valueLabel: '33건'),
  CoreCategoryBreakdownItem(label: '기타', value: 0, valueLabel: '0건'),
];

Map<String, String> _props(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

void main() {
  group('resolveCategoryBreakdown', () {
    testComponents('shares and labels come from the Core geometry', (
      tester,
    ) async {
      final resolved = resolveCategoryBreakdown(
        _themedContext(tester),
        variant: .bar,
        items: _items,
      );
      expect(resolved.series.percentLabels, ['58%', '27%', '15%', '0%']);
      expect(resolved.series.rowLabels.first, '결제 문의, 128건, 58%');
      expect(_props(resolved.fills[3])['width'], '0.000%');
    });

    testComponents('palette colours go out as token classes', (tester) async {
      final resolved = resolveCategoryBreakdown(
        _themedContext(tester),
        variant: .bar,
        items: _items,
      );
      expect(resolved.fills[0].className, contains('bg-primary'));
      expect(resolved.fills[1].className, contains('bg-secondary'));
      expect(resolved.arcs[0].className, contains('text-primary'));
    });

    testComponents('a raw item colour goes inline', (tester) async {
      final resolved = resolveCategoryBreakdown(
        _themedContext(tester),
        variant: .bar,
        items: const [
          CoreCategoryBreakdownItem(
            label: 'A',
            value: 1,
            color: CoreColor(0xFF123456),
          ),
        ],
      );
      expect(resolved.fills[0].className, isNot(contains('bg-')));
      expect(_props(resolved.fills[0])['background-color'], isNotNull);
    });

    testComponents(
      'arcs are dashes of one ring, starting where the last ended',
      (
        tester,
      ) async {
        final resolved = resolveCategoryBreakdown(
          _themedContext(tester),
          variant: .donut,
          items: const [
            CoreCategoryBreakdownItem(label: 'A', value: 1),
            CoreCategoryBreakdownItem(label: 'B', value: 1),
          ],
          categoryBreakdownStyle: const CoreCategoryBreakdownStyle(
            donutSegmentSpacing: 0,
          ),
        );
        final a = _props(resolved.arcs[0]);
        final b = _props(resolved.arcs[1]);
        expect(a['stroke-dashoffset'], anyOf('0.000', '-0.000'));
        final circumference = double.parse(
          a['stroke-dasharray']!.split(' ')[1],
        );
        expect(
          double.parse(b['stroke-dashoffset']!),
          closeTo(-circumference / 2, 0.01),
        );
        expect(resolved.donutSvg.className, contains('rtl:-scale-x-100'));
      },
    );

    testComponents('the legend wraps at one donut width', (tester) async {
      final resolved = resolveCategoryBreakdown(
        _themedContext(tester),
        variant: .donut,
        items: _items,
      );
      expect(_props(resolved.legend)['flex'], '1 1 10.0rem');
      expect(resolved.root.className, contains('flex-wrap'));
    });

    testComponents('theme variantStyles reach only their variant', (
      tester,
    ) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              categoryBreakdown: CoreCategoryBreakdownTheme(
                variantStyles: {
                  CoreCategoryBreakdownVariant.bar: CoreCategoryBreakdownStyle(
                    barHeight: 16,
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
          resolveCategoryBreakdown(context, variant: .bar, items: _items).track,
        )['height'],
        '1.0rem',
      );
      expect(
        _props(
          resolveCategoryBreakdown(
            context,
            variant: .donut,
            items: _items,
          ).track,
        )['height'],
        isNot('1.0rem'),
      );
    });
  });

  group('CategoryBreakdown markup', () {
    Future<server.DocumentResponse> render(
      server.ServerTester tester,
      Component component,
    ) {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: component));
      return tester.request('/');
    }

    server.testServer(
      'bar: a named list of rows that read label, value, share',
      (
        tester,
      ) async {
        final response = await render(
          tester,
          const CategoryBreakdown(semanticLabel: '문의 유형별 분포', items: _items),
        );
        final doc = response.document!;
        final list = doc.querySelector('[role="list"]');
        expect(list?.attributes['aria-label'], '문의 유형별 분포');
        expect(
          doc
              .querySelectorAll('[role="listitem"]')
              .map(
                (e) => e.attributes['aria-label'],
              ),
          [
            '결제 문의, 128건, 58%',
            '배송 문의, 61건, 27%',
            '계정, 33건, 15%',
            '기타, 0건, 0%',
          ],
        );
      },
    );

    server.testServer('donut: group with a legend list and the centre slot', (
      tester,
    ) async {
      final response = await render(
        tester,
        const CategoryBreakdown(
          variant: .donut,
          semanticLabel: '분포',
          center: span([Text('222건')]),
          items: _items,
        ),
      );
      final doc = response.document!;
      expect(
        doc.querySelector('[role="group"]')?.attributes['aria-label'],
        '분포',
      );
      expect(doc.querySelectorAll('[role="listitem"]'), hasLength(4));
      expect(doc.querySelectorAll('circle'), hasLength(4));
      expect(doc.body!.text, contains('222건'));
    });

    server.testServer('empty input renders the empty slot only', (
      tester,
    ) async {
      final response = await render(
        tester,
        const CategoryBreakdown(items: [], empty: span([Text('데이터 없음')])),
      );
      expect(response.document!.body!.text, contains('데이터 없음'));
      expect(response.document!.querySelector('[role="list"]'), isNull);
    });
  });

  test('withStyle merges into categoryBreakdownStyle', () {
    final chart = const CategoryBreakdown(
      items: _items,
    ).withStyle(const CoreCategoryBreakdownStyle(barHeight: 12));
    expect(chart.categoryBreakdownStyle?.barHeight, 12);
  });
}
