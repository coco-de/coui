/// Divider 페이지 — 플레이그라운드와 장면의 공용 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `divider_web.dart` · `divider_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 플레이그라운드의 속성은 `orientation`(선의 방향), `child`(`none` 이면 라벨
/// 없음, 그 밖은 라벨의 `childAlignment`), `thickness`, `indent` ·
/// `endIndent`(켜면 [dividerPreviewInset]), `color`(`primary`)다. 두 플랫폼
/// 빌더와 코드가 같은 뜻으로 읽도록 해석은 이 파일 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/divider.md`.
const String slug = 'divider';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Divider 에는 `CoreComponentSize` 축이 없다 — 선의 굵기는 `dividerStyle` 의
/// `thickness` 로 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 라벨을 켰을 때 선 사이에 넣는 글.
String dividerSampleText(String? label) => label ?? '또는';

/// 플레이그라운드에서 `indent` · `endIndent` 를 켰을 때의 여백.
const double dividerPreviewInset = CoreSpace.space32;

/// 플레이그라운드에서 고르는 선 굵기.
const List<double> dividerPreviewThicknesses = [
  CoreStrokeWidth.stroke1,
  CoreStrokeWidth.stroke2,
  CoreStrokeWidth.stroke4,
];

/// 가로선 무대의 부모 폭 — 가로선은 부모의 폭을 채우므로 정해 둔다.
const double dividerStageWidth = CoreSpace.space256;

/// 세로선 무대의 부모 높이 — 세로선은 부모의 높이를 채우므로 정해 둔다.
const double dividerStageHeight = CoreSpace.space160;

/// 가로선 위 · 아래에 두는 글.
const (String, String) dividerColumnTexts = ('위 내용', '아래 내용');

/// 세로선 왼쪽 · 오른쪽에 두는 글.
const (String, String) dividerRowTexts = ('왼쪽', '오른쪽');

/// `divider/label-alignment` 장면에 놓는 순서.
const List<CoreDividerChildAlignment> dividerSceneAlignments = [
  CoreDividerChildAlignment.start,
  CoreDividerChildAlignment.center,
  CoreDividerChildAlignment.end,
];

/// `divider/indent` 장면의 선 — 설명, 스타일, 라벨을 넣는지.
const List<(String, CoreDividerStyle?, bool)> dividerSceneIndents = [
  ('여백 없음', null, false),
  ('indent 48', CoreDividerStyle(indent: CoreSpace.space48), false),
  ('indent 48 · endIndent 8', CoreDividerStyle(indent: CoreSpace.space48, endIndent: CoreSpace.space8), false),
  ('라벨 · indent 48 · endIndent 8', CoreDividerStyle(indent: CoreSpace.space48, endIndent: CoreSpace.space8), true),
];

/// 권장 · 금지 장면의 항목 묶음.
const List<List<String>> dividerSceneGroups = [
  ['이름', '이메일'],
  ['알림', '언어'],
];

/// `divider/in-row` 장면에서 가로선 앞에 두는 제목.
const String dividerSceneRowTitle = '이전 기록';

/// `divider/in-row` 장면에서 세로선으로 나누는 도구 이름.
const List<String> dividerSceneTools = ['굵게', '기울임', '밑줄'];

/// Resizable 관련 카드의 두 영역 이름.
const (String, String) dividerScenePanes = ('목록', '본문');

/// 속성의 `orientation`. 없거나 모르는 값은 가로.
CoreDividerOrientation dividerPreviewOrientation(Map<String, String> props) =>
    previewEnum(CoreDividerOrientation.values, props['orientation'], CoreDividerOrientation.horizontal);

/// 속성의 `child` → 라벨이 놓이는 자리. `none` 이거나 모르는 값이면
/// `null`(라벨 없음).
CoreDividerChildAlignment? dividerPreviewChildAlignment(Map<String, String> props) {
  for (final alignment in CoreDividerChildAlignment.values) {
    if (alignment.name == props['child']) return alignment;
  }
  return null;
}

/// 속성 → `dividerStyle`. 기본값에서 바꾼 것이 없으면 `null`. 두 플랫폼의
/// 속성 빌더와 코드가 함께 읽는다.
CoreDividerStyle? dividerPreviewStyle(Map<String, String> props) {
  final alignment = dividerPreviewChildAlignment(props);
  final thickness = double.tryParse(props['thickness'] ?? '');
  final changesThickness =
      thickness != CoreDividerStyle.defaultThickness && dividerPreviewThicknesses.contains(thickness);
  final style = CoreDividerStyle(
    color: props['color'] == 'primary' ? const CoreColor.token(CoreColors.primary) : null,
    thickness: changesThickness ? thickness : null,
    indent: previewFlag(props, 'indent') ? dividerPreviewInset : null,
    endIndent: previewFlag(props, 'endIndent') ? dividerPreviewInset : null,
    childAlignment: alignment == CoreDividerStyle.defaultChildAlignment ? null : alignment,
  );
  return style == const CoreDividerStyle() ? null : style;
}

// 방향과 라벨 위치의 선택지는 Core enum 에서 읽는다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'orientation': CoreDividerOrientation.horizontal.name,
    'child': CoreDividerStyle.defaultChildAlignment.name,
    'thickness': '${CoreDividerStyle.defaultThickness.toInt()}',
  },
  label: dividerSampleText(null),
  controls: [
    DocsPlaygroundChoice(
      label: 'orientation',
      prop: 'orientation',
      options: [for (final orientation in CoreDividerOrientation.values) orientation.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'child 위치',
      prop: 'child',
      options: ['none', for (final alignment in CoreDividerChildAlignment.values) alignment.name],
    ),
    DocsPlaygroundChoice(
      label: 'thickness',
      prop: 'thickness',
      options: [for (final thickness in dividerPreviewThicknesses) '${thickness.toInt()}'],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: 'indent 32', on: {'indent': 'true'}),
    const DocsPlaygroundFlag(label: 'endIndent 32', on: {'endIndent': 'true'}),
    const DocsPlaygroundFlag(label: 'primary 색', on: {'color': 'primary'}),
  ],
  code: _dividerCode,
  webCode: _dividerWebCode,
);

/// 속성 → `Divider(...)` 의 줄들. 기본값과 같은 것은 적지 않는다. 두 플랫폼의
/// 코드가 같이 쓰고, 둘레의 부모 코드만 다르다.
List<String> _dividerLines(Map<String, String> props, String? label) {
  final style = dividerPreviewStyle(props);
  final arguments = <String>[
    if (dividerPreviewOrientation(props) == CoreDividerOrientation.vertical)
      'orientation: CoreDividerOrientation.vertical,',
    if (style != null) ...[
      'dividerStyle: CoreDividerStyle(',
      if (style.color != null) '  color: CoreColor.token(CoreColors.primary),',
      if (style.thickness case final thickness?) '  thickness: CoreStrokeWidth.stroke${thickness.toInt()},',
      if (style.indent case final indent?) '  indent: CoreSpace.space${indent.toInt()},',
      if (style.endIndent case final endIndent?) '  endIndent: CoreSpace.space${endIndent.toInt()},',
      if (style.childAlignment case final alignment?) '  childAlignment: CoreDividerChildAlignment.${alignment.name},',
      '),',
    ],
    if (dividerPreviewChildAlignment(props) != null)
      "child: Text('${dividerSampleText(label)}').labelMedium.onSurfaceVariant,",
  ];
  if (arguments.isEmpty) return const ['Divider(),'];
  return ['Divider(', for (final line in arguments) '  $line', '),'];
}

String _dividerCode(Map<String, String> props, String? label) {
  final lines = _dividerLines(props, label);
  if (dividerPreviewOrientation(props) == CoreDividerOrientation.vertical) {
    return [
      'SizedBox(',
      '  height: CoreSpace.space${dividerStageHeight.toInt()},',
      '  child: Row(',
      '    mainAxisSize: MainAxisSize.min,',
      '    spacing: CoreSpace.space16,',
      '    children: [',
      "      Text('${dividerRowTexts.$1}'),",
      for (final line in lines) '      $line',
      "      Text('${dividerRowTexts.$2}'),",
      '    ],',
      '  ),',
      ')',
    ].join('\n');
  }
  return [
    'Column(',
    '  mainAxisSize: MainAxisSize.min,',
    '  spacing: CoreSpace.space16,',
    '  children: [',
    "    Text('${dividerColumnTexts.$1}'),",
    for (final line in lines) '    $line',
    "    Text('${dividerColumnTexts.$2}'),",
    '  ],',
    ')',
  ].join('\n');
}

String _dividerWebCode(Map<String, String> props, String? label) {
  final vertical = dividerPreviewOrientation(props) == CoreDividerOrientation.vertical;
  final (before, after) = vertical ? dividerRowTexts : dividerColumnTexts;
  return [
    'div(',
    '  [',
    "    Text('$before'),",
    for (final line in _dividerLines(props, label)) '    $line',
    "    Text('$after'),",
    '  ],',
    "  classes: 'flex ${vertical ? 'flex-row' : 'flex-col'} items-center gap-space16',",
    if (vertical) "  styles: Styles(raw: {'height': '\${CoreSpace.space${dividerStageHeight.toInt()}}px'}),",
    ')',
  ].join('\n');
}
