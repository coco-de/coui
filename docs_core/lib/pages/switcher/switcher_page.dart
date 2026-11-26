/// Switcher 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `switcher_web.dart` · `switcher_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 화면 · 창 크기 · 속성 해석은 이 파일 한 곳에 둔다 — 두 플랫폼의
/// 그림과 코드가 같은 값을 쓴다. 크기 축이 없어 크기 표는 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/switcher.md`.
const String slug = 'switcher';

/// 미리보기의 화면 — 이름과 설명. 순서가 곧 `index` 다.
const List<(String, String)> kSwitcherPreviewViews = [
  ('개요', '이번 달 요약'),
  ('상세', '항목별 내역'),
  ('리뷰', '받은 의견'),
];

/// 미리보기 창의 폭(logical px).
const double kSwitcherPreviewWidth = 256;

/// 미리보기 창의 높이(logical px).
const double kSwitcherPreviewHeight = 112;

/// 나란히 놓는 작은 창의 폭(logical px).
const double kSwitcherSampleWidth = 160;

/// 나란히 놓는 작은 창의 높이(logical px).
const double kSwitcherSampleHeight = 80;

/// 속성의 `index` — 미리보기 화면의 범위 안으로.
int switcherPreviewIndex(Map<String, String> props) =>
    (int.tryParse(props['index'] ?? '') ?? 0).clamp(0, kSwitcherPreviewViews.length - 1);

/// 속성의 `direction` — 없거나 모르는 값은 위젯의 기본값.
CoreSwitcherDirection switcherPreviewDirection(Map<String, String> props) =>
    previewEnum(CoreSwitcherDirection.values, props['direction'], CoreSwitcherDirection.defaultDirection);

/// 속성의 `gestureEnabled` — 없으면 위젯의 기본값(`true`).
bool switcherPreviewGestureEnabled(Map<String, String> props) => previewFlag(props, 'gestureEnabled', fallback: true);

/// logical px → Web 이 쓰는 rem 문자열.
String switcherRem(double pixels) => '${docsSizeNumber(pixels / 16)}rem';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// variant 와 크기 축이 없어서 보일 화면(`index`), 움직이는 방향, 끌기만
/// 바꾼다. `index` 를 바꾸면 미리보기가 전환을 재생한다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'index': '0', 'direction': 'left'},
  controls: [
    DocsPlaygroundChoice(label: 'index', prop: 'index', options: ['0', '1', '2'], segmented: true),
    DocsPlaygroundChoice(
      label: 'direction',
      prop: 'direction',
      options: ['left', 'right', 'up', 'down'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '끌기 끄기', on: {'gestureEnabled': 'false'}),
  ],
  code: _switcherCode,
  webCode: _switcherWebCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null` — `CoreSwitcherStyle` 에는
/// `defaultsBySize` 가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 두 플랫폼이 같은 `Switcher` 인자 — `items` 앞까지.
///
/// 끌기를 켠 코드의 `index` 는 상태 변수다. 숫자를 그대로 적으면 끌어서 넘긴
/// 번호가 `index` 에 반영되지 않는다.
List<String> _switcherArguments(Map<String, String> props) {
  final direction = switcherPreviewDirection(props);
  final draggable = switcherPreviewGestureEnabled(props);
  return [
    if (draggable) 'index: index,' else 'index: ${switcherPreviewIndex(props)},',
    if (direction != CoreSwitcherDirection.defaultDirection) 'direction: CoreSwitcherDirection.${direction.name},',
    if (draggable) 'onIndexChanged: (next) => setState(() => index = next),' else 'gestureEnabled: false,',
  ];
}

/// 코드 위의 주석 — 끌기를 켠 코드가 쓰는 상태 변수와 컨트롤에서 고른 시작 번호.
String _switcherStateComment(Map<String, String> props) =>
    switcherPreviewGestureEnabled(props) ? '// 상태: int index = ${switcherPreviewIndex(props)};\n' : '';

String _switcherCode(Map<String, String> props, String? label) {
  final lines = [
    ..._switcherArguments(props),
    'items: const [',
    for (final (name, _) in kSwitcherPreviewViews) "  Center(child: Text('$name')),",
    '],',
  ];
  return '${_switcherStateComment(props)}SizedBox(\n'
      '  width: ${docsSizeNumber(kSwitcherPreviewWidth)},\n'
      '  height: ${docsSizeNumber(kSwitcherPreviewHeight)},\n'
      '  child: Switcher(\n'
      '${lines.map((l) => '    $l').join('\n')}\n'
      '  ),\n'
      ')';
}

String _switcherWebCode(Map<String, String> props, String? label) {
  final lines = [
    ..._switcherArguments(props),
    'items: [',
    for (final (name, _) in kSwitcherPreviewViews)
      "  div(classes: 'flex h-full items-center justify-center', [Text('$name')]),",
    '],',
  ];
  final size = "{'width': '${switcherRem(kSwitcherPreviewWidth)}', 'height': '${switcherRem(kSwitcherPreviewHeight)}'}";
  return '${_switcherStateComment(props)}div(styles: Styles(raw: $size), [\n'
      '  Switcher(\n'
      '${lines.map((l) => '    $l').join('\n')}\n'
      '  ),\n'
      '])';
}
