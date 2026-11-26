/// Drawer 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `drawer_web.dart` · `drawer_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자(제목 · 설명 · 본문 · 버튼 이름)와 그림의 크기는 아래 상수
/// 한 곳에 둔다 — 두 플랫폼의 그림과 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/drawer.md`.
const String slug = 'drawer';

/// 속성 미리보기의 제목 — 태그가 `label` 을 주지 않을 때.
const String demoTitle = '필터';

/// 속성 미리보기의 설명.
const String demoDescription = '보여 줄 상품의 조건을 고릅니다.';

/// 속성 미리보기의 본문.
const String demoContent = '고른 조건에 맞는 상품만 목록에 남습니다.';

/// 속성 미리보기 하단 영역의 보조 버튼.
const String demoCancel = '취소';

/// 속성 미리보기 하단 영역의 주요 버튼.
const String demoApply = '적용';

/// 실제 서랍을 여는 버튼의 글자.
const String demoOpener = '열어 보기';

/// 하단 시트 장면의 통화 목록.
const List<String> demoCurrencies = ['대한민국 원 (KRW)', '미국 달러 (USD)', '일본 엔 (JPY)'];

/// 고무줄 장면의 시간 목록.
const List<String> demoTimes = ['오전 8:00', '오전 8:30', '오전 9:00'];

/// 그림이 놓이는 작은 화면의 폭. 좁은 무대에서는 이보다 작게 그려진다.
const double demoFrameWidth = 480;

/// 속성 미리보기의 작은 화면 높이.
const double demoFrameHeight = 300;

/// 구조 그림의 작은 화면 높이 — 하단 시트 위로 어두운 막이 보이게 둔다.
const double demoAnatomyHeight = 380;

/// 장면의 작은 화면 높이 — 하단 영역과 입력창이 함께 들어간다.
const double demoSceneHeight = 340;

/// 권장 · 금지 카드의 작은 화면 높이.
const double demoCardHeight = 360;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 패널 그림 아래에
/// 실제 서랍을 여는 버튼을 둔다. 플레이그라운드만 켠다: 사이트의 다른 무대는
/// 브라우저에서 깨어나지 않아 그 버튼이 아무것도 열지 못한다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'side': 'right', 'description': demoDescription, 'footer': 'true', 'opener': 'true'},
  label: demoTitle,
  controls: [
    DocsPlaygroundChoice(label: 'side', prop: 'side', options: ['left', 'right', 'top', 'bottom'], segmented: true),
    DocsPlaygroundFlag(label: '설명 (description)', on: {'description': demoDescription}),
    DocsPlaygroundFlag(label: '하단 영역 (footer)', on: {'footer': 'true'}),
    DocsPlaygroundFlag(label: '손잡이 (showDragHandle)', on: {'showDragHandle': 'true'}),
    DocsPlaygroundFlag(label: '닫기 버튼 끄기', on: {'showCloseButton': 'false'}),
    DocsPlaygroundFlag(label: '고무줄 (rubberBand)', on: {'rubberBand': 'true'}),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// 크기 표. Drawer 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `side` — 없거나 모르는 이름이면 `Drawer` 의 기본값.
CoreDrawerSide demoSideOf(Map<String, String> props) =>
    previewEnum(CoreDrawerSide.values, props['side'], CoreDrawerSide.defaultSide);

/// 속성 `showDragHandle` — 없으면 위젯의 기본값.
bool demoShowsHandle(Map<String, String> props) =>
    previewFlag(props, 'showDragHandle', fallback: CoreDrawerContract.defaultShowDragHandle);

/// 속성 `showCloseButton` — 없으면 위젯의 기본값.
bool demoShowsClose(Map<String, String> props) =>
    previewFlag(props, 'showCloseButton', fallback: CoreDrawerContract.defaultShowCloseButton);

/// 속성 `rubberBand` — 없으면 위젯의 기본값. 그림은 읽지 않고, 실제 서랍과
/// 코드가 읽는다.
bool demoRubberBand(Map<String, String> props) =>
    previewFlag(props, 'rubberBand', fallback: CoreDrawerContract.defaultRubberBand);

/// 속성 `footer` — 미리보기가 하단 영역에 취소 · 적용 버튼을 두는가.
bool demoHasFooter(Map<String, String> props) => previewFlag(props, 'footer');

/// 두 플랫폼의 코드가 함께 쓰는 패널의 앞부분.
List<String> _panelLines(Map<String, String> props, String? label) => [
  "      title: '${label ?? demoTitle}',",
  if (props['description'] case final description?) "      description: '$description',",
  if (demoShowsHandle(props)) '      showDragHandle: true,',
  if (!demoShowsClose(props)) '      showCloseButton: false,',
];

/// Flutter 코드 — 제스처 옵션은 `openDrawer` 에 주고, 닫을 때는 `builder` 의
/// 컨텍스트로 `closeDrawer` 를 부른다.
String _flutterCode(Map<String, String> props, String? label) {
  final footer = demoHasFooter(props);
  final lines = [
    'Button(',
    '  variant: CoreButtonVariant.outline,',
    '  onPressed: () => openDrawer<void>(',
    '    context: context,',
    '    side: CoreDrawerSide.${demoSideOf(props).name},',
    if (demoRubberBand(props)) '    rubberBand: true,',
    '    builder: (${footer ? 'drawerContext' : '_'}) => Drawer(',
    ..._panelLines(props, label),
    "      content: Text('$demoContent'),",
    if (footer) ...[
      '      footer: Row(',
      '        mainAxisSize: MainAxisSize.min,',
      '        spacing: CoreSpace.space8,',
      '        children: [',
      '          Button(',
      '            variant: CoreButtonVariant.outline,',
      '            onPressed: () => closeDrawer<void>(drawerContext),',
      "            child: Text('$demoCancel'),",
      '          ),',
      '          Button(',
      '            onPressed: () => closeDrawer<void>(drawerContext),',
      "            child: Text('$demoApply'),",
      '          ),',
      '        ],',
      '      ),',
    ],
    '    ),',
    '  ),',
    "  child: Text('$demoOpener'),",
    ')',
  ];
  return lines.join('\n');
}

/// Web 코드 — 제스처 옵션은 `Drawer` 에 주고, 닫을 때는 `builder` 가 받은
/// `close` 를 부른다.
String _webCode(Map<String, String> props, String? label) {
  final footer = demoHasFooter(props);
  final lines = [
    'Button(',
    '  variant: CoreButtonVariant.outline,',
    '  onPressed: () => openDrawer<void>(',
    '    context: context,',
    '    side: CoreDrawerSide.${demoSideOf(props).name},',
    '    builder: (${footer ? 'close' : '_'}) => Drawer(',
    ..._panelLines(props, label),
    if (demoRubberBand(props)) '      rubberBand: true,',
    "      content: Text('$demoContent'),",
    if (footer) ...[
      "      footer: div(classes: 'flex gap-\${CoreSpace.scale.space8}', [",
      '        Button(',
      '          variant: CoreButtonVariant.outline,',
      '          onPressed: close,',
      "          child: Text('$demoCancel'),",
      '        ),',
      "        Button(onPressed: close, child: Text('$demoApply')),",
      '      ]),',
    ],
    '    ),',
    '  ),',
    "  child: Text('$demoOpener'),",
    ')',
  ];
  return lines.join('\n');
}
