/// ItemPicker 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `item_picker_web.dart` · `item_picker_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 `layout`(`CoreItemPickerLayout` 이름), `gridColumns`(격자의 열 수),
/// `title`, `showSearch`, `enabled` 다. 두 플랫폼 빌더와 코드가 같은 뜻으로
/// 읽도록 해석은 이 파일 한 곳에 두고, 항목 글자도 여기에 둔다.
///
/// `ItemPicker` 는 고른 값을 바꾸지 않고 누른 항목을 `onChanged` 로 넘기기만
/// 한다. 그래서 속성 미리보기는 그 값을 들고 `selectedValue` 로 다시 넘긴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/item-picker.md`.
const String slug = 'item-picker';

/// 속성 미리보기와 코드의 항목. 두 글자 이름만 둬서 격자 3 열까지는 고른 칸에도
/// 두 글자가 들어가는 폭이 남는다. 4 열(기본값)은 고른 칸의 글자 자리가 한 글자보다
/// 좁아, 글자가 꺾이는 모습이 그대로 보인다.
const List<String> itemPickerCities = ['서울', '부산', '대구', '인천', '광주', '대전'];

/// 구조 · 상태 장면의 짧은 목록.
const List<String> itemPickerShortCities = ['서울', '부산', '대구'];

/// 미리보기에서 처음 고른 항목.
const String itemPickerSelected = '부산';

/// 미리보기의 구역 라벨.
const String itemPickerTitle = '지역';

/// `item-picker/layouts` 장면의 두 칸 이름과 격자의 열 수.
const String itemPickerListCaption = 'list';
const String itemPickerGridCaption = 'grid · gridColumns: 3';
const int itemPickerSceneColumns = 3;

/// `item-picker/states` 장면의 칸 이름.
const String itemPickerSelectedCaption = '선택';
const String itemPickerDisabledCaption = '비활성';
const String itemPickerEmptyCaption = '항목 없음';

/// 검색 입력 예 — 항목이 셋뿐인 목록.
const List<String> itemPickerTextSizes = ['작게', '보통', '크게'];
const String itemPickerTextSizeSelected = '보통';
const String itemPickerTextSizeTitle = '글자 크기';

/// 항목 글자 예 — 구분되는 이름과, 같은 글자가 겹친 목록.
const List<String> itemPickerBranches = ['서울 중구', '부산 중구', '대구 중구'];
const String itemPickerBranchSelected = '부산 중구';
const List<String> itemPickerDuplicates = ['중구', '중구', '중구'];
const String itemPickerDuplicateSelected = '중구';
const String itemPickerBranchTitle = '지점';

/// 속성의 `layout` — 없거나 모르는 이름이면 기본값(list).
CoreItemPickerLayout itemPickerPreviewLayout(Map<String, String> props) =>
    previewEnum(CoreItemPickerLayout.values, props['layout'], CoreItemPickerLayout.defaultLayout);

/// 속성의 `gridColumns` — 1 이상의 정수가 아니면 기본값(4).
int itemPickerPreviewColumns(Map<String, String> props) {
  final columns = int.tryParse(props['gridColumns'] ?? '');
  return columns != null && columns > 0 ? columns : CoreItemPickerLayout.defaultGridColumns;
}

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `gridColumns` 는 `layout` 이 grid 일 때만 화면과 코드에 나타난다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'layout': 'list', 'gridColumns': '3', 'title': itemPickerTitle},
  controls: [
    DocsPlaygroundChoice(label: 'layout', prop: 'layout', options: ['list', 'grid'], segmented: true),
    DocsPlaygroundChoice(label: 'gridColumns (grid)', prop: 'gridColumns', options: ['2', '3', '4'], segmented: true),
    DocsPlaygroundFlag(label: '제목 (title)', on: {'title': itemPickerTitle}),
    DocsPlaygroundFlag(label: '검색 입력 숨기기', on: {'showSearch': 'false'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _itemPickerCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// ItemPicker 에는 크기 단계(`defaultsBySize`)가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _itemPickerCode(Map<String, String> props, String? label) {
  final layout = itemPickerPreviewLayout(props);
  final columns = itemPickerPreviewColumns(props);
  final title = props['title'];
  final lines = [
    "items: const [${itemPickerCities.map((city) => "'$city'").join(', ')}],",
    'selectedValue: city,',
    if (title != null) "title: '$title',",
    if (layout == CoreItemPickerLayout.grid) ...[
      'layout: CoreItemPickerLayout.grid,',
      if (columns != CoreItemPickerLayout.defaultGridColumns) 'gridColumns: $columns,',
    ],
    if (!previewFlag(props, 'showSearch', fallback: true)) 'showSearch: false,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setCity,',
  ];
  return 'ItemPicker(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
