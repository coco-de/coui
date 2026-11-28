/// DefinitionList 페이지 — 플레이그라운드와 장면이 함께 읽는 예시 글. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `definition_list_web.dart` · `definition_list_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 설명의 위젯 타입은 플랫폼마다 달라, 예시는 (용어, 설명) 글자 쌍으로 두고
/// [definitionListEntries] 가 각 플랫폼의 항목으로 바꾼다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/definition-list.md`.
const String slug = 'definition-list';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 글자 쌍 → 목록 항목. [W] 는 플랫폼의 위젯 타입이다.
List<CoreDefinitionEntry<W>> definitionListEntries<W>(List<(String, String)> samples) => [
  for (final (term, description) in samples) CoreDefinitionEntry<W>(term: term, description: description),
];

/// 속성의 `layout` — 없거나 모르는 값은 위젯의 기본값(`stacked`).
CoreDefinitionLayout definitionListLayoutOf(Map<String, String> props) =>
    previewEnum(CoreDefinitionLayout.values, props['layout'], CoreDefinitionLayout.stacked);

/// 플레이그라운드와 속성 미리보기의 항목. 숫자 폭 차이가 보이도록 날짜를 넣고,
/// 고정폭 서체 차이가 보이도록 영문 코드를 넣는다.
const List<(String, String)> definitionListOrderSamples = [
  ('주문번호', 'A-1048-2711'),
  ('주문일', '2026-11-11'),
  ('발송일', '2026-11-18'),
  ('도착 예정', '2026-11-20'),
];

/// 구조 장면의 항목.
const List<(String, String)> definitionListAnatomySamples = [
  ('주문번호', 'A-1048-2711'),
  ('주문일', '2026-11-11'),
];

/// 위아래 배치 장면의 항목.
const List<(String, String)> definitionListBusinessSamples = [
  ('상호', '예시상사'),
  ('사업자등록번호', '000-00-00000'),
  ('통신판매업신고번호', '2026-예시-00000'),
];

/// 한 줄 흐름 장면의 항목.
const List<(String, String)> definitionListInlineSamples = [
  ('상호', '예시상사'),
  ('고객센터', '000-0000-0000'),
  ('사업자등록번호', '000-00-00000'),
];

/// 모양이 같은 날짜 — 고정폭 숫자를 비교하는 항목.
const List<(String, String)> definitionListDateSamples = [
  ('주문일', '2026-11-11'),
  ('발송일', '2026-11-18'),
  ('도착 예정', '2026-11-20'),
];

/// 길이가 다른 금액 — 고정폭 숫자를 켜도 자릿값이 맞지 않는 항목.
const List<(String, String)> definitionListAmountSamples = [
  ('상품 금액', '1,111,000원'),
  ('배송비', '8,000원'),
  ('합계', '1,119,000원'),
];

/// 코드 값 — `mono` 를 보이는 항목.
const List<(String, String)> definitionListCodeSamples = [
  ('주문번호', 'A-1048-2711'),
  ('추적 코드', 'KR-7F3A9C21'),
];

/// 글자 장면의 줄 — 두 플랫폼 장면이 함께 읽는다.
const List<({String caption, List<(String, String)> samples, bool numeric, bool mono})> definitionListTypographyCases =
    [
      (caption: '기본', samples: definitionListDateSamples, numeric: false, mono: false),
      (caption: 'numeric: true', samples: definitionListDateSamples, numeric: true, mono: false),
      (caption: 'mono: true', samples: definitionListCodeSamples, numeric: false, mono: true),
    ];

/// 용어 열 폭 장면 — 용어가 짧은 목록.
const List<(String, String)> definitionListShortTermSamples = [
  ('상호', '예시상사'),
  ('고객센터', '000-0000-0000'),
];

/// 용어 열 폭 장면 — 용어가 긴 목록.
const List<(String, String)> definitionListWideTermSamples = [
  ('사업자등록번호', '000-00-00000'),
  ('통신판매업신고번호', '2026-예시-00000'),
];

/// 용어 열 폭 장면의 스타일 — 두 목록이 같은 값을 쓴다.
const CoreDefinitionListStyle definitionListTermWidthStyle = CoreDefinitionListStyle(termWidth: CoreSpace.space120);

/// 번호가 둘인 항목 — 용어를 붙이는 예시.
const List<(String, String)> definitionListRegistrationSamples = [
  ('사업자등록번호', '000-00-00000'),
  ('법인등록번호', '000000-0000000'),
];

/// 위 두 번호를 한 문자열에 이어 붙인 예시.
const String definitionListOneLineText = '사업자등록번호 000-00-00000 · 법인등록번호 000000-0000000';

/// 용어가 긴 항목.
const List<(String, String)> definitionListLongTermSamples = [
  ('고객센터 전화 상담 가능 시간', '평일 10시부터 18시까지'),
];

/// 링크가 든 설명 장면의 주소.
const String definitionListReceiptUrl = 'https://example.com/receipts/1048';

/// 링크가 든 설명 장면의 두 줄 주소.
const List<String> definitionListAddressLines = ['서울시 예시구 예시로 1', '3층 301호'];

// 선택지는 enum 에서 읽는다 — 배치가 늘면 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'layout': CoreDefinitionLayout.columns.name, 'numeric': 'true'},
  controls: [
    DocsPlaygroundChoice(
      label: 'layout',
      prop: 'layout',
      options: [for (final layout in CoreDefinitionLayout.values) layout.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: 'numeric', on: {'numeric': 'true'}),
    const DocsPlaygroundFlag(label: 'mono', on: {'mono': 'true'}),
  ],
  code: _definitionListCode,
);

/// 속성 → 코드. 기본값과 같은 속성은 적지 않는다.
String _definitionListCode(Map<String, String> props, String? label) {
  final layout = definitionListLayoutOf(props);
  final lines = [
    'items: const [',
    for (final (term, description) in definitionListOrderSamples)
      "  CoreDefinitionEntry(term: '$term', description: '$description'),",
    '],',
    if (layout != CoreDefinitionLayout.stacked) 'layout: CoreDefinitionLayout.${layout.name},',
    if (previewFlag(props, 'numeric')) 'numeric: true,',
    if (previewFlag(props, 'mono')) 'mono: true,',
  ];
  return 'DefinitionList(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
