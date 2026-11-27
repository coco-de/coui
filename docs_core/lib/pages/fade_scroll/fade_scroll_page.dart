/// FadeScroll 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `fade_scroll_web.dart` · `fade_scroll_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 플레이그라운드의 속성은 둘이다 — `direction`(`CoreFadeScrollDirection` 의
/// 이름)과 `offset`(`startOffset` · `endOffset` 에 함께 넣는 길이).
/// `showScrollbar` 는 컨트롤에 두지 않는다. Flutter 의 막대는 가만히 있으면
/// 보이지 않아, 바꿔도 첫 화면이 달라지지 않는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/fade-scroll.md`.
const String slug = 'fade-scroll';

/// 플레이그라운드 상자의 폭(logical px).
const double demoBoxWidth = CoreSpace.space240;

/// 플레이그라운드 세로 상자의 높이. 가로는 내용 높이를 따른다.
const double demoBoxHeight = CoreSpace.space200;

/// 세로 목록의 줄 수.
const int demoRowCount = 12;

/// 가로 줄의 항목 수.
const int demoTagCount = 10;

/// 세로 목록의 [index] 번째 글자.
String demoRowLabel(int index) => '항목 $index';

/// 가로 줄의 [index] 번째 글자.
String demoTagLabel(int index) => '태그 $index';

/// 플레이그라운드에서 고르는 페이드 길이. 가운데가 기본값이다.
///
/// 장면의 길이와 함께, 앞뒤를 더한 값이 상자의 길이를 넘지 않게 고른다 —
/// 넘으면 Web 과 Flutter 가 페이드를 다른 길이로 그린다.
const List<double> demoOffsets = [CoreSpace.space16, CoreFadeScrollStyle.defaultStartOffset, CoreSpace.space96];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: {
    'direction': CoreFadeScrollDirection.defaultDirection.name,
    'offset': '${CoreFadeScrollStyle.defaultStartOffset.toInt()}',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'direction',
      prop: 'direction',
      options: [for (final direction in CoreFadeScrollDirection.values) direction.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: '페이드 길이',
      prop: 'offset',
      options: [for (final offset in demoOffsets) '${offset.toInt()}'],
      segmented: true,
    ),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// 크기 표. FadeScroll 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `direction` — 없거나 모르는 값은 위젯의 기본값.
CoreFadeScrollDirection demoDirectionOf(Map<String, String> props) =>
    previewEnum(CoreFadeScrollDirection.values, props['direction'], CoreFadeScrollDirection.defaultDirection);

/// 속성의 `offset` — 고를 수 있는 길이가 아니면 기본값.
double demoOffsetOf(Map<String, String> props) {
  final offset = double.tryParse(props['offset'] ?? '');
  return offset != null && demoOffsets.contains(offset) ? offset : CoreFadeScrollStyle.defaultStartOffset;
}

/// 속성의 `offset` 이 만드는 스타일. 기본 길이면 `null` 이다.
CoreFadeScrollStyle? demoStyleOf(Map<String, String> props) {
  final offset = demoOffsetOf(props);
  return offset == CoreFadeScrollStyle.defaultStartOffset ? null : offsetStyle(offset);
}

/// 앞뒤 페이드 길이를 [offset] 하나로 맞춘 스타일.
CoreFadeScrollStyle offsetStyle(double offset) => CoreFadeScrollStyle(startOffset: offset, endOffset: offset);

// ─── 장면 ───────────────────────────────────────────────────

/// `fade-scroll/states` 두 상자의 폭과 높이.
const double sceneStateWidth = CoreSpace.space144;
const double sceneStateHeight = CoreSpace.space160;

/// 상자에 다 들어가는 목록의 줄 수.
const int sceneFitRowCount = 3;

/// `fade-scroll/offsets` 에 늘어놓는 페이드 길이.
const List<double> sceneOffsets = [CoreSpace.space0, CoreFadeScrollStyle.defaultStartOffset, CoreSpace.space80];

/// `fade-scroll/offsets` 한 칸의 아래 글자.
String sceneOffsetCaption(double offset) =>
    offset == CoreFadeScrollStyle.defaultStartOffset ? '${offset.toInt()} (기본)' : '${offset.toInt()}';

/// `fade-scroll/offsets` 한 칸의 폭.
const double sceneOffsetWidth = CoreSpace.space104;

/// 사용 가이드 카드 상자의 폭.
const double sceneGuideWidth = CoreSpace.space184;

/// 초점 안내 카드 상자의 높이.
const double sceneFocusHeight = CoreSpace.space160;

/// 페이드 길이 안내 카드 상자의 높이.
const double sceneShortBoxHeight = CoreSpace.space120;

/// 페이드 길이 안내 카드의 두 길이.
const double sceneShortFade = CoreSpace.space24;
const double sceneLongFade = CoreSpace.space56;

/// `fade-scroll/do-focusable` 의 버튼 수.
const int sceneButtonCount = 8;

/// `fade-scroll/do-focusable` 의 [index] 번째 버튼 글자.
String sceneButtonLabel(int index) => '설정 $index';

/// `fade-scroll/dont-text-only` 의 글.
const String sceneParagraph =
    '이 상자에는 읽을 글만 들어 있습니다. 링크도 버튼도 없어 안에 초점을 받는 항목이 없습니다. '
    '화면에 다 보이지 않는 문장은 스크롤해야 읽을 수 있습니다. '
    '키보드만 쓰는 사람에게도 끝 문장까지 갈 방법이 있어야 합니다. '
    '그 방법은 FadeScroll 이 만들어 주지 않습니다.';

/// 관련 컴포넌트 카드의 ScrollArea 폭과 높이.
const double sceneScrollAreaWidth = CoreSpace.space160;
const double sceneScrollAreaHeight = CoreSpace.space120;

/// 관련 컴포넌트 카드의 ChipGroup 폭.
const double sceneChipGroupWidth = CoreSpace.space200;

// ─── 플레이그라운드 코드 ─────────────────────────────────────

/// 기본값과 다른 파라미터 줄 — 두 플랫폼이 같은 이름을 쓴다.
List<String> _parameterLines(Map<String, String> props) {
  final direction = demoDirectionOf(props);
  final offset = demoOffsetOf(props).toInt();
  return [
    if (direction != CoreFadeScrollDirection.defaultDirection) 'direction: CoreFadeScrollDirection.${direction.name},',
    if (demoStyleOf(props) != null) ...[
      'fadeScrollStyle: CoreFadeScrollStyle(',
      '  startOffset: CoreSpace.space$offset,',
      '  endOffset: CoreSpace.space$offset,',
      '),',
    ],
  ];
}

const List<String> _flutterColumnLines = [
  'child: Column(',
  '  crossAxisAlignment: CrossAxisAlignment.start,',
  '  spacing: CoreSpace.space12,',
  '  children: [',
  '    for (var i = 1; i <= $demoRowCount; i += 1)',
  "      Text('항목 \$i').bodyMedium,",
  '  ],',
  '),',
];

const List<String> _flutterRowLines = [
  'child: Row(',
  '  spacing: CoreSpace.space8,',
  '  children: [',
  '    for (var i = 1; i <= $demoTagCount; i += 1)',
  "      Chip(label: '태그 \$i'),",
  '  ],',
  '),',
];

String _flutterCode(Map<String, String> props, String? label) {
  final horizontal = demoDirectionOf(props) == CoreFadeScrollDirection.horizontal;
  return [
    'SizedBox(',
    '  width: ${demoBoxWidth.toInt()},',
    if (!horizontal) '  height: ${demoBoxHeight.toInt()},',
    '  child: FadeScroll(',
    for (final line in _parameterLines(props)) '    $line',
    for (final line in horizontal ? _flutterRowLines : _flutterColumnLines) '    $line',
    '  ),',
    ')',
  ].join('\n');
}

const List<String> _webColumnLines = [
  'child: div(',
  '  styles: Styles(',
  "    raw: {'display': 'flex', 'flex-direction': 'column', 'gap': '12px'},",
  '  ),',
  '  [',
  '    for (var i = 1; i <= $demoRowCount; i += 1)',
  "      Text('항목 \$i').bodyMedium,",
  '  ],',
  '),',
];

const List<String> _webRowLines = [
  'child: div(',
  '  styles: Styles(',
  "    raw: {'display': 'flex', 'gap': '8px', 'width': 'max-content'},",
  '  ),',
  '  [',
  '    for (var i = 1; i <= $demoTagCount; i += 1)',
  "      Chip(label: '태그 \$i'),",
  '  ],',
  '),',
];

String _webCode(Map<String, String> props, String? label) {
  final horizontal = demoDirectionOf(props) == CoreFadeScrollDirection.horizontal;
  final box = [
    "'width': '${demoBoxWidth.toInt()}px'",
    if (!horizontal) "'height': '${demoBoxHeight.toInt()}px'",
  ].join(', ');
  return [
    'div(',
    '  styles: Styles(raw: {$box}),',
    '  [',
    '    FadeScroll(',
    for (final line in _parameterLines(props)) '      $line',
    for (final line in horizontal ? _webRowLines : _webColumnLines) '      $line',
    '    ),',
    '  ],',
    ')',
  ].join('\n');
}
