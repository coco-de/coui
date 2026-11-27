/// Window 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `window_web.dart` · `window_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 모든 창 매니저는 폭과 높이를 정한 상자 안에 둔다. `WindowNavigator` 는
/// 부모의 크기를 채우고, 창의 위치는 그 왼쪽 위에서 잰 값이라 상자보다 큰
/// 부분은 잘린다. 낮은 상자에는 위쪽 스냅 바가 들어가지 않아
/// `showTopSnapBar: false` 로 끈다.
///
/// 창 본문의 코드가 두 플랫폼에서 달라(Flutter 는 `Align` 으로 왼쪽 위에
/// 붙인다) `webCode` 를 따로 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/window.md`.
const String slug = 'window';

/// 플레이그라운드 창 매니저의 폭(logical px).
const double playgroundWidth = CoreSpace.space256 + CoreSpace.space32;

/// 플레이그라운드 창 매니저의 높이.
const double playgroundHeight = CoreSpace.space240;

/// 장면 창 매니저의 폭.
const double sceneWidth = CoreSpace.space256;

/// 플레이그라운드 창을 줄일 수 있는 가장 작은 크기. 기본값(200×200)은 이
/// 상자의 창보다 커서 그대로 두면 처음 크기를 조절할 때 창이 커진다.
const CoreWindowConstraints playgroundConstraints = CoreWindowConstraints(
  minWidth: CoreSpace.space128,
  minHeight: CoreSpace.space88,
);

/// 플레이그라운드의 앞 창 — 목록의 첫 번째.
const CoreWindowRect playgroundFrontBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space72,
  CoreSpace.space88,
  CoreSpace.space176,
  CoreSpace.space136,
);

/// 플레이그라운드의 뒤 창.
const CoreWindowRect playgroundBackBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space16,
  CoreSpace.space16,
  CoreSpace.space176,
  CoreSpace.space136,
);

/// 앞 창의 제목.
const String playgroundFrontTitle = '메모';

/// 앞 창의 본문.
const String playgroundFrontBody = '회의 메모';

/// 뒤 창의 제목.
const String playgroundBackTitle = '파일';

/// 뒤 창의 본문.
const String playgroundBackBody = '보고서 목록';

/// 플레이그라운드의 창을 처음 자리에 다시 놓는 버튼.
const String resetLabel = '창 다시 놓기';

/// 구조 장면의 높이.
const double anatomyHeight = CoreSpace.space168;

/// 구조 장면의 창.
const CoreWindowRect anatomyBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space8,
  CoreSpace.space8,
  CoreSpace.space240,
  CoreSpace.space152,
);

/// 구조 장면의 제목.
const String anatomyTitle = '편집기';

/// 구조 장면의 본문.
const String anatomyBody = '본문 영역';

/// `actions` 슬롯에 넣는 버튼.
const String saveLabel = '저장';

/// 상태 장면의 높이.
const double statesHeight = CoreSpace.space216;

/// 상태 장면의 앞 창.
const CoreWindowRect statesFrontBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space56,
  CoreSpace.space80,
  CoreSpace.space184,
  CoreSpace.space88,
);

/// 상태 장면의 뒤 창.
const CoreWindowRect statesBackBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space8,
  CoreSpace.space8,
  CoreSpace.space184,
  CoreSpace.space96,
);

/// 상태 장면의 최소화한 창. 타이틀 바 높이만 남는다.
const CoreWindowRect statesMinimizedBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space8,
  CoreSpace.space176,
  CoreSpace.space184,
  CoreSpace.space96,
);

/// 상태 장면의 앞 창 제목.
const String statesFrontTitle = '앞 창';

/// 상태 장면의 앞 창 본문.
const String statesFrontBody = '제목이 진합니다';

/// 상태 장면의 뒤 창 제목.
const String statesBackTitle = '뒤 창';

/// 상태 장면의 뒤 창 본문.
const String statesBackBody = '제목이 흐립니다';

/// 상태 장면의 최소화한 창 제목.
const String statesMinimizedTitle = '최소화한 창';

/// 상태 장면의 최소화한 창 본문. 최소화한 동안에는 보이지 않는다.
const String statesMinimizedBody = '접힌 본문';

/// 창 순서 장면의 높이.
const double layersHeight = CoreSpace.space168;

/// 목록의 첫 창.
const CoreWindowRect layersFirstBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space8,
  CoreSpace.space8,
  CoreSpace.space176,
  CoreSpace.space104,
);

/// 항상 위 창.
const CoreWindowRect layersPinnedBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space72,
  CoreSpace.space80,
  CoreSpace.space176,
  CoreSpace.space80,
);

/// 목록의 첫 창 제목.
const String layersFirstTitle = '첫 번째 창';

/// 목록의 첫 창 본문.
const String layersFirstBody = '목록의 첫 항목';

/// 항상 위 창 제목.
const String layersPinnedTitle = '항상 위';

/// 항상 위 창 본문.
const String layersPinnedBody = 'alwaysOnTop';

/// 타이틀 바 동작을 비교하는 장면의 높이.
const double actionsHeight = CoreSpace.space128;

/// 타이틀 바 동작을 비교하는 장면의 창.
const CoreWindowRect actionsBounds = CoreWindowRect.fromLTWH(
  CoreSpace.space8,
  CoreSpace.space8,
  CoreSpace.space240,
  CoreSpace.space104,
);

/// 타이틀 바 동작을 비교하는 장면의 제목.
const String actionsTitle = '문서';

/// 동작을 하나 더한 창의 본문.
const String extraActionBody = '저장 버튼을 더했습니다';

/// 같은 버튼이 겹친 창의 본문.
const String windowActionsBody = '같은 버튼이 두 번 보입니다';

/// 버튼으로 옮기는 장면의 높이.
const double moveHeight = CoreSpace.space144;

/// 버튼으로 옮기는 장면의 처음 창 — 왼쪽 자리.
const CoreWindowRect moveBounds = CoreWindowRect.fromLTWH(
  moveLeft,
  CoreSpace.space8,
  CoreSpace.space168,
  CoreSpace.space128,
);

/// 왼쪽 자리의 `left`.
const double moveLeft = CoreSpace.space8;

/// 오른쪽 자리의 `left`.
const double moveRight = CoreSpace.space80;

/// 버튼으로 옮기는 장면의 제목.
const String moveTitle = '도구';

/// 버튼으로 옮기는 장면의 본문.
const String moveBody = '버튼으로 옮깁니다';

/// 왼쪽으로 옮기는 버튼.
const String moveLeftLabel = '왼쪽에 놓기';

/// 오른쪽으로 옮기는 버튼.
const String moveRightLabel = '오른쪽에 놓기';

/// 플레이그라운드가 켜고 끄는 `Window` 파라미터. 모두 기본값이 `true` 다.
const List<String> playgroundFlagNames = ['draggable', 'resizable', 'maximizable', 'minimizable', 'closable'];

/// [name] 파라미터의 지금 값.
bool demoFlag(Map<String, String> props, String name) => previewFlag(props, name, fallback: true);

/// 속성 조합 하나를 가리키는 글자. `WindowNavigator` 는 `initialWindows` 를
/// 처음 만들 때만 읽으므로, 미리보기는 이 글자를 key 로 써서 새로 만든다.
String demoSignature(Map<String, String> props) =>
    [for (final name in playgroundFlagNames) demoFlag(props, name)].join('-');

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {},
  controls: [
    DocsPlaygroundFlag(label: '이동 끄기', on: {'draggable': 'false'}),
    DocsPlaygroundFlag(label: '크기 조절 끄기', on: {'resizable': 'false'}),
    DocsPlaygroundFlag(label: '최대화 버튼 끄기', on: {'maximizable': 'false'}),
    DocsPlaygroundFlag(label: '최소화 버튼 끄기', on: {'minimizable': 'false'}),
    DocsPlaygroundFlag(label: '닫기 버튼 끄기', on: {'closable': 'false'}),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// 크기 표. Window 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 코드에 적는 수 — 정수는 소수점 없이.
String _number(double value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value';

/// 코드 한 창. [content] 는 `content:` 줄부터의 코드다.
String _windowCode(
  Map<String, String> props, {
  required CoreWindowRect bounds,
  required String title,
  required List<String> content,
}) {
  final lines = [
    'Window(',
    '  bounds: const CoreWindowRect.fromLTWH(${_number(bounds.left)}, ${_number(bounds.top)}, '
        '${_number(bounds.width)}, ${_number(bounds.height)}),',
    '  constraints: const CoreWindowConstraints('
        'minWidth: ${_number(playgroundConstraints.minWidth)}, '
        'minHeight: ${_number(playgroundConstraints.minHeight)}),',
    "  title: const Text('$title'),",
    for (final line in content) '  $line',
    for (final name in playgroundFlagNames)
      if (!demoFlag(props, name)) '  $name: false,',
    '),',
  ];
  return lines.join('\n');
}

/// [block] 의 모든 줄을 [spaces] 칸 들여 쓴다.
String _indent(String block, int spaces) => [for (final line in block.split('\n')) '${' ' * spaces}$line'].join('\n');

String _flutterWindow(Map<String, String> props, CoreWindowRect bounds, String title, String body) => _windowCode(
  props,
  bounds: bounds,
  title: title,
  content: [
    'content: const Align(',
    '  alignment: Alignment.topLeft,',
    "  child: Text('$body'),",
    '),',
  ],
);

String _webWindow(Map<String, String> props, CoreWindowRect bounds, String title, String body) => _windowCode(
  props,
  bounds: bounds,
  title: title,
  content: ["content: const Text('$body'),"],
);

String _flutterCode(Map<String, String> props, String? label) {
  final front = _flutterWindow(props, playgroundFrontBounds, playgroundFrontTitle, playgroundFrontBody);
  final back = _flutterWindow(props, playgroundBackBounds, playgroundBackTitle, playgroundBackBody);
  return [
    'SizedBox(',
    '  width: ${_number(playgroundWidth)},',
    '  height: ${_number(playgroundHeight)},',
    '  child: OutlinedContainer(',
    '    child: WindowNavigator(',
    '      showTopSnapBar: false,',
    '      initialWindows: [',
    '        // 목록의 첫 창이 맨 앞에 놓입니다.',
    _indent(front, 8),
    _indent(back, 8),
    '      ],',
    '    ),',
    '  ),',
    ')',
  ].join('\n');
}

String _webCode(Map<String, String> props, String? label) {
  final front = _webWindow(props, playgroundFrontBounds, playgroundFrontTitle, playgroundFrontBody);
  final back = _webWindow(props, playgroundBackBounds, playgroundBackTitle, playgroundBackBody);
  // 16px = 1rem.
  final width = _number(playgroundWidth / 16);
  final height = _number(playgroundHeight / 16);
  return [
    'div(',
    "  styles: Styles(raw: {'width': '${width}rem', 'height': '${height}rem'}),",
    '  [',
    '    OutlinedContainer(',
    "      css: Styles(raw: {'height': '100%'}),",
    '      child: WindowNavigator(',
    '        showTopSnapBar: false,',
    '        initialWindows: [',
    '          // 목록의 첫 창이 맨 앞에 놓입니다.',
    _indent(front, 10),
    _indent(back, 10),
    '        ],',
    '      ),',
    '    ),',
    '  ],',
    ')',
  ].join('\n');
}
