/// Scrollbar 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `scrollbar_web.dart` · `scrollbar_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 플레이그라운드의 속성은 셋이다 — `visibility`(`CoreScrollbarVisibility` 의
/// 이름), `axis`(`vertical` · `horizontal`), `interactive`. 처음 값의
/// `visibility` 는 `always` 다. 기본값 `auto` 는 가만히 있으면 thumb 을 그리지
/// 않아 첫 화면에서 컴포넌트가 보이지 않는다.
///
/// 정지 장면은 줄 높이가 같은 목록 하나를 같은 자리까지 스크롤해 둔다. 장면
/// 한 칸의 모양은 `CoreScrollbarStyle` 하나로 적는다 — Flutter 는 그 값을 실제
/// `Scrollbar` 에 넘기고, Web 은 같은 값과 같은 위치 계산으로 그림을 그린다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/scrollbar.md`.
const String slug = 'scrollbar';

/// 세로 목록의 줄 수.
const int demoRowCount = 20;

/// 가로 줄의 항목 수.
const int demoColumnCount = 12;

/// 플레이그라운드 스크롤 상자의 폭(logical px).
const double demoViewportWidth = 200;

/// 플레이그라운드 세로 스크롤 상자의 높이. 가로는 내용 높이를 따른다.
const double demoViewportHeight = 160;

/// 세로 목록의 [index] 번째 글자.
String demoRowLabel(int index) => '스크롤 항목 $index';

/// 가로 줄의 [index] 번째 글자.
String demoColumnLabel(int index) => '항목 $index';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'visibility': 'always', 'axis': 'vertical'},
  controls: [
    DocsPlaygroundChoice(label: 'visibility', prop: 'visibility', options: ['auto', 'always', 'thin', 'hidden']),
    DocsPlaygroundChoice(label: 'axis', prop: 'axis', options: ['vertical', 'horizontal'], segmented: true),
    DocsPlaygroundFlag(label: 'interactive 끄기', on: {'interactive': 'false'}),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// 크기 표. Scrollbar 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `visibility` — 없거나 모르는 값은 위젯의 기본값(`auto`).
CoreScrollbarVisibility demoVisibilityOf(Map<String, String> props) =>
    previewEnum(CoreScrollbarVisibility.values, props['visibility'], CoreScrollbarVisibility.defaultVisibility);

/// 속성의 `axis` — `horizontal` 이 아니면 세로. 미리보기 내용은 한 방향만 넘친다.
CoreScrollbarAxis demoAxisOf(Map<String, String> props) =>
    props['axis'] == CoreScrollbarAxis.horizontal.name ? CoreScrollbarAxis.horizontal : CoreScrollbarAxis.vertical;

/// 속성의 `interactive` — 없으면 위젯의 기본값(`true`).
bool demoIsInteractive(Map<String, String> props) => previewFlag(props, 'interactive', fallback: true);

// ─── 정지 장면 ───────────────────────────────────────────────

/// 장면 목록의 줄 수.
const int sceneRowCount = 20;

/// 장면 목록의 한 줄 높이 — 내용 길이를 알아야 그림의 thumb 자리를 계산한다.
const double sceneRowHeight = 28;

/// 장면 스크롤 상자의 높이.
const double sceneViewportHeight = 160;

/// 장면 목록을 미리 스크롤해 둔 거리 — thumb 이 위 끝에서 떨어져 보인다.
const double sceneScrollOffset = 120;

/// `scrollbar/anatomy` 상자의 폭.
const double sceneAnatomyWidth = 220;

/// `scrollbar/states` 한 칸의 폭.
const double sceneStateWidth = 180;

/// `scrollbar/visibility` 한 칸의 폭.
const double sceneVisibilityWidth = 150;

/// 장면 한 칸 — 아래 글자, thumb 을 그리지 않는지, 그 칸의 모양.
typedef ScrollbarSceneCell = ({String caption, bool hidden, CoreScrollbarStyle style});

/// `scrollbar/anatomy` 의 칸 — 쉬는 상태의 기본 모양.
const ScrollbarSceneCell sceneAnatomyCell = (caption: '', hidden: false, style: CoreScrollbarStyle());

/// `scrollbar/states` 의 칸들.
const List<ScrollbarSceneCell> sceneStateCells = [
  (caption: '쉬는 상태 — 두께 6', hidden: false, style: CoreScrollbarStyle()),
  (caption: '올리거나 끄는 동안 — 두께 8', hidden: false, style: _heldStyle),
];

/// `scrollbar/visibility` 의 칸들.
const List<ScrollbarSceneCell> sceneVisibilityCells = [
  (caption: 'always — 두께 6', hidden: false, style: CoreScrollbarStyle()),
  (caption: 'thin — 나타났을 때 두께 3', hidden: false, style: _thinStyle),
  (caption: 'hidden — 그리지 않음', hidden: true, style: CoreScrollbarStyle()),
];

/// 올리거나 끄는 동안의 모양 — 색과 두께는 hover 기본값이고, 여백은 같은 바
/// 폭에서 두께를 빼고 남은 것의 절반이다.
const CoreScrollbarStyle _heldStyle = CoreScrollbarStyle(
  thumbColor: CoreScrollbarStyle.defaultHoverThumbColor,
  hoverThumbColor: CoreScrollbarStyle.defaultHoverThumbColor,
  thickness: CoreScrollbarStyle.defaultHoverThickness,
  thumbInset: _heldInset,
);

const double _heldInset =
    (CoreScrollbarStyle.defaultThickness +
        2 * CoreScrollbarStyle.defaultThumbInset -
        CoreScrollbarStyle.defaultHoverThickness) /
    2;

/// `thin` 이 그리는 두께 — 쉬는 두께와 올리거나 끌 때의 두께를 모두 절반으로.
const double _thinThickness = CoreScrollbarStyle.defaultThickness * CoreScrollbarStyle.thinThicknessFactor;
const double _thinHoverThickness = CoreScrollbarStyle.defaultHoverThickness * CoreScrollbarStyle.thinThicknessFactor;

const CoreScrollbarStyle _thinStyle = CoreScrollbarStyle(
  thickness: _thinThickness,
  hoverThickness: _thinHoverThickness,
);

/// 장면 thumb 의 길이와 위치 — 실제 바가 쓰는 계산이다. 양 끝 여백은 쉬는
/// 상태의 여백이다.
CoreScrollbarThumbLayout? sceneThumbLayout(CoreScrollbarStyle style) => CoreScrollbarThumbLayout.of(
  viewportExtent: sceneViewportHeight,
  contentExtent: sceneRowCount * sceneRowHeight,
  scrollOffset: sceneScrollOffset,
  margin: CoreScrollbarStyle.defaultThumbInset,
  minLength: style.minThumbLength ?? CoreScrollbarStyle.defaultMinThumbLength,
);

// ─── 플레이그라운드 코드 ─────────────────────────────────────

/// 기본값과 다른 파라미터 줄 — 두 플랫폼이 같은 이름을 쓴다.
List<String> _barLines(Map<String, String> props) {
  final axis = demoAxisOf(props);
  final visibility = demoVisibilityOf(props);
  return [
    if (axis != CoreScrollbarAxis.defaultAxis) 'axis: CoreScrollbarAxis.${axis.name},',
    if (visibility != CoreScrollbarVisibility.defaultVisibility)
      'visibility: CoreScrollbarVisibility.${visibility.name},',
    if (!demoIsInteractive(props)) 'interactive: false,',
  ];
}

const List<String> _flutterColumnLines = [
  'child: Column(',
  '  crossAxisAlignment: CrossAxisAlignment.start,',
  '  spacing: CoreSpace.space8,',
  '  children: [',
  '    for (var i = 1; i <= $demoRowCount; i += 1)',
  "      Text('스크롤 항목 \$i').bodyMedium,",
  '  ],',
  '),',
];

const List<String> _flutterRowLines = [
  'child: Row(',
  '  spacing: CoreSpace.space16,',
  '  children: [',
  '    for (var i = 1; i <= $demoColumnCount; i += 1)',
  "      Text('항목 \$i').bodyMedium,",
  '  ],',
  '),',
];

String _flutterCode(Map<String, String> props, String? label) {
  final horizontal = demoAxisOf(props) == CoreScrollbarAxis.horizontal;
  return [
    '// controller 는 State 에서 만들고 dispose 하는 ScrollController 입니다.',
    'SizedBox(',
    '  width: ${demoViewportWidth.toInt()},',
    if (!horizontal) '  height: ${demoViewportHeight.toInt()},',
    '  child: Scrollbar(',
    '    controller: controller,',
    for (final line in _barLines(props)) '    $line',
    '    child: SingleChildScrollView(',
    if (horizontal) '      scrollDirection: Axis.horizontal,',
    '      controller: controller,',
    if (horizontal) '      padding: const EdgeInsets.only(bottom: CoreSpace.space12),',
    for (final line in horizontal ? _flutterRowLines : _flutterColumnLines) '      $line',
    '    ),',
    '  ),',
    ')',
  ].join('\n');
}

const List<String> _webColumnLines = [
  'child: div(',
  "  classes: 'flex flex-col gap-\${CoreSpace.scale.space8}',",
  '  [',
  '    for (var i = 1; i <= $demoRowCount; i += 1)',
  "      Text('스크롤 항목 \$i').bodyMedium,",
  '  ],',
  '),',
];

const List<String> _webRowLines = [
  'child: div(',
  "  classes: 'flex flex-row whitespace-nowrap '",
  "      'gap-\${CoreSpace.scale.space16} pb-\${CoreSpace.scale.space12}',",
  '  [',
  '    for (var i = 1; i <= $demoColumnCount; i += 1)',
  "      Text('항목 \$i').bodyMedium,",
  '  ],',
  '),',
];

String _webCode(Map<String, String> props, String? label) {
  final horizontal = demoAxisOf(props) == CoreScrollbarAxis.horizontal;
  final box = [
    "'width': '${demoViewportWidth.toInt()}px'",
    "'max-width': '100%'",
    if (!horizontal) "'height': '${demoViewportHeight.toInt()}px'",
  ].join(', ');
  return [
    'div(',
    '  styles: Styles(',
    '    raw: {$box},',
    '  ),',
    '  [',
    '    Scrollbar(',
    for (final line in _barLines(props)) '      $line',
    for (final line in horizontal ? _webRowLines : _webColumnLines) '      $line',
    '    ),',
    '  ],',
    ')',
  ].join('\n');
}
