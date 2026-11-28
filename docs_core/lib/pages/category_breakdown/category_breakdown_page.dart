/// CategoryBreakdown 페이지 — 플레이그라운드와 예시 데이터. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `category_breakdown_web.dart` · `category_breakdown_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/category-breakdown.md`.
const String slug = 'category-breakdown';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. CategoryBreakdown 은 `CoreComponentSize` 축이 없다 — 막대 두께 ·
/// 도넛 지름 같은 치수는 `categoryBreakdownStyle` 이 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 예시 분포의 접근 가능한 이름.
const String categoryBreakdownDemoLabel = '문의 유형별 분포';

/// 예시 항목 — 플레이그라운드와 두 플랫폼의 장면이 함께 읽는다.
const List<CoreCategoryBreakdownItem> categoryBreakdownDemoItems = [
  CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
  CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
  CoreCategoryBreakdownItem(label: '계정 · 로그인', value: 33, valueLabel: '33건'),
  CoreCategoryBreakdownItem(label: '기타', value: 12, valueLabel: '12건'),
];

/// 세 항목의 값이 같은 예시 — 정수 퍼센트의 합을 100 으로 맞추는 것을 보인다.
const List<CoreCategoryBreakdownItem> categoryBreakdownThirdItems = [
  CoreCategoryBreakdownItem(label: '웹', value: 1, valueLabel: '1건'),
  CoreCategoryBreakdownItem(label: '앱', value: 1, valueLabel: '1건'),
  CoreCategoryBreakdownItem(label: '전화', value: 1, valueLabel: '1건'),
];

/// 값이 0 인 항목이 섞인 예시.
const List<CoreCategoryBreakdownItem> categoryBreakdownZeroItems = [
  CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
  CoreCategoryBreakdownItem(label: '환불 문의', value: 0, valueLabel: '0건'),
];

/// 라벨이 긴 예시.
const List<CoreCategoryBreakdownItem> categoryBreakdownLongItems = [
  CoreCategoryBreakdownItem(label: '해외 배송 · 통관 지연 문의', value: 24, valueLabel: '24건'),
  CoreCategoryBreakdownItem(label: '결제 수단 변경 · 영수증 재발급 문의', value: 18, valueLabel: '18건'),
  CoreCategoryBreakdownItem(label: '기타', value: 8, valueLabel: '8건'),
];

/// 좁은 폭에서 값 · 비율이 라벨 아래로 내려가는 예시.
const List<CoreCategoryBreakdownItem> categoryBreakdownWrapItems = [
  CoreCategoryBreakdownItem(label: '해외 배송 · 통관 지연 문의', value: 1284, valueLabel: '1,284건'),
  CoreCategoryBreakdownItem(label: '기타', value: 316, valueLabel: '316건'),
];

/// 합계를 이루지 않는 값이 섞인 금지 예시.
const List<CoreCategoryBreakdownItem> categoryBreakdownMixedItems = [
  CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
  CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
  CoreCategoryBreakdownItem(label: '평균 응답 시간', value: 42, valueLabel: '42분'),
];

/// 기본 색 목록(6색)보다 항목이 하나 많은 예시 — 일곱째가 첫째와 같은 색이다.
const List<CoreCategoryBreakdownItem> categoryBreakdownManyItems = [
  CoreCategoryBreakdownItem(label: '결제', value: 48, valueLabel: '48건'),
  CoreCategoryBreakdownItem(label: '배송', value: 36, valueLabel: '36건'),
  CoreCategoryBreakdownItem(label: '계정', value: 27, valueLabel: '27건'),
  CoreCategoryBreakdownItem(label: '환불', value: 19, valueLabel: '19건'),
  CoreCategoryBreakdownItem(label: '교환', value: 14, valueLabel: '14건'),
  CoreCategoryBreakdownItem(label: '쿠폰', value: 9, valueLabel: '9건'),
  CoreCategoryBreakdownItem(label: '기타', value: 6, valueLabel: '6건'),
];

/// 플레이그라운드의 "색 목록 바꾸기" 가 얹는 값 — 코드 상자와 같은 색이다.
const CoreCategoryBreakdownStyle categoryBreakdownSeriesStyle = CoreCategoryBreakdownStyle(
  seriesColors: [
    CoreColor.token(CoreColors.info),
    CoreColor.token(CoreColors.success),
    CoreColor.token(CoreColors.warning),
    CoreColor.token(CoreColors.outline),
  ],
);

/// 인스턴스 하나를 바꾸는 예시 — 본문의 "분포 하나만 바꾸기" 코드와 같은 값이다.
const CoreCategoryBreakdownStyle categoryBreakdownDemoStyle = CoreCategoryBreakdownStyle(
  barHeight: CoreSpace.space12,
  barBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
  percentStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSurface)),
  seriesColors: [
    CoreColor.token(CoreColors.info),
    CoreColor.token(CoreColors.success),
    CoreColor.token(CoreColors.warning),
    CoreColor.token(CoreColors.outline),
  ],
);

/// 구조(bar) · 상태 · 반올림 장면의 폭 (논리 px).
const double categoryBreakdownDemoWidth = 352;

/// 범례가 도넛 옆에 놓이는 폭 — 기본값의 경계(지름 × 2 + 간격)보다 넓다.
const double categoryBreakdownWideDonutWidth = 400;

/// 범례가 도넛 아래로 내려가는 폭.
const double categoryBreakdownNarrowDonutWidth = 240;

/// 값 · 비율이 라벨 아래로 내려가는 폭.
const double categoryBreakdownWrapWidth = 208;

/// 속성의 `count` 만큼의 예시 항목. `rawValue` 를 켜면 `valueLabel` 을 뺀다.
List<CoreCategoryBreakdownItem> categoryBreakdownPropItems(Map<String, String> props) {
  final count = (int.tryParse(props['count'] ?? '') ?? categoryBreakdownDemoItems.length).clamp(
    1,
    categoryBreakdownDemoItems.length,
  );
  final rawValue = previewFlag(props, 'rawValue');
  return [
    for (final item in categoryBreakdownDemoItems.take(count))
      rawValue ? CoreCategoryBreakdownItem(label: item.label, value: item.value) : item,
  ];
}

/// 도넛 가운데에 넣는 합계 글. 컴포넌트는 합계를 그리지 않으므로 두 플랫폼의
/// 속성 빌더 · 장면과 플레이그라운드 코드가 여기서 함께 읽는다.
String categoryBreakdownTotal(List<CoreCategoryBreakdownItem> items) {
  final total = items.fold<double>(0, (sum, item) => sum + item.value);
  return '${CoreCategoryBreakdownGeometry.formatValue(total)}건';
}

/// 속성 `colors=custom` 이면 얹는 스타일.
CoreCategoryBreakdownStyle? categoryBreakdownPropStyle(Map<String, String> props) =>
    props['colors'] == 'custom' ? categoryBreakdownSeriesStyle : null;

// variant 선택지는 enum 에서, 항목 수 선택지는 예시 항목에서 읽는다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'variant': CoreCategoryBreakdownVariant.defaultVariant.name,
    'count': '${categoryBreakdownDemoItems.length}',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreCategoryBreakdownVariant.values) variant.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: '항목 수',
      prop: 'count',
      options: [for (var count = 2; count <= categoryBreakdownDemoItems.length; count++) '$count'],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: 'valueLabel 빼기', on: {'rawValue': 'true'}),
    const DocsPlaygroundFlag(label: '색 목록 바꾸기', on: {'colors': 'custom'}),
  ],
  code: _categoryBreakdownCode,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다. 도넛에는 합계를 넣은
/// `center` 가 함께 나온다.
String _categoryBreakdownCode(Map<String, String> props, String? label) {
  final variant = previewEnum(
    CoreCategoryBreakdownVariant.values,
    props['variant'],
    CoreCategoryBreakdownVariant.defaultVariant,
  );
  final items = categoryBreakdownPropItems(props);
  final seriesColors = categoryBreakdownPropStyle(props)?.seriesColors;
  final lines = [
    if (variant != CoreCategoryBreakdownVariant.defaultVariant)
      'variant: CoreCategoryBreakdownVariant.${variant.name},',
    "semanticLabel: '$categoryBreakdownDemoLabel',",
    if (variant == CoreCategoryBreakdownVariant.donut)
      "center: Text('${categoryBreakdownTotal(items)}').titleMedium.semiBold,",
    'items: const [',
    for (final item in items) '  ${_itemCode(item)},',
    '],',
    if (seriesColors != null) ...[
      'categoryBreakdownStyle: const CoreCategoryBreakdownStyle(',
      '  seriesColors: [',
      for (final color in seriesColors) '    CoreColor.token(CoreColors.${color.token!.name}),',
      '  ],',
      '),',
    ],
  ];
  return 'CategoryBreakdown(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

String _itemCode(CoreCategoryBreakdownItem item) {
  final valueLabel = item.valueLabel;
  final arguments = [
    "label: '${item.label}'",
    'value: ${CoreCategoryBreakdownGeometry.formatValue(item.value)}',
    if (valueLabel != null) "valueLabel: '$valueLabel'",
  ];
  return 'CoreCategoryBreakdownItem(${arguments.join(', ')})';
}
