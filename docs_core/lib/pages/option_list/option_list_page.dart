/// OptionList 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `option_list_web.dart` · `option_list_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 둘이다: `spacing`(줄 사이 간격, CoreSpace 단계의 숫자)과
/// `selection`(줄의 선택 방식, `CoreOptionItemSelection` 이름). 두 플랫폼
/// 빌더와 코드가 같은 뜻으로 읽도록 해석은 이 파일 한 곳에 둔다. 목록은
/// 선택을 들고 있지 않으므로 미리보기의 고른 줄은 고정값이다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/option-list.md`.
const String slug = 'option-list';

/// single 미리보기와 코드의 선택지(정렬 기준) — 값과 라벨.
const List<(String, String)> optionListSortItems = [
  ('latest', '최신순'),
  ('popular', '인기순'),
  ('price', '낮은 가격순'),
];

/// multiple 미리보기와 코드의 선택지(색상 필터) — 값과 라벨.
const List<(String, String)> optionListColorItems = [
  ('black', '검정'),
  ('white', '흰색'),
  ('navy', '남색'),
];

/// [selection] 의 선택지.
List<(String, String)> optionListPreviewItems(CoreOptionItemSelection selection) => switch (selection) {
  CoreOptionItemSelection.single => optionListSortItems,
  CoreOptionItemSelection.multiple => optionListColorItems,
};

/// 미리보기에서 고른 값 — single 은 하나, multiple 은 둘.
Set<String> optionListPreviewSelected(CoreOptionItemSelection selection) => switch (selection) {
  CoreOptionItemSelection.single => const {'latest'},
  CoreOptionItemSelection.multiple => const {'black', 'navy'},
};

/// 속성의 `selection` — 없거나 모르는 이름이면 기본값(single).
CoreOptionItemSelection optionListPreviewSelection(Map<String, String> props) =>
    previewEnum(CoreOptionItemSelection.values, props['selection'], CoreOptionItemSelection.defaultSelection);

/// 속성의 `spacing` → 줄 사이 간격(logical px). 없거나 `CoreSpace` 단계가 아니면
/// `null` — 그때 목록은 `CoreOptionListStyle.defaultSpacing` 으로 그린다.
double? optionListPreviewSpacing(Map<String, String> props) {
  final px = double.tryParse(props['spacing'] ?? '');
  return px != null && CoreSpace.steps.contains(px) ? px : null;
}

/// `option-list/selection` 장면에서 목록 위에 적는 글자.
String optionListSelectionCaption(CoreOptionItemSelection selection) => switch (selection) {
  CoreOptionItemSelection.single => 'single — 고른 줄에 체크 표시',
  CoreOptionItemSelection.multiple => 'multiple — 줄마다 체크박스',
};

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 목록이 가진 겉모습 값은 줄 사이 간격 하나다. 다른 컨트롤은 줄이 어떻게
/// 골라지는지 보여 주는 선택 방식이다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'spacing': '8', 'selection': 'single'},
  controls: [
    DocsPlaygroundChoice(label: 'spacing', prop: 'spacing', options: ['4', '8', '12', '16'], segmented: true),
    DocsPlaygroundChoice(label: '선택 방식', prop: 'selection', options: ['single', 'multiple'], segmented: true),
  ],
  code: _optionListCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// OptionList 에는 크기 단계(`defaultsBySize`)가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _optionListCode(Map<String, String> props, String? label) {
  final selection = optionListPreviewSelection(props);
  final multiple = selection == CoreOptionItemSelection.multiple;
  final spacing = optionListPreviewSpacing(props);
  final lines = [
    if (spacing != null && spacing != CoreOptionListStyle.defaultSpacing)
      'optionListStyle: CoreOptionListStyle(spacing: CoreSpace.space${spacing.toInt()}),',
    'children: [',
    for (final (value, text) in optionListPreviewItems(selection)) ...[
      '  OptionItem(',
      if (multiple) '    selection: CoreOptionItemSelection.multiple,',
      "    label: Text('$text'),",
      if (multiple) "    selected: colors.contains('$value')," else "    selected: sort == '$value',",
      if (multiple) "    onPressed: () => toggleColor('$value')," else "    onPressed: () => setSort('$value'),",
      '  ),',
    ],
    '],',
  ];
  return 'OptionList(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
