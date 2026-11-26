/// RefreshTrigger 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `refresh_trigger_web.dart` · `refresh_trigger_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 목록 · 버튼 글자 · 바꾼 라벨 · 스타일 · 상자 크기는 아래 상수 한
/// 곳에 둔다 — 두 플랫폼의 미리보기와 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/refresh-trigger.md`.
const String slug = 'refresh-trigger';

/// 감싼 목록의 항목. 플레이그라운드의 상자보다 길어야 목록이 스크롤된다.
const List<String> demoRows = ['받은편지함', '임시 보관함', '보낸편지함', '보관함', '스팸함', '휴지통'];

/// `refresh()` 를 부르는 버튼의 글자.
const String demoRefreshButton = '새로고침';

/// 새로 고침에 실패했을 때 목록 위에 두는 알림의 제목.
const String demoFailureTitle = '목록을 새로 못 불러왔어요';

/// 실패 알림의 설명 — 사용자가 다음에 할 일.
const String demoFailureHint = '새로고침을 다시 시도해 주세요';

/// 당기는 중 그림의 라벨 — 한국어 기본 문구(`refreshTriggerPull`)와 같다.
const String demoPullLabel = '당겨서 새로고침';

/// 놓기 직전 그림의 라벨 — 한국어 기본 문구(`refreshTriggerRelease`)와 같다.
const String demoReleaseLabel = '놓으면 새로고침';

/// 당기는 중 그림의 표시 상자 — `RefreshTrigger` 의 기본값을 그대로 읽는다.
const CoreOutlinedContainerStyle demoPullingBoxStyle = CoreOutlinedContainerStyle(
  backgroundColor: CoreRefreshTriggerStyle.defaultIndicatorBackgroundColor,
  borderRadius: CoreRefreshTriggerStyle.defaultIndicatorBorderRadius,
  borderWidth: 0,
  padding: CoreRefreshTriggerStyle.defaultPullingPadding,
);

/// 미리보기의 `onRefresh` 가 기다리는 시간.
const Duration demoRefreshWait = Duration(milliseconds: CoreDuration.ms2000);

/// 플레이그라운드 상자의 폭(logical px). 코드 상자에는 나오지 않는다.
const double demoBoxWidth = CoreLayout.layout320;

/// 플레이그라운드 상자의 높이(logical px) — 코드의 `CoreSpace.space256` · `16rem`.
const double demoBoxHeight = CoreSpace.space256;

/// 구조 그림의 상자 높이(logical px).
const double demoAnatomyHeight = CoreSpace.space200;

/// 구조 그림의 상자 폭(logical px). 왼쪽에 놓인 목록 글자가 표시 상자의 번호에
/// 닿지 않을 만큼 넓게 둔다.
const double demoAnatomyWidth = CoreLayout.layout400;

/// 카드 안에 놓는 상자의 폭(logical px). 좁으면 칸 폭으로 줄어든다. 목록 글자가
/// 가운데의 표시 상자에 가리지 않을 만큼 둔다.
const double demoCardWidth = CoreLayout.layout320;

/// 카드 안에 놓는 작은 상자의 높이(logical px).
const double demoCardHeight = CoreSpace.space128;

/// "라벨 바꾸기" 를 켰을 때의 네 라벨. 키는 생성자 파라미터 이름이다.
const Map<String, String> demoCustomTexts = {
  'pullText': '당겨서 새 메일 확인',
  'releaseText': '놓으면 새 메일 확인',
  'refreshingText': '메일 가져오는 중',
  'completedText': '메일을 가져왔어요',
};

/// 스타일 장면의 덮어쓰기 — 문서의 코드 블록과 같은 값이다.
const CoreRefreshTriggerStyle demoCustomStyle = CoreRefreshTriggerStyle(
  indicatorBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  indicatorBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  indicatorPadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16, vertical: CoreSpace.space8),
);

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `stage` 의 선택지에 `pulling` 은 없다 — 직접 지정한 `pulling` 은 당긴 거리가
/// 0 이라 표시가 영역 밖에 남는다. `button` 은 위젯의 속성이 아니라 미리보기의
/// 손잡이다 — 켜면 상자 위에 `refresh()` 를 부르는 버튼을 둔다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'stage': 'idle', 'button': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'stage', prop: 'stage', options: ['idle', 'refreshing', 'completed'], segmented: true),
    DocsPlaygroundFlag(label: '라벨 바꾸기', on: demoCustomTexts),
    DocsPlaygroundFlag(label: 'refresh() 버튼', on: {'button': 'true'}),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// 크기 표. RefreshTrigger 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `stage` — 없거나 모르는 값은 위젯의 기본값.
CoreRefreshStage demoStageOf(Map<String, String> props) =>
    previewEnum(CoreRefreshStage.values, props['stage'], CoreRefreshStage.defaultStage);

/// 속성 `button` — `refresh()` 버튼을 둘 것인가.
bool demoShowsButton(Map<String, String> props) => previewFlag(props, 'button');

String _quoted(String value) => "'${value.replaceAll("'", r"\'")}'";

/// 코드 안의 목록 항목 — 미리보기와 같은 글자.
String get _rowsLiteral => '[${demoRows.map(_quoted).join(', ')}]';

/// `RefreshTrigger(` 의 첫 인자들 — 두 플랫폼이 같다.
List<String> _argumentLines(Map<String, String> props) {
  final stage = demoStageOf(props);
  return [
    if (demoShowsButton(props)) 'key: refreshKey,',
    if (stage != CoreRefreshStage.defaultStage) 'stage: CoreRefreshStage.${stage.name},',
    for (final name in demoCustomTexts.keys)
      if (props[name] case final text?) '$name: ${_quoted(text)},',
    'onRefresh: reload,',
  ];
}

/// 상자 위에 두는 버튼과 간격 — 두 플랫폼이 같다.
List<String> get _buttonLines => [
  'Button(',
  '  variant: CoreButtonVariant.outline,',
  '  size: CoreComponentSize.sm,',
  '  onPressed: () => refreshKey.currentState?.refresh(),',
  '  child: Text(${_quoted(demoRefreshButton)}),',
  '),',
  'const Gap.space12(),',
];

/// 버튼과 상자 [box] 를 부모 [open] · [close] 안에 넣는다.
String _withButton(
  List<String> box, {
  required String keyType,
  required List<String> open,
  required List<String> close,
}) {
  return [
    '// State 에 둡니다: final refreshKey = $keyType<RefreshTriggerState>();',
    ...open,
    for (final line in [..._buttonLines, ...box.sublist(0, box.length - 1), '${box.last},']) '    $line',
    ...close,
  ].join('\n');
}

String _flutterCode(Map<String, String> props, String? label) {
  final box = [
    'OutlinedContainer(',
    '  child: SizedBox(',
    '    height: CoreSpace.space256,',
    '    child: RefreshTrigger(',
    for (final line in _argumentLines(props)) '      $line',
    '      child: ListView(',
    '        children: [',
    '          for (final row in $_rowsLiteral)',
    '            Padding(',
    '              padding: const EdgeInsets.symmetric(horizontal: CoreSpace.space16, vertical: CoreSpace.space12),',
    '              child: Text(row),',
    '            ),',
    '        ],',
    '      ),',
    '    ),',
    '  ),',
    ')',
  ];
  if (!demoShowsButton(props)) return box.join('\n');
  return _withButton(
    box,
    keyType: 'GlobalKey',
    open: const ['Column(', '  mainAxisSize: MainAxisSize.min,', '  children: ['],
    close: const ['  ],', ')'],
  );
}

String _webCode(Map<String, String> props, String? label) {
  final box = [
    'OutlinedContainer(',
    "  classes: 'w-full',",
    '  child: RefreshTrigger(',
    "    css: const Styles(raw: {'height': '16rem'}),",
    for (final line in _argumentLines(props)) '    $line',
    '    child: div([',
    '      for (final row in $_rowsLiteral)',
    r"        div([Text(row)], classes: 'px-${CoreSpace.scale.space16} py-${CoreSpace.scale.space12}'),",
    '    ]),',
    '  ),',
    ')',
  ];
  if (!demoShowsButton(props)) return box.join('\n');
  return _withButton(
    box,
    keyType: 'GlobalStateKey',
    open: const ['div(', '  ['],
    close: const ['  ],', "  classes: 'flex w-full flex-col items-center',", ')'],
  );
}
