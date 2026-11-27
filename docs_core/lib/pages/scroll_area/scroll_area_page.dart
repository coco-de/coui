/// ScrollArea 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `scroll_area_web.dart` · `scroll_area_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 플레이그라운드의 속성은 셋이다 — `direction`(`CoreScrollAreaDirection` 의
/// 이름), `maxHeight`, `showScrollbar`. 모든 상자는 폭을 정하고, 세로 목록은
/// `maxHeight` 로 높이를 막아 실제로 스크롤되게 한다. 가로 줄은 내용 높이를
/// 따르므로 `maxHeight` 를 넣지 않는다.
///
/// 스크롤되는 내용의 코드가 두 플랫폼에서 달라(`Column` · `Row` 와 flex
/// `div`) `webCode` 를 따로 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/scroll-area.md`.
const String slug = 'scroll-area';

/// 세로 목록의 줄 수.
const int demoRowCount = 20;

/// 가로 줄의 항목 수.
const int demoColumnCount = 12;

/// 플레이그라운드 스크롤 상자의 폭(logical px).
const double demoViewportWidth = 240;

/// 플레이그라운드의 처음 `maxHeight`. Flutter 무대에 들어가는 가장 큰 값이다.
const double demoDefaultMaxHeight = CoreSpace.space160;

/// 플레이그라운드에서 고를 수 있는 `maxHeight`.
const List<double> demoMaxHeights = [CoreSpace.space96, CoreSpace.space128, demoDefaultMaxHeight];

/// 세로 목록의 [index] 번째 글자.
String demoRowLabel(int index) => '스크롤 항목 $index';

/// 가로 줄의 [index] 번째 글자.
String demoColumnLabel(int index) => '항목 $index';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'direction': 'vertical', 'maxHeight': '160'},
  controls: [
    DocsPlaygroundChoice(label: 'direction', prop: 'direction', options: ['vertical', 'horizontal'], segmented: true),
    DocsPlaygroundChoice(label: 'maxHeight', prop: 'maxHeight', options: ['96', '128', '160'], segmented: true),
    DocsPlaygroundFlag(label: 'showScrollbar 끄기', on: {'showScrollbar': 'false'}),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// 크기 표. ScrollArea 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `direction` — 없거나 모르는 값은 위젯의 기본값.
CoreScrollAreaDirection demoDirectionOf(Map<String, String> props) =>
    previewEnum(CoreScrollAreaDirection.values, props['direction'], CoreScrollAreaDirection.defaultDirection);

/// 속성의 `maxHeight` — 고를 수 있는 값이 아니면 [demoDefaultMaxHeight].
double demoMaxHeightOf(Map<String, String> props) {
  final px = double.tryParse(props['maxHeight'] ?? '');
  return px != null && demoMaxHeights.contains(px) ? px : demoDefaultMaxHeight;
}

/// 속성의 `showScrollbar` — 없으면 위젯의 기본값(`true`).
bool demoShowsScrollbar(Map<String, String> props) => previewFlag(props, 'showScrollbar', fallback: true);

// ─── 장면 ───────────────────────────────────────────────────

/// 나란히 놓는 장면 한 칸의 폭.
const double sceneCellWidth = 200;

/// `scroll-area/directions` · `scroll-area/sizes` 의 `maxHeight`.
const double sceneMaxHeight = CoreSpace.space128;

/// `scroll-area/sizes` 의 짧은 목록 줄 수 — [sceneMaxHeight] 보다 낮다.
const int sceneShortRowCount = 2;

/// `scroll-area/directions` 의 세로 칸 글자.
const String sceneVerticalCaption = 'vertical — maxHeight 128';

/// `scroll-area/directions` 의 가로 칸 글자.
const String sceneHorizontalCaption = 'horizontal — 높이는 내용을 따름';

/// `scroll-area/sizes` 의 긴 목록 칸 글자.
const String sceneLongCaption = '긴 내용 — 128에서 멈추고 스크롤';

/// `scroll-area/sizes` 의 짧은 목록 칸 글자.
const String sceneShortCaption = '짧은 내용 — 내용 높이만큼';

/// `scroll-area/inside` 상자의 폭.
const double sceneNestedWidth = 240;

/// `scroll-area/inside` 의 바깥 `maxHeight`.
const double sceneNestedMaxHeight = CoreSpace.space160;

/// `scroll-area/inside` 의 세로 목록 줄 수. 첫 줄 아래에 가로 줄이 놓인다.
const int sceneNestedRowCount = 10;

// ─── 플레이그라운드 코드 ─────────────────────────────────────

/// 기본값과 다른 파라미터 줄 — 두 플랫폼이 같은 이름을 쓴다.
List<String> _areaLines(Map<String, String> props) {
  final direction = demoDirectionOf(props);
  return [
    if (direction != CoreScrollAreaDirection.defaultDirection) 'direction: CoreScrollAreaDirection.${direction.name},',
    if (!demoShowsScrollbar(props)) 'showScrollbar: false,',
    if (direction == CoreScrollAreaDirection.vertical)
      'scrollAreaStyle: const CoreScrollAreaStyle(maxHeight: ${demoMaxHeightOf(props).toInt()}),',
  ];
}

const List<String> _flutterColumnLines = [
  'child: Column(',
  '  crossAxisAlignment: CrossAxisAlignment.start,',
  '  spacing: CoreSpace.space8,',
  '  children: [',
  '    for (var i = 1; i <= $demoRowCount; i += 1)',
  r"      Text('스크롤 항목 $i').bodyMedium,",
  '  ],',
  '),',
];

const List<String> _flutterRowLines = [
  'child: Padding(',
  '  padding: const EdgeInsets.only(bottom: CoreSpace.space12),',
  '  child: Row(',
  '    mainAxisSize: MainAxisSize.min,',
  '    spacing: CoreSpace.space16,',
  '    children: [',
  '      for (var i = 1; i <= $demoColumnCount; i += 1)',
  r"        Text('항목 $i').bodyMedium,",
  '    ],',
  '  ),',
  '),',
];

String _flutterCode(Map<String, String> props, String? label) {
  final horizontal = demoDirectionOf(props) == CoreScrollAreaDirection.horizontal;
  return [
    'SizedBox(',
    '  width: ${demoViewportWidth.toInt()},',
    '  child: ScrollArea(',
    for (final line in _areaLines(props)) '    $line',
    for (final line in horizontal ? _flutterRowLines : _flutterColumnLines) '    $line',
    '  ),',
    ')',
  ].join('\n');
}

const List<String> _webColumnLines = [
  'child: div(',
  r"  classes: 'flex flex-col gap-${CoreSpace.scale.space8}',",
  '  [',
  '    for (var i = 1; i <= $demoRowCount; i += 1)',
  r"      Text('스크롤 항목 $i').bodyMedium,",
  '  ],',
  '),',
];

const List<String> _webRowLines = [
  'child: div(',
  "  classes: 'flex flex-row whitespace-nowrap '",
  r"      'gap-${CoreSpace.scale.space16} pb-${CoreSpace.scale.space12}',",
  '  [',
  '    for (var i = 1; i <= $demoColumnCount; i += 1)',
  r"      Text('항목 $i').bodyMedium,",
  '  ],',
  '),',
];

String _webCode(Map<String, String> props, String? label) {
  final horizontal = demoDirectionOf(props) == CoreScrollAreaDirection.horizontal;
  return [
    'div(',
    '  styles: Styles(',
    "    raw: {'width': '${demoViewportWidth.toInt()}px', 'max-width': '100%'},",
    '  ),',
    '  [',
    '    ScrollArea(',
    for (final line in _areaLines(props)) '      $line',
    for (final line in horizontal ? _webRowLines : _webColumnLines) '      $line',
    '    ),',
    '  ],',
    ')',
  ].join('\n');
}
