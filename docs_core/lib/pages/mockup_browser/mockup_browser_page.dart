/// MockupBrowser 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `mockup_browser_web.dart` · `mockup_browser_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// MockupBrowser 에는 variant · 크기 단계가 없어 플레이그라운드가 작다. 창의
/// 구성을 정하는 `showControls` · `addressBar` 와, 정해야 동작이 달라지는
/// `addressBarTextAlign` 만 바꾼다. 두 플랫폼의 장면이 같은 글과 같은 크기를
/// 쓰도록 그 값들을 이 파일에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/mockup-browser.md`.
const String slug = 'mockup-browser';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {},
  controls: [
    DocsPlaygroundFlag(label: '창 컨트롤 숨기기', on: {'showControls': 'false'}),
    DocsPlaygroundFlag(label: '앱 창 (주소창 없음)', on: {'addressBar': 'null'}),
    DocsPlaygroundFlag(label: '주소 가운데 정렬', on: {'addressBarTextAlign': 'center'}),
  ],
  code: _mockupBrowserCode,
  webCode: _mockupBrowserWebCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// 창의 크기는 크기 단계(`CoreComponentSize`)가 아니라 부모의 폭과 `child` 의
/// 높이가 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `showControls` — 없으면 위젯의 기본값.
bool mockupBrowserShowControls(Map<String, String> props) =>
    previewFlag(props, 'showControls', fallback: CoreMockupBrowserContract.defaultShowControls);

/// 속성의 `addressBar` → 주소창에 넣을 글. `null` 이면 앱 창이다.
String? mockupBrowserAddress(Map<String, String> props) =>
    props['addressBar'] == 'null' ? null : mockupBrowserPlaygroundAddress;

/// 속성이 주소 정렬을 가운데로 직접 정했는가.
bool mockupBrowserCentersAddress(Map<String, String> props) =>
    props['addressBarTextAlign'] == CoreTextAlign.center.name;

/// 플레이그라운드 창 안의 글.
String mockupBrowserBodyText(Map<String, String> props) =>
    mockupBrowserAddress(props) == null ? mockupBrowserAppText : mockupBrowserPageText;

/// 플레이그라운드의 주소.
const String mockupBrowserPlaygroundAddress = 'example.com/docs';

/// 장면의 짧은 주소.
const String mockupBrowserShortAddress = 'example.com';

/// 주소창보다 긴 주소 — 말줄임을 보인다.
const String mockupBrowserLongAddress = 'https://example.com/workspace/projects/quarterly-report/summary?tab=all';

/// 웹 페이지 창 안의 글.
const String mockupBrowserPageText = '페이지 콘텐츠';

/// 앱 창 안의 글.
const String mockupBrowserAppText = '앱 콘텐츠';

/// 구조 장면에서 `child` 자리에 두는 글.
const String mockupBrowserSlotText = 'child';

/// 기기 틀 카드의 화면 글.
const String mockupBrowserScreenText = '앱 화면';

/// 코드 틀 카드의 코드.
const String mockupBrowserSampleCode = 'flutter pub get\nflutter run';

/// 플레이그라운드 창의 폭(logical px).
const double mockupBrowserPlaygroundWidth = 340;

/// 플레이그라운드 창의 높이(logical px).
const double mockupBrowserPlaygroundHeight = 180;

/// 구조 · 주소창 장면의 폭(logical px).
const double mockupBrowserWideWidth = 360;

/// 구조 그림의 폭 — 390px 화면에서도 번호가 무대 안에 놓이게 양옆을 비운다.
const double mockupBrowserAnatomyWidth = 264;

/// 구조 장면의 높이(logical px).
const double mockupBrowserAnatomyHeight = 180;

/// 그 밖의 장면과 권장 · 금지 카드의 폭(logical px).
const double mockupBrowserSceneWidth = 320;

/// 창 구성 장면 한 창의 높이(logical px).
const double mockupBrowserSceneHeight = 112;

/// 권장 · 금지 카드와 스타일 장면의 높이(logical px).
const double mockupBrowserCardHeight = 128;

/// 배치 장면에서 부모가 정하는 높이(logical px).
const double mockupBrowserParentHeight = 144;

/// 배치 장면에서 `child` 가 스스로 정하는 높이(logical px).
const double mockupBrowserChildHeight = CoreSpace.space72;

/// 관련 컴포넌트 카드의 폭(logical px).
const double mockupBrowserRelatedWidth = 240;

/// 관련 컴포넌트 카드의 앱 창 높이(logical px).
const double mockupBrowserRelatedHeight = 96;

/// 관련 컴포넌트 카드의 폰 본체 폭(logical px).
const double mockupBrowserPhoneWidth = 144;

/// `mockup-browser/compositions` 장면의 창 — 설명, `showControls`, 주소창을
/// 두는지.
const List<(String, bool, bool)> mockupBrowserCompositions = [
  ('addressBar 를 정함 — 웹 페이지', true, true),
  ('showControls: false — 점이 없는 웹 페이지', false, true),
  ('addressBar: null — 앱 창', true, false),
  ('둘 다 끔 — 툴바 자리만 남음', false, false),
];

/// `mockup-browser/address` 장면의 창 — 설명, 주소, 직접 정한 정렬.
const List<(String, String, CoreTextAlign?)> mockupBrowserAddressCases = [
  ('기본 — 자물쇠 옆, 앞쪽에서 시작', mockupBrowserShortAddress, null),
  ('addressBarTextAlign: CoreTextAlign.center', mockupBrowserShortAddress, CoreTextAlign.center),
  ('긴 주소 — 한 줄로 두고 말줄임표', mockupBrowserLongAddress, null),
];

/// `mockup-browser/sizing` 장면의 세 설명 — `child` 높이, `child` 없음, 부모
/// 높이.
const String mockupBrowserChildSizedCaption = 'child 높이 72 — 창 높이 116';

/// [mockupBrowserChildSizedCaption] 참고.
const String mockupBrowserEmptyCaption = 'child 없음 — 툴바 자리 44 만 남음';

/// [mockupBrowserChildSizedCaption] 참고.
const String mockupBrowserParentSizedCaption = '부모 높이 144 — 창이 그 높이를 채움';

/// Flutter 코드 — 부모의 높이가 정해진 창에서 글을 가운데에 둔다.
String _mockupBrowserCode(Map<String, String> props, String? label) => _mockupBrowserSnippet(props, [
  "  child: Center(child: Text('${mockupBrowserBodyText(props)}')),",
]);

/// Web 코드 — `child` 를 가운데에 두는 상자만 다르다.
String _mockupBrowserWebCode(Map<String, String> props, String? label) => _mockupBrowserSnippet(props, [
  '  child: div(',
  "    [Text('${mockupBrowserBodyText(props)}')],",
  "    classes: 'flex h-full items-center justify-center',",
  '  ),',
]);

/// 속성 → 코드. 기본값과 같은 `showControls` 는 적지 않고, 주소창이 없으면
/// 주소 정렬도 적지 않는다.
String _mockupBrowserSnippet(Map<String, String> props, List<String> childLines) {
  final address = mockupBrowserAddress(props);
  return [
    '// 폭과 높이는 부모가 정합니다.',
    'MockupBrowser(',
    if (!mockupBrowserShowControls(props)) '  showControls: false,',
    if (address == null) '  addressBar: null,' else "  addressBar: '$address',",
    if (address != null && mockupBrowserCentersAddress(props)) ...[
      '  mockupBrowserStyle: const CoreMockupBrowserStyle(',
      '    addressBarTextAlign: CoreTextAlign.center,',
      '  ),',
    ],
    ...childLines,
    ')',
  ].join('\n');
}
