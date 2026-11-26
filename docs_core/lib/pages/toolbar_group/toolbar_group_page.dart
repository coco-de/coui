/// ToolbarGroup 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `toolbar_group_web.dart` · `toolbar_group_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// `ToolbarGroup` 은 놓은 자리에 그대로 그려지므로 무대에 실제 위젯을 놓는다.
/// 속성은 둘이다: `direction`(`CoreAxis` 의 이름)과 `surfaceStyle`
/// (`liquidGlass` 면 그 그룹만 리퀴드 글라스, 없으면 주변 서페이스 스타일).
/// 두 플랫폼 빌더와 코드가 같은 뜻으로 읽도록 해석과 미리보기의 동작은 이
/// 파일에 둔다.
///
/// 아이콘 버튼의 이름은 Flutter 가 `Semantics(label:)`, Web 이
/// `Button(attributes:)` 로 주므로 코드가 플랫폼마다 다르다(`webCode`).
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/toolbar-group.md`.
const String slug = 'toolbar-group';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'direction': 'horizontal'},
  controls: [
    DocsPlaygroundChoice(label: 'direction', prop: 'direction', options: ['horizontal', 'vertical'], segmented: true),
    DocsPlaygroundFlag(label: 'Liquid Glass', on: {'surfaceStyle': 'liquidGlass'}),
  ],
  code: _toolbarGroupCode,
  webCode: _toolbarGroupWebCode,
);

/// 크기 표. ToolbarGroup 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기 그룹의 접근 가능한 이름.
const String toolbarDemoLabel = '편집 도구';

/// 속성 미리보기의 아이콘 버튼 — (코드의 콜백 이름, 버튼 이름, 아이콘).
const List<(String, String, IconName)> toolbarDemoActions = [
  ('undo', '실행 취소', LucideIcons.undo2),
  ('redo', '다시 실행', LucideIcons.redo2),
  ('share', '공유', LucideIcons.share),
];

/// 이 그룹만 리퀴드 글라스로 그리는 패널 스타일.
const CorePopupStyle toolbarDemoGlassStyle = CorePopupStyle(surfaceStyle: CoreSurfaceStyleId.liquidGlass);

/// 문서의 서페이스 스타일과 상관없이 불투명 모양으로 그리는 패널 스타일 —
/// 두 모양을 나란히 비교하는 장면이 쓴다.
const CorePopupStyle toolbarDemoOpaqueStyle = CorePopupStyle(surfaceStyle: CoreSurfaceStyleId.defaultStyle);

/// 속성의 `direction` → 컨트롤을 놓는 방향. 없거나 모르는 값은 가로.
CoreAxis toolbarPreviewDirection(Map<String, String> props) =>
    previewEnum(CoreAxis.values, props['direction'], CoreAxis.horizontal);

/// 속성의 `surfaceStyle` → 패널 스타일. `liquidGlass` 만 그룹에 유리를 주고,
/// 나머지는 스타일을 주지 않아 주변 서페이스 스타일을 따른다.
CorePopupStyle? toolbarPreviewStyle(Map<String, String> props) =>
    props['surfaceStyle'] == 'liquidGlass' ? toolbarDemoGlassStyle : null;

String _toolbarGroupCode(Map<String, String> props, String? label) => _toolbarCode(props, [
  for (final (callback, name, icon) in toolbarDemoActions) ...[
    'Semantics(',
    "  label: '$name',",
    '  child: Button(',
    '    variant: CoreButtonVariant.ghost,',
    '    shape: CoreButtonShape.square,',
    '    onPressed: $callback,',
    '    child: Icon(LucideIcons.${docsIconIdentifier(icon.name)}),',
    '  ),',
    '),',
  ],
]);

String _toolbarGroupWebCode(Map<String, String> props, String? label) => _toolbarCode(props, [
  for (final (callback, name, icon) in toolbarDemoActions) ...[
    'Button(',
    '  variant: CoreButtonVariant.ghost,',
    '  shape: CoreButtonShape.square,',
    '  onPressed: $callback,',
    "  attributes: {'aria-label': '$name'},",
    '  child: Icon(LucideIcons.${docsIconIdentifier(icon.name)}),',
    '),',
  ],
]);

/// 두 플랫폼이 같이 쓰는 그룹의 틀 — 버튼 줄만 다르다.
String _toolbarCode(Map<String, String> props, List<String> children) {
  final lines = [
    "ariaLabel: '$toolbarDemoLabel',",
    if (toolbarPreviewDirection(props) == CoreAxis.vertical) 'direction: CoreAxis.vertical,',
    if (toolbarPreviewStyle(props) != null) ...[
      'popupStyle: CorePopupStyle(',
      '  surfaceStyle: CoreSurfaceStyleId.liquidGlass,',
      '),',
    ],
    'children: [',
    for (final line in children) '  $line',
    '],',
  ];
  return 'ToolbarGroup(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
