/// OptionItem 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `option_item_web.dart` · `option_item_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/option-item.md`.
const String slug = 'option-item';

/// 미리보기 · 코드가 함께 쓰는 라벨과 설명.
const String optionItemPreviewLabel = '무료 배송';

/// [optionItemPreviewLabel] 아래의 설명.
const String optionItemPreviewDescription = '3만원 이상 주문';

/// 목록 장면의 정렬 기준 — 하나만 고르고, 첫 줄이 고른 줄이다.
const List<String> optionItemListLabels = ['최신순', '인기순', '낮은 가격순'];

/// 상태 장면의 줄 — 이름, 고름 여부, 활성 여부.
const List<(String, bool, bool)> optionItemStateRows = [
  ('기본', false, true),
  ('고름', true, true),
  ('비활성', false, false),
  ('고름 · 비활성', true, false),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `leading` 의 값은 `page_kit` 의 아이콘 이름이다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'selection': 'single', 'selected': 'true'},
  label: optionItemPreviewLabel,
  controls: [
    DocsPlaygroundChoice(label: 'selection', prop: 'selection', options: ['single', 'multiple'], segmented: true),
    DocsPlaygroundFlag(label: '고름', on: {'selected': 'true'}),
    DocsPlaygroundFlag(label: '설명', on: {'description': optionItemPreviewDescription}),
    DocsPlaygroundFlag(label: '앞 아이콘', on: {'leading': 'star'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _optionItemCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// OptionItem 에는 크기 파라미터가 없다 — 줄의 치수는 `CoreOptionItemStyle` 의
/// 기본값 하나다.
DocsSizeSpec Function()? get sizeSpec => null;

String _optionItemCode(Map<String, String> props, String? label) {
  final selection = props['selection'] ?? 'single';
  final lines = [
    if (selection != 'single') 'selection: CoreOptionItemSelection.$selection,',
    if (props['leading'] case final icon?) 'leading: Icon(LucideIcons.${docsIconIdentifier(icon)}),',
    "label: Text('${label ?? optionItemPreviewLabel}'),",
    if (props['description'] case final description?) "description: Text('$description'),",
    'selected: ${previewFlag(props, 'selected')},',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onPressed: chooseOption,',
  ];
  return 'OptionItem(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
