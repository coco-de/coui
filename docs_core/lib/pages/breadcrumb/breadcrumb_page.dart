/// Breadcrumb 페이지 — 플레이그라운드와 장면 데이터. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `breadcrumb_web.dart` · `breadcrumb_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 플레이그라운드의 속성은 넷이다: `depth`(항목 수), `separatorSize`(chevron
/// 크기), `gap`(구분자 양옆 간격), `enabled`. 두 플랫폼 빌더와 코드가 같은
/// 뜻으로 읽도록 해석을 이 파일의 함수에 둔다. 크기 축이 없어 크기 표는
/// 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/breadcrumb.md`.
const String slug = 'breadcrumb';

/// 플레이그라운드의 경로 — 루트부터. 앞에서 `depth` 개를 쓰고, 그 마지막이
/// 현재 위치다.
const List<CoreBreadcrumbItem> kBreadcrumbPreviewTrail = [
  CoreBreadcrumbItem(label: '홈', href: '/'),
  CoreBreadcrumbItem(label: '라이브러리', href: '/library'),
  CoreBreadcrumbItem(label: '데이터', href: '/library/data'),
  CoreBreadcrumbItem(label: '보고서', href: '/library/data/reports'),
];

/// `breadcrumb/anatomy` 장면의 라벨. 라벨이 짧으면 구조 번호가 서로 붙어서
/// 조금 긴 낱말을 쓴다.
const List<String> kBreadcrumbAnatomyLabels = ['대시보드', '프로젝트', 'CoUI'];

/// `breadcrumb/states` 장면의 경로 라벨.
const List<String> kBreadcrumbStateLabels = ['홈', '라이브러리', '데이터'];

/// `breadcrumb/states` 장면의 줄 — 위에 적는 이름과 위젯에 넘기는 값.
const List<({String caption, bool hasHandler, bool? enabled})> kBreadcrumbStateRows = [
  (caption: 'onItemTap 있음', hasHandler: true, enabled: null),
  (caption: 'onItemTap 없음', hasHandler: false, enabled: null),
  (caption: 'enabled: true, onItemTap 없음', hasHandler: false, enabled: true),
];

/// `breadcrumb/separator` 장면의 줄 — 위에 적는 이름과 덮어쓴 스타일.
const List<({String caption, CoreBreadcrumbStyle? style})> kBreadcrumbSeparatorRows = [
  (caption: '기본: 크기 16 · 간격 4', style: null),
  (
    caption: '크기 12 · 간격 8 · primary',
    style: CoreBreadcrumbStyle(
      separatorIconStyle: CoreIconStyle(size: CoreIconSize.size12, color: CoreColor.token(CoreColors.primary)),
      itemSeparatorGapStyle: CoreGapStyle(size: CoreSpace.space8),
    ),
  ),
];

/// `breadcrumb/overflow` 장면의 긴 경로.
const List<String> kBreadcrumbLongLabels = ['홈', '라이브러리', '데이터', '분기 보고서', '4분기 매출 요약'];

/// `breadcrumb/overflow` 장면의 부모 폭(logical px).
const double kBreadcrumbOverflowWidth = 240;

/// 권장 카드 — 지금 보는 화면까지 넣은 경로.
const List<String> kBreadcrumbDoCurrentLabels = ['홈', '라이브러리', '데이터'];

/// 금지 카드 — '데이터' 화면인데 '데이터'를 뺀 경로.
const List<String> kBreadcrumbDontMissingCurrentLabels = ['홈', '라이브러리'];

/// 권장 카드 — 세 단계 이상인 계층.
const List<String> kBreadcrumbDoDeepLabels = ['홈', '상품', '주방', '냄비'];

/// 금지 카드 — 두 단계뿐인 계층.
const List<String> kBreadcrumbDontTwoLevelLabels = ['홈', '설정'];

/// 관련 컴포넌트 카드의 탭 라벨.
const List<String> kBreadcrumbRelatedTabLabels = ['개요', '활동'];

/// 라벨만 있는 항목 목록.
List<CoreBreadcrumbItem> breadcrumbItems(List<String> labels) => [
  for (final label in labels) CoreBreadcrumbItem(label: label),
];

/// 속성의 `depth` → 보일 항목. 없거나 모르는 값은 세 개.
List<CoreBreadcrumbItem> breadcrumbPreviewItems(Map<String, String> props) {
  final depth = int.tryParse(props['depth'] ?? '') ?? 3;
  return kBreadcrumbPreviewTrail.sublist(0, depth.clamp(1, kBreadcrumbPreviewTrail.length));
}

/// 속성의 `separatorSize` → chevron 크기. 없거나 모르는 값은 기본 크기.
double breadcrumbPreviewSeparatorSize(Map<String, String> props) => switch (props['separatorSize']) {
  '12' => CoreIconSize.size12,
  '20' => CoreIconSize.size20,
  _ => CoreBreadcrumbStyle.defaultSeparatorIconSize,
};

/// 속성의 `gap` → 구분자 양옆 간격. 없거나 모르는 값은 기본 간격(4).
double breadcrumbPreviewGap(Map<String, String> props) => switch (props['gap']) {
  '8' => CoreSpace.space8,
  '12' => CoreSpace.space12,
  _ => CoreSpace.space4,
};

/// 속성 → `breadcrumbStyle`. 둘 다 기본값이면 `null`.
CoreBreadcrumbStyle? breadcrumbPreviewStyle(Map<String, String> props) {
  final size = breadcrumbPreviewSeparatorSize(props);
  final gap = breadcrumbPreviewGap(props);
  final resized = size != CoreBreadcrumbStyle.defaultSeparatorIconSize;
  final spaced = gap != CoreSpace.space4;
  if (!resized && !spaced) return null;
  return CoreBreadcrumbStyle(
    separatorIconStyle: resized ? CoreIconStyle(size: size) : null,
    itemSeparatorGapStyle: spaced ? CoreGapStyle(size: gap) : null,
  );
}

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'depth': '3', 'separatorSize': '16', 'gap': '4'},
  controls: [
    DocsPlaygroundChoice(label: '항목 수', prop: 'depth', options: ['2', '3', '4'], segmented: true),
    DocsPlaygroundChoice(label: '구분자 크기', prop: 'separatorSize', options: ['12', '16', '20'], segmented: true),
    DocsPlaygroundChoice(label: '구분자 간격', prop: 'gap', options: ['4', '8', '12'], segmented: true),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _breadcrumbCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 → 코드. 마지막 항목은 현재 위치라 `href` 를 적지 않는다.
String _breadcrumbCode(Map<String, String> props, String? label) {
  final items = breadcrumbPreviewItems(props);
  final size = breadcrumbPreviewSeparatorSize(props);
  final gap = breadcrumbPreviewGap(props);
  final lines = [
    'items: const [',
    for (final (index, item) in items.indexed)
      if (index < items.length - 1)
        "  CoreBreadcrumbItem(label: '${item.label}', href: '${item.href}'),"
      else
        "  CoreBreadcrumbItem(label: '${item.label}'),",
    '],',
    'onItemTap: openCrumb,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    if (breadcrumbPreviewStyle(props) != null) ...[
      'breadcrumbStyle: const CoreBreadcrumbStyle(',
      if (size != CoreBreadcrumbStyle.defaultSeparatorIconSize)
        '  separatorIconStyle: CoreIconStyle(size: CoreIconSize.size${size.toInt()}),',
      if (gap != CoreSpace.space4) '  itemSeparatorGapStyle: CoreGapStyle(size: CoreSpace.space${gap.toInt()}),',
      '),',
    ],
  ];
  return 'Breadcrumb(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
