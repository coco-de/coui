/// Sortable 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `sortable_web.dart` · `sortable_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 위젯 생성자의 이름을 그대로 쓴다 — `axis`(`CoreSortableAxis` 의
/// 이름) · `removable` · `enabled`. 두 플랫폼 빌더와 코드가 같은 뜻으로
/// 읽도록 해석은 이 파일 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/sortable.md`.
const String slug = 'sortable';

/// 세로 목록 미리보기 항목.
const List<String> kSortablePreviewItems = ['기획', '디자인', '개발'];

/// `horizontal` 미리보기 항목 — 좁은 Variant 무대에 한 줄로 들어가게 짧은 것
/// 두 개만 둔다. 웹의 가로 목록은 자리가 모자라면 줄을 바꾸지 않고 행을
/// 내용보다 좁힌다.
const List<String> kSortableHorizontalPreviewItems = ['기획', '개발'];

/// `grid` 미리보기 항목 — 줄이 바뀌는 것이 보이게 여섯 개를 둔다.
const List<String> kSortableGridPreviewItems = ['기획', '디자인', '개발', '검수', '배포', '회고'];

/// 세로 목록 미리보기의 폭(logical px).
const double kSortablePreviewWidth = 320;

/// `grid` 미리보기의 폭(logical px) — 항목이 한 줄에 다 들어가지 않는 폭.
const double kSortableGridPreviewWidth = 288;

/// 속성의 `axis` — 없거나 모르는 값은 계약의 기본값.
CoreSortableAxis sortablePreviewAxis(Map<String, String> props) =>
    previewEnum(CoreSortableAxis.values, props['axis'], CoreSortableContract.defaultAxis);

/// [axis] 미리보기의 처음 항목.
List<String> sortablePreviewItems(CoreSortableAxis axis) => switch (axis) {
  CoreSortableAxis.vertical => kSortablePreviewItems,
  CoreSortableAxis.horizontal => kSortableHorizontalPreviewItems,
  CoreSortableAxis.grid => kSortableGridPreviewItems,
};

/// `onReorder` 가 알려 준 대로 옮긴 새 목록 — [newIndex] 는 옮기는 항목을
/// 먼저 뺀 목록에 넣을 자리다.
List<String> sortableMoved(List<String> items, int oldIndex, int newIndex) {
  final rest = sortableRemoved(items, oldIndex);
  return [...rest.take(newIndex), items[oldIndex], ...rest.skip(newIndex)];
}

/// [index] 항목을 뺀 새 목록.
List<String> sortableRemoved(List<String> items, int index) => [
  for (final (position, item) in items.indexed)
    if (position != index) item,
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'axis': 'vertical'},
  controls: [
    DocsPlaygroundChoice(label: 'axis', prop: 'axis', options: ['vertical', 'horizontal', 'grid'], segmented: true),
    DocsPlaygroundFlag(label: '제거 버튼', on: {'removable': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _sortableCode,
  webCode: _sortableWebCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null` — `CoreSortableStyle` 에는
/// `defaultsBySize` 가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _sortableCode(Map<String, String> props, String? label) => _sortableSnippet(props, _flutterItemBuilder(props));

String _sortableWebCode(Map<String, String> props, String? label) => _sortableSnippet(props, _webItemBuilder(props));

/// 두 플랫폼이 같이 쓰는 생성자 줄 — `itemBuilder` 만 다르다.
String _sortableSnippet(Map<String, String> props, List<String> itemBuilder) {
  final axis = sortablePreviewAxis(props);
  final removable = previewFlag(props, 'removable');
  final lines = [
    'itemCount: tasks.length,',
    if (axis != CoreSortableContract.defaultAxis) 'axis: CoreSortableAxis.${axis.name},',
    'onReorder: reorderTasks,',
    if (removable) 'removable: true,',
    if (removable) 'onRemove: removeTask,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    ...itemBuilder,
  ];
  return 'Sortable(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

/// 세로 목록은 글자가 남는 폭을 채우고, 가로 · 격자 목록은 내용만큼만 쓴다.
List<String> _flutterItemBuilder(Map<String, String> props) {
  final vertical = sortablePreviewAxis(props) == CoreSortableAxis.vertical;
  return [
    'itemBuilder: (context, index, dragHandle, removeButton) => Row(',
    if (!vertical) '  mainAxisSize: MainAxisSize.min,',
    '  spacing: CoreSpace.space8,',
    '  children: [',
    '    dragHandle,',
    if (vertical) '    Expanded(child: Text(tasks[index])),' else '    Text(tasks[index]),',
    if (previewFlag(props, 'removable')) '    ?removeButton,',
    '  ],',
    '),',
  ];
}

List<String> _webItemBuilder(Map<String, String> props) {
  final vertical = sortablePreviewAxis(props) == CoreSortableAxis.vertical;
  return [
    'itemBuilder: (index, dragHandle, removeButton) => div(',
    '  [',
    '    dragHandle,',
    if (vertical) "    div([Text(tasks[index])], classes: 'flex-1')," else '    Text(tasks[index]),',
    if (previewFlag(props, 'removable')) '    ?removeButton,',
    '  ],',
    if (vertical)
      r"  classes: 'flex flex-1 items-center gap-${CoreSpace.scale.space8}',"
    else
      r"  classes: 'flex items-center gap-${CoreSpace.scale.space8}',",
    '),',
  ];
}
