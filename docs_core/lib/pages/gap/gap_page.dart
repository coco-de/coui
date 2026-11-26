/// Gap 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `gap_web.dart` · `gap_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// Gap 은 혼자서는 보이지 않는다 — 미리보기는 늘 부모(가로 · 세로 flex) 안의
/// 두 요소 사이에 Gap 을 둔다. 속성은 둘이다: `size`(CoreSpace 단계의 숫자,
/// `16` → `Gap.space16()`)와 `direction`(`row` · `column`, 부모의 방향).
/// 두 플랫폼 빌더와 코드가 같은 뜻으로 읽도록 해석은 이 파일의
/// [gapPreviewSize] · [gapPreviewVertical] 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/gap.md`.
const String slug = 'gap';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'size': '16', 'direction': 'row'},
  controls: [
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: ['4', '8', '12', '16', '24', '32'],
      segmented: true,
    ),
    DocsPlaygroundChoice(label: '부모 방향', prop: 'direction', options: ['row', 'column'], segmented: true),
  ],
  code: _gapCode,
  webCode: _gapWebCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// Gap 의 크기는 크기 단계(`CoreComponentSize`)가 아니라 간격 토큰
/// (`CoreSpace`) 하나라서 `defaultsBySize` 가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `size` → 간격(logical px). `CoreSpace` 의 단계가 아니면 `null` —
/// 그때 미리보기는 `Gap()` 의 기본 간격을 그린다.
double? gapPreviewSize(Map<String, String> props) {
  final px = double.tryParse(props['size'] ?? '');
  return px != null && CoreSpace.steps.contains(px) ? px : null;
}

/// 속성의 `direction` 이 세로(`column`)인가. 없거나 모르는 값은 가로.
bool gapPreviewVertical(Map<String, String> props) => props['direction'] == 'column';

/// `gap/sizes` 장면에 늘어놓는 단계 — 두 플랫폼 장면이 함께 읽는다.
const List<double> gapSceneSizeSteps = [
  CoreSpace.space4,
  CoreSpace.space8,
  CoreSpace.space16,
  CoreSpace.space24,
  CoreSpace.space32,
];

/// `gap/max-gap` 장면의 두 부모 — 설명과 부모 폭(logical px). 두 플랫폼
/// 장면이 함께 읽는다.
const List<(String, double)> gapSceneMaxGapParents = [
  ('넓은 부모 — 64를 다 씁니다', 240),
  ('좁은 부모 — 남은 만큼으로 줄어듭니다', 120),
];

String _gapCode(Map<String, String> props, String? label) {
  final body = _gapChildren(props);
  return '${gapPreviewVertical(props) ? 'Column' : 'Row'}(\n  children: [\n$body\n  ],\n)';
}

String _gapWebCode(Map<String, String> props, String? label) {
  final body = _gapChildren(props);
  final direction = gapPreviewVertical(props) ? 'flex-col' : 'flex-row';
  return "div(\n  [\n$body\n  ],\n  classes: 'flex $direction items-center',\n)";
}

/// 두 플랫폼이 같이 쓰는 자식 줄 — 부모만 다르다.
String _gapChildren(Map<String, String> props) {
  final size = gapPreviewSize(props);
  return [
    "Button(variant: CoreButtonVariant.outline, onPressed: save, child: Text('A')),",
    if (size == null) 'const Gap(),' else 'const Gap.space${size.toInt()}(),',
    "Button(variant: CoreButtonVariant.outline, onPressed: save, child: Text('B')),",
  ].map((line) => '    $line').join('\n');
}
