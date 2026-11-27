/// TrendChart 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="trend-chart/...">` · `<Card demo>` · `<Anatomy demo>` 가
/// 읽는다. 같은 이름의 Flutter 파일(`trend_chart_flutter.dart`)과 컴포넌트 ·
/// 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_web.dart';
import 'trend_chart_page.dart' as page;

/// 속성 → Component.
///
/// 고른 기간은 부모가 들고 넘기는 값이라 빌더가 기억한다. 서버에서 그리는
/// 블록에서는 처음 기간만 보인다.
WebPropPreviewBuilder? get propPreview =>
    (props, _) => _box(_TrendChartPreview(props: props));

/// 장면 이름(`trend-chart/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'trend-chart/anatomy': () => _box(
    TrendChart(
      semanticLabel: page.trendChartName(),
      // `data-docs-part` 는 구조 번호가 요약 슬롯을 찾는 표지다.
      summary: div(attributes: const {'data-docs-part': 'summary'}, [_summary(page.trendChartSummaryText())]),
      periods: page.trendChartPeriods,
      selectedPeriodIndex: page.trendChartInitialPeriod,
      onPeriodChanged: (_) {},
      referenceValue: page.trendChartReference(),
      referenceLabel: page.trendChartReferenceText(),
      points: page.trendChartMonthlyPoints(6),
    ),
    width: page.trendChartAnatomyWidth,
  ),
  'trend-chart/axis': () => _box(
    TrendChart(
      semanticLabel: '일별 주문 추이',
      valueFormatter: page.trendChartGrouped,
      points: page.trendChartDailyPoints(),
    ),
  ),
  'trend-chart/negative': () => _box(
    TrendChart(
      variant: CoreTrendChartVariant.bar,
      semanticLabel: page.trendChartName(negative: true),
      points: page.trendChartMonthlyPoints(6, negative: true),
    ),
  ),
  'trend-chart/summary': () => _box(
    TrendChart(
      semanticLabel: page.trendChartName(),
      summary: const Stat(
        label: '구독자',
        value: '12,480',
        unit: '명',
        size: CoreComponentSize.sm,
        change: '+11.4%',
        changeType: CoreStatChangeType.positive,
      ),
      referenceValue: page.trendChartReference(),
      referenceLabel: page.trendChartReferenceText(),
      valueFormatter: page.trendChartGrouped,
      points: page.trendChartMonthlyPoints(6),
    ),
  ),
  'trend-chart/empty': () => _box(
    TrendChart(
      semanticLabel: page.trendChartName(),
      periods: page.trendChartPeriods,
      selectedPeriodIndex: 0,
      onPeriodChanged: (_) {},
      empty: Text(page.trendChartEmptyText).bodySmall.onSurfaceVariant,
      points: const [],
    ),
  ),
  'trend-chart/single': () => _box(
    TrendChart(
      semanticLabel: page.trendChartName(),
      valueFormatter: page.trendChartGrouped,
      points: page.trendChartSinglePoint(),
    ),
  ),
  'trend-chart/flat': () => _box(TrendChart(semanticLabel: '월별 문의 추이', points: page.trendChartFlatPoints())),
  'trend-chart/styled': () => _box(
    TrendChart(
      semanticLabel: page.trendChartName(),
      points: page.trendChartMonthlyPoints(6),
      trendChartStyle: const CoreTrendChartStyle(
        seriesColor: CoreColor.token(CoreColors.success),
        lineWidth: CoreStrokeWidth.stroke3,
        plotHeight: CoreSpace.space120,
        axisTickCount: 2,
      ),
    ),
  ),
  'trend-chart/do-scale': () => _card(_smallChange(CoreTrendChartVariant.line)),
  'trend-chart/dont-scale': () => _card(_smallChange(CoreTrendChartVariant.bar)),
  'trend-chart/do-labels': () => _card(
    TrendChart(semanticLabel: page.trendChartName(), points: page.trendChartMonthlyPoints(4)),
  ),
  'trend-chart/dont-labels': () => _card(
    TrendChart(semanticLabel: page.trendChartName(), points: page.trendChartUnlabeledPoints()),
  ),
  'trend-chart/do-reference': () => _card(
    TrendChart(
      semanticLabel: page.trendChartName(),
      referenceValue: page.trendChartReference(),
      referenceLabel: page.trendChartReferenceText(),
      points: page.trendChartMonthlyPoints(4),
    ),
  ),
  'trend-chart/dont-reference': () => _card(
    TrendChart(
      semanticLabel: page.trendChartName(),
      referenceValue: page.trendChartReference(),
      points: page.trendChartMonthlyPoints(4),
    ),
  ),
  'trend-chart/related-stat': () => _related(
    const Stat(
      label: '구독자',
      value: '12,480',
      unit: '명',
      size: CoreComponentSize.sm,
      change: '+11.4%',
      changeType: CoreStatChangeType.positive,
    ),
  ),
  'trend-chart/related-tracker': () => _related(
    const Tracker(
      segments: [
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.warning),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.critical),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
      ],
    ),
  ),
  'trend-chart/related-progress': () => _related(const Progress(value: 0.6)),
  'trend-chart/related-chip': () => docsWebDemoRow([
    Chip(label: '3개월'),
    Chip(label: '6개월', selected: true),
  ]),
};

/// 폭을 정한 상자 — TrendChart 는 부모의 폭을 채운다.
Component _box(Component child, {double width = page.trendChartSceneWidth}) =>
    div(styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}), [child]);

Component _card(Component child) => _box(child, width: page.trendChartCardWidth);

Component _related(Component child) => _box(child, width: page.trendChartRelatedWidth);

Component _summary(String text) => Text(text).titleSmall.onSurface;

Component _smallChange(CoreTrendChartVariant variant) => TrendChart(
  variant: variant,
  semanticLabel: page.trendChartName(),
  valueFormatter: page.trendChartGrouped,
  points: page.trendChartSmallChangePoints(),
);

/// 속성으로 그리는 TrendChart — 고른 기간을 기억한다.
///
/// 속성: `variant` 는 위젯 속성 그대로, `periods` · `referenceValue` ·
/// `summary` 는 켜면 그 속성에 예시 값을 넘긴다. `negative` 는 음수가 섞인
/// 점으로 바꾸고, `empty` 는 `points` 를 비운다.
class _TrendChartPreview extends StatefulComponent {
  const _TrendChartPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_TrendChartPreview> createState() => _TrendChartPreviewState();
}

class _TrendChartPreviewState extends State<_TrendChartPreview> {
  int _period = page.trendChartInitialPeriod;

  void _handlePeriodChanged(int index) => setState(() => _period = index);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    final negative = previewFlag(props, 'negative');
    final periods = previewFlag(props, 'periods');
    final reference = previewFlag(props, 'referenceValue');
    final empty = previewFlag(props, 'empty');
    final count = page.trendChartPeriodCounts[periods ? _period : page.trendChartInitialPeriod];
    return TrendChart(
      variant: page.trendChartPreviewVariant(props),
      semanticLabel: page.trendChartName(negative: negative),
      summary: previewFlag(props, 'summary') ? _summary(page.trendChartSummaryText(negative: negative)) : null,
      periods: periods ? page.trendChartPeriods : const [],
      selectedPeriodIndex: periods ? _period : null,
      onPeriodChanged: periods ? _handlePeriodChanged : null,
      referenceValue: reference ? page.trendChartReference(negative: negative) : null,
      referenceLabel: reference ? page.trendChartReferenceText(negative: negative) : null,
      empty: empty ? Text(page.trendChartEmptyText).bodySmall.onSurfaceVariant : null,
      points: empty ? const [] : page.trendChartMonthlyPoints(count, negative: negative),
    );
  }
}
