/// Mockup 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `mockup_web.dart` · `mockup_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 이 페이지는 위젯 하나가 아니라 목업 묶음(`MockupBrowser` · `MockupDevice` ·
/// `MockupCode`)을 다룬다. 그래서 플레이그라운드의 속성은 `frame` 하나다 —
/// 어느 틀을 그릴지 고른다. 두 플랫폼의 장면이 같은 글과 같은 폭을 쓰도록
/// 그 값들을 이 파일에 둔다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/mockup.md`.
const String slug = 'mockup';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// 목업에는 크기 단계(`CoreComponentSize`)가 없다. 기기는 `width` 하나로,
/// 브라우저 창과 코드 틀은 부모의 폭으로 크기가 정해진다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 플레이그라운드가 그리는 틀.
enum MockupPageFrame {
  /// 주소창이 있는 `MockupBrowser`.
  browser,

  /// 주소창이 없는 `MockupBrowser` — 앱 창.
  app,

  /// 폰 `MockupDevice`.
  phone,

  /// 태블릿 `MockupDevice`.
  tablet,

  /// `MockupCode`.
  code,
}

/// 속성의 `frame` → 틀. 없거나 모르는 값은 브라우저.
MockupPageFrame mockupPageFrame(Map<String, String> props) =>
    previewEnum(MockupPageFrame.values, props['frame'], MockupPageFrame.browser);

/// 브라우저 창 · 코드 틀 미리보기의 폭(logical px).
const double mockupFrameWidth = 320;

/// 브라우저 창 미리보기의 높이(logical px).
const double mockupBrowserHeight = 176;

/// 앱 창 장면의 높이(logical px).
const double mockupAppWindowHeight = 112;

/// 미리보기 폰의 본체 폭(logical px).
const double mockupPhoneWidth = 160;

/// 미리보기 태블릿의 본체 폭(logical px).
const double mockupTabletWidth = 240;

/// 카드 안의 브라우저 창 · 코드 틀 폭(logical px).
const double mockupCardWidth = 240;

/// 카드 안의 브라우저 창 높이(logical px).
const double mockupCardBrowserHeight = 128;

/// 카드 안의 폴더블 본체 폭(logical px) — 펼친 상태.
const double mockupCardFoldableWidth = 288;

/// 주소창에 적는 글.
const String mockupSampleAddress = 'example.com/docs';

/// 브라우저 창 안의 글.
const String mockupPageText = '페이지 콘텐츠';

/// 브라우저 창 장면의 둘째 줄.
const String mockupPageNote = '툴바 아래에서 시작합니다';

/// 앱 창 안의 글.
const String mockupAppText = '앱 콘텐츠';

/// 기기 화면 안의 글.
const String mockupScreenText = '앱 화면';

/// `mockup/app-window` 장면의 두 설명 — 주소창만 뺀 창과 점까지 뺀 창.
const String mockupAppWindowCaption = 'addressBar: null';

/// [mockupAppWindowCaption] 참고.
const String mockupBareWindowCaption = 'showControls: false 도 함께';

/// `mockup/decorations` 장면의 두 설명.
const String mockupDecoratedCaption = '장식 켜짐 (기본)';

/// [mockupDecoratedCaption] 참고.
const String mockupUndecoratedCaption = '장식 셋 모두 끔';

/// 장식 장면에서 안전 영역을 채우는 글.
const String mockupSafeAreaText = '안전 영역';

/// `mockup/safe-area-fill` 장면의 두 설명.
const String mockupChildFillCaption = 'child 에만 배경색';

/// [mockupChildFillCaption] 참고.
const String mockupScreenFillCaption = '화면 backgroundColor';

/// 예시 화면의 제목과 줄 — 정적인 글만 담는다.
const String mockupOrderTitle = '주문 내역';

/// [mockupOrderTitle] 참고.
const List<String> mockupOrderLines = ['오늘 2건', '배송 준비 중', '도착 예정 내일'];

/// 코드 틀에 넣는 짧은 두 줄.
const String mockupSampleCode = 'flutter pub get\nflutter run';

/// 코드 장면의 세 줄. 들여쓰기가 없는 줄이라 두 플랫폼이 같게 보인다.
const String mockupCommandLines = 'flutter pub get\nflutter test\nflutter build web';

/// 틀보다 긴 한 줄 — 잘리는 모습을 보인다.
const String mockupLongCodeLine = 'flutter build web --release --base-href /docs/ --dart-define=FLAVOR=production';

/// `CodeSnippet` 카드의 코드.
const String mockupSnippetCode = 'void main() => runApp(const App());';

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'frame': MockupPageFrame.browser.name},
  controls: [
    DocsPlaygroundChoice(label: '프레임 종류', prop: 'frame', options: [for (final f in MockupPageFrame.values) f.name]),
  ],
  code: _mockupCode,
);

String _mockupCode(Map<String, String> props, String? label) => switch (mockupPageFrame(props)) {
  MockupPageFrame.browser => _browserCode("'$mockupSampleAddress'", mockupPageText),
  MockupPageFrame.app => _browserCode('null', mockupAppText),
  MockupPageFrame.phone => _deviceCode(null, mockupPhoneWidth),
  MockupPageFrame.tablet => _deviceCode('CoreMockupDevice.tablet', mockupTabletWidth),
  MockupPageFrame.code => [
    '// 폭은 부모가 정합니다.',
    "MockupCode.fromString('${mockupSampleCode.replaceAll('\n', r'\n')}')",
  ].join('\n'),
};

String _browserCode(String address, String text) => [
  '// 폭은 부모를 채웁니다. 부모가 높이를 정하지 않으면 높이는 child 를 따릅니다.',
  'MockupBrowser(',
  '  addressBar: $address,',
  "  child: Text('$text').bodyMedium.onSurface,",
  ')',
].join('\n');

String _deviceCode(String? device, double width) => [
  'MockupDevice(',
  if (device != null) '  device: $device,',
  '  width: ${width.toInt()},',
  "  child: Text('$mockupScreenText').bodyMedium.onSurface,",
  ')',
].join('\n');
