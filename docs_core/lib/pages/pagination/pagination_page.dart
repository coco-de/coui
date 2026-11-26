/// Pagination 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `pagination_web.dart` · `pagination_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 크기 단계(`size`)가 없어 크기 표는 없다 — 버튼 크기는
/// `CorePaginationStyle.buttonSize` 하나다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/pagination.md`.
const String slug = 'pagination';

/// 속성에 `totalPages` 가 없을 때와 장면이 쓰는 전체 페이지 수.
const int paginationPreviewTotalPages = 10;

/// 두 플랫폼 `Pagination` 의 `maxPages` 기본값 — 코드에는 이 값과 다를 때만 적는다.
const int paginationDefaultMaxPages = 3;

/// "좁은 폭" 미리보기 상자의 폭(logical px).
const double paginationPreviewNarrowWidth = 240;

/// `pagination/window` 장면의 현재 페이지 — 전체 10 가운데 앞 · 중간 · 뒤.
const List<int> paginationWindowPages = [2, 5, 9];

/// `pagination/states` 장면의 줄 — 이름, 현재 페이지, 활성 여부.
const List<(String, int, bool)> paginationStateRows = [
  ('기본', 2, true),
  ('첫 페이지', 1, true),
  ('비활성', 2, false),
];

/// Table 관련 카드의 머리글.
const (String, String) paginationTableHeader = ('주문', '금액');

/// Table 관련 카드의 행.
const List<(String, String)> paginationTableRows = [
  ('A-102', '12,000원'),
  ('A-101', '8,000원'),
];

/// Select 관련 카드의 페이지당 개수 선택지 — 값과 라벨.
const List<(String, String)> paginationPageSizeItems = [
  ('10', '10개씩'),
  ('20', '20개씩'),
  ('50', '50개씩'),
];

/// 속성의 `totalPages` — 없거나 숫자가 아니면 [paginationPreviewTotalPages], 1 미만이면 1.
int paginationPreviewTotal(Map<String, String> props) {
  final total = int.tryParse(props['totalPages'] ?? '') ?? paginationPreviewTotalPages;
  return total < 1 ? 1 : total;
}

/// 속성의 `page`(처음 보일 페이지) — 1 ~ 전체 페이지 수로 맞춘다. 없으면 1.
int paginationPreviewPage(Map<String, String> props) =>
    (int.tryParse(props['page'] ?? '') ?? 1).clamp(1, paginationPreviewTotal(props));

/// 속성의 `maxPages` — 없으면 [paginationDefaultMaxPages], 1 미만이면 1.
int paginationPreviewMaxPages(Map<String, String> props) {
  final maxPages = int.tryParse(props['maxPages'] ?? '') ?? paginationDefaultMaxPages;
  return maxPages < 1 ? 1 : maxPages;
}

/// 플레이그라운드.
///
/// `maxPages` 선택지는 홀수만 둔다 — 짝수는 번호 창과 `…` 가 어긋난다(페이지의
/// 알려진 제약). "좁은 폭" 은 위젯 속성이 아니라 미리보기를 놓는 상자의 폭이라
/// 코드를 바꾸지 않는다 — 버튼은 컴포넌트가 스스로 줄인다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'page': '5', 'totalPages': '10', 'maxPages': '3'},
  controls: [
    DocsPlaygroundChoice(label: 'totalPages', prop: 'totalPages', options: ['3', '10', '50'], segmented: true),
    DocsPlaygroundChoice(label: 'maxPages', prop: 'maxPages', options: ['3', '5', '7'], segmented: true),
    DocsPlaygroundFlag(label: 'showLabel', on: {'showLabel': 'true'}),
    DocsPlaygroundFlag(
      label: '첫 · 마지막 버튼 끄기',
      on: {'showSkipToFirstPage': 'false', 'showSkipToLastPage': 'false'},
    ),
    DocsPlaygroundFlag(
      label: '끝 화살표 숨기기',
      on: {'hidePreviousOnFirstPage': 'true', 'hideNextOnLastPage': 'true'},
    ),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
    DocsPlaygroundFlag(label: '좁은 폭', on: {'narrow': 'true'}),
  ],
  code: _paginationCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

String _paginationCode(Map<String, String> props, String? label) {
  final maxPages = paginationPreviewMaxPages(props);
  final lines = [
    'page: page,',
    'totalPages: ${paginationPreviewTotal(props)},',
    'onPageChanged: (next) => setState(() => page = next),',
    if (maxPages != paginationDefaultMaxPages) 'maxPages: $maxPages,',
    if (previewFlag(props, 'showLabel')) 'showLabel: true,',
    if (!previewFlag(props, 'showSkipToFirstPage', fallback: true)) 'showSkipToFirstPage: false,',
    if (!previewFlag(props, 'showSkipToLastPage', fallback: true)) 'showSkipToLastPage: false,',
    if (previewFlag(props, 'hidePreviousOnFirstPage')) 'hidePreviousOnFirstPage: true,',
    if (previewFlag(props, 'hideNextOnLastPage')) 'hideNextOnLastPage: true,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
  ];
  return 'Pagination(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
