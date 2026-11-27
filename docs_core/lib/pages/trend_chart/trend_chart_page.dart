/// TrendChart 페이지 — 플레이그라운드와 예시 데이터. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `trend_chart_web.dart` · `trend_chart_flutter.dart` 가 그린다. 두
/// 플랫폼 장면이 같은 점 · 글 · 폭을 쓰도록 예시 데이터는 이 파일에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/trend-chart.md`.
const String slug = 'trend-chart';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 미리보기와 본문 장면의 폭.
const double trendChartSceneWidth = CoreLayout.layout320;

/// 구조 장면의 폭. 390px 에서 옆 번호가 무대 안에 놓이게 좁힌다.
const double trendChartAnatomyWidth = 264;

/// Do · Don't 카드에 놓는 차트의 폭.
const double trendChartCardWidth = CoreLayout.layout240;

/// 관련 컴포넌트 장면의 폭.
const double trendChartRelatedWidth = CoreLayout.layout160;

/// 기간 칩의 글.
const List<String> trendChartPeriods = ['3개월', '6개월', '12개월'];

/// 기간 칩마다 보여 줄 점의 수 — [trendChartPeriods] 와 같은 순서.
const List<int> trendChartPeriodCounts = [3, 6, 12];

/// 처음에 고른 기간 칩 — 6개월.
const int trendChartInitialPeriod = 1;

/// 월별 점의 연 · 월. 오래된 것부터.
const List<(int, int)> _months = [
  (2025, 10),
  (2025, 11),
  (2025, 12),
  (2026, 1),
  (2026, 2),
  (2026, 3),
  (2026, 4),
  (2026, 5),
  (2026, 6),
  (2026, 7),
  (2026, 8),
  (2026, 9),
];

/// 월별 구독자 수.
const List<double> _subscribers = [6100, 6600, 7000, 7300, 7900, 8000, 8200, 9100, 8800, 10400, 11200, 12480];

/// 월별 손익(만 원) — 음수가 섞인 예시.
const List<double> _profits = [120, -80, 40, -160, 220, 60, -40, 180, -120, 90, 150, -60];

/// 최근 [count] 개월의 점. [negative] 면 음수가 섞인 손익이다.
List<CoreTrendPoint> trendChartMonthlyPoints(int count, {bool negative = false}) {
  final values = negative ? _profits : _subscribers;
  return [
    for (var i = _months.length - count; i < _months.length; i++)
      CoreTrendPoint(
        date: DateTime(_months[i].$1, _months[i].$2),
        value: values[i],
        label: '${_months[i].$2}월',
        valueLabel: negative ? '${trendChartGrouped(values[i])}만 원' : '${trendChartGrouped(values[i])}명',
      ),
  ];
}

/// 그래프의 접근 가능한 이름.
String trendChartName({bool negative = false}) => negative ? '월별 손익 추이' : '월별 구독자 추이';

/// `summary` 슬롯에 적는 글.
String trendChartSummaryText({bool negative = false}) => negative ? '9월 손익 -60만 원' : '구독자 12,480명';

/// 기준선의 값.
double trendChartReference({bool negative = false}) => negative ? 100 : 12000;

/// 기준선의 범례 글.
String trendChartReferenceText({bool negative = false}) => negative ? '목표 100만 원' : '목표 12,000명';

/// 점이 없을 때 `empty` 슬롯에 적는 글.
const String trendChartEmptyText = '이 기간에는 데이터가 없습니다';

/// 세 자리마다 쉼표를 넣은 정수 글. 두 플랫폼에서 같은 글이 나온다.
String trendChartGrouped(double value) {
  final whole = value.round();
  final digits = whole.abs().toString();
  final buffer = StringBuffer(whole < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// 30일치 점 — 날짜 축이 라벨 셋만 보이는 장면.
List<CoreTrendPoint> trendChartDailyPoints() => [
  for (var i = 0; i < 30; i++) _dailyPoint(i + 1, (1200 + (i * 137) % 400 + i * 20).toDouble()),
];

CoreTrendPoint _dailyPoint(int day, double value) => CoreTrendPoint(
  date: DateTime(2026, 9, day),
  value: value,
  label: '9월 $day일',
  valueLabel: '${trendChartGrouped(value)}건',
);

/// 점 하나.
List<CoreTrendPoint> trendChartSinglePoint() => trendChartMonthlyPoints(1);

/// 값이 모두 같은 점.
List<CoreTrendPoint> trendChartFlatPoints() => [
  for (var month = 6; month <= 9; month++)
    CoreTrendPoint(date: DateTime(2026, month), value: 50, label: '$month월', valueLabel: '50건'),
];

/// 값에 비해 변화가 작은 점 — line 과 bar 를 견주는 카드.
List<CoreTrendPoint> trendChartSmallChangePoints() => [
  for (final (month, value) in const [(6, 9980.0), (7, 10010.0), (8, 9995.0), (9, 10020.0)])
    CoreTrendPoint(
      date: DateTime(2026, month),
      value: value,
      label: '$month월',
      valueLabel: '${trendChartGrouped(value)}명',
    ),
];

/// `label` 을 주지 않은 점 — 날짜 축에 `yyyy-MM-dd` 가 나온다.
List<CoreTrendPoint> trendChartUnlabeledPoints() => [
  for (final point in trendChartMonthlyPoints(4))
    CoreTrendPoint(date: point.date, value: point.value, valueLabel: point.valueLabel),
];

/// 속성의 `variant` → 값. 없거나 모르는 이름은 기본값.
CoreTrendChartVariant trendChartPreviewVariant(Map<String, String> props) =>
    previewEnum(CoreTrendChartVariant.values, props['variant'], CoreTrendChartVariant.defaultVariant);

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'variant': CoreTrendChartVariant.defaultVariant.name, 'periods': 'true', 'referenceValue': 'true'},
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreTrendChartVariant.values) variant.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '기간 칩', on: {'periods': 'true'}),
    const DocsPlaygroundFlag(label: '기준선', on: {'referenceValue': 'true'}),
    const DocsPlaygroundFlag(label: '요약', on: {'summary': 'true'}),
    const DocsPlaygroundFlag(label: '음수 값', on: {'negative': 'true'}),
    const DocsPlaygroundFlag(label: '데이터 없음', on: {'empty': 'true'}),
  ],
  code: _trendChartCode,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다.
String _trendChartCode(Map<String, String> props, String? label) {
  final variant = trendChartPreviewVariant(props);
  final negative = previewFlag(props, 'negative');
  final periods = previewFlag(props, 'periods');
  final lines = <String>[
    if (variant != CoreTrendChartVariant.defaultVariant) 'variant: CoreTrendChartVariant.${variant.name},',
    "semanticLabel: '${trendChartName(negative: negative)}',",
    if (previewFlag(props, 'summary'))
      "summary: Text('${trendChartSummaryText(negative: negative)}').titleSmall.onSurface,",
    if (periods) ...[
      'periods: const [${trendChartPeriods.map((period) => "'$period'").join(', ')}],',
      'selectedPeriodIndex: period,',
      'onPeriodChanged: (index) => setState(() => period = index),',
    ],
    if (previewFlag(props, 'referenceValue')) ...[
      'referenceValue: ${trendChartReference(negative: negative).round()},',
      "referenceLabel: '${trendChartReferenceText(negative: negative)}',",
    ],
    if (previewFlag(props, 'empty')) ...[
      'points: const [],',
      "empty: Text('$trendChartEmptyText').bodySmall.onSurfaceVariant,",
    ] else ...[
      if (periods) '// 고른 기간에 맞는 점을 넘깁니다. 아래는 6개월입니다.',
      'points: [',
      for (final point in trendChartMonthlyPoints(
        trendChartPeriodCounts[trendChartInitialPeriod],
        negative: negative,
      ))
        '  CoreTrendPoint(date: DateTime(${point.date.year}, ${point.date.month}), '
            "value: ${point.value.round()}, label: '${point.label}', valueLabel: '${point.valueLabel}'),",
      '],',
    ],
  ];
  return 'TrendChart(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
