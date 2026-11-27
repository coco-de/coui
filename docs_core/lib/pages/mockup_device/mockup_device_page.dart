/// MockupDevice 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `mockup_device_web.dart` · `mockup_device_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 위젯 생성자의 이름을 그대로 쓴다. `showCamera` · `showStatusBar` ·
/// `showGestureBar` · `screenBrightness` 는 값을 적지 않는 상태가 따로 뜻을
/// 가지므로 선택지에 `null` 을 둔다. 속성 해석과 두 플랫폼 장면이 함께 쓰는
/// 글 · 폭은 이 파일에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/mockup-device.md`.
const String slug = 'mockup-device';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// `MockupDevice` 에는 크기 단계(`CoreComponentSize`)가 없다. 본체의 크기는
/// `width` 하나와 화면 비율에서 나온다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `device`. 없거나 모르는 값은 기본 기기.
CoreMockupDevice mockupDevicePreviewKind(Map<String, String> props) =>
    previewEnum(CoreMockupDevice.values, props['device'], CoreMockupDevice.defaultDevice);

/// 속성의 `orientation`. 없거나 모르는 값은 기본 방향.
CoreMockupOrientation mockupDevicePreviewOrientation(Map<String, String> props) =>
    previewEnum(CoreMockupOrientation.values, props['orientation'], CoreMockupOrientation.defaultOrientation);

/// 속성의 `finish`. 없거나 모르는 값은 기본 마감.
CoreMockupDeviceFinish mockupDevicePreviewFinish(Map<String, String> props) =>
    previewEnum(CoreMockupDeviceFinish.values, props['finish'], CoreMockupDeviceFinish.defaultFinish);

/// 속성의 `width`. 숫자가 아니면 `null` — 마감의 기본 너비를 쓴다.
double? mockupDevicePreviewWidth(Map<String, String> props) => double.tryParse(props['width'] ?? '');

/// `showCamera` 류의 속성 [key]. `true` · `false` 가 아니면 `null` — 마감을 따른다.
bool? mockupDevicePreviewShown(Map<String, String> props, String key) => switch (props[key]) {
  'true' => true,
  'false' => false,
  _ => null,
};

/// 속성의 `screenBrightness`. `light` · `dark` 가 아니면 `null` — 페이지의 밝기를
/// 따른다.
CoreBrightness? mockupDevicePreviewBrightness(Map<String, String> props) => switch (props['screenBrightness']) {
  'light' => CoreBrightness.light,
  'dark' => CoreBrightness.dark,
  _ => null,
};

/// 화면 안의 글.
const String mockupDeviceScreenText = '앱 화면';

/// 장면 속 폰의 본체 폭(logical px).
const double mockupDevicePhoneWidth = 160;

/// 장면 속 태블릿의 본체 폭(logical px).
const double mockupDeviceTabletWidth = 200;

/// 장면 속 가로 기기의 본체 폭(logical px).
const double mockupDeviceLandscapeWidth = 280;

/// 구조 장면의 폰 본체 폭(logical px).
const double mockupDeviceAnatomyWidth = 200;

/// `mockup-device/widths` 장면에 늘어놓는 폭(logical px).
const List<double> mockupDeviceSceneWidths = [160, 200, 240];

/// `mockup-device/finish` 장면의 두 설명.
const String mockupDeviceRealisticCaption = 'realistic (기본)';

/// [mockupDeviceRealisticCaption] 참고.
const String mockupDeviceFlatCaption = 'flat';

/// `mockup-device/flat-decorations` 장면의 두 설명.
const String mockupDeviceFlatPlainCaption = 'flat 기본';

/// [mockupDeviceFlatPlainCaption] 참고.
const String mockupDeviceFlatDecoratedCaption = '장식 셋 켬';

/// `mockup-device/safe-area` 장면의 세 설명.
const String mockupDeviceDecoratedCaption = '장식 켜짐 (기본)';

/// [mockupDeviceDecoratedCaption] 참고.
const String mockupDeviceUndecoratedCaption = '장식 셋 모두 끔';

/// [mockupDeviceDecoratedCaption] 참고.
const String mockupDeviceTurnedCaption = '가로 폰';

/// 안전 영역을 색으로 채우는 자식의 글.
const String mockupDeviceSafeAreaText = '안전 영역';

/// `mockup-device/screen-brightness` 장면의 화면 제목.
const String mockupDeviceBrightTitle = '라이트 앱';

/// [mockupDeviceBrightTitle] 아래 버튼의 글.
const String mockupDeviceBrightButton = '열기';

/// 화면 밝기 장면의 어두운 카드 폭(logical px).
const double mockupDeviceBrightCardWidth = 264;

/// 화면 밝기 장면의 기기 본체 폭(logical px).
const double mockupDeviceBrightDeviceWidth = 200;

/// 관련 컴포넌트 카드의 창 · 코드 틀 폭(logical px).
///
/// Flutter 브라우저 창의 툴바는 점 · 캡슐 · 아이콘이 줄지 않는다. 기본 스타일에서
/// 약 225 가 필요하므로, 그보다 좁게 두면 툴바가 넘친다.
const double mockupDeviceRelatedWidth = 264;

/// 관련 컴포넌트 카드의 브라우저 창 높이(logical px).
const double mockupDeviceRelatedBrowserHeight = 128;

/// 관련 컴포넌트 카드의 폴더블 본체 폭(logical px).
const double mockupDeviceRelatedFoldableWidth = 288;

/// 관련 컴포넌트 카드의 주소.
const String mockupDeviceRelatedAddress = 'example.com';

/// 관련 컴포넌트 카드의 창 안 글.
const String mockupDeviceRelatedPageText = '페이지 콘텐츠';

/// 관련 컴포넌트 카드의 코드 한 줄.
const String mockupDeviceRelatedCode = 'flutter run';

/// `Card` 카드의 글.
const String mockupDeviceRelatedCardText = '카드 콘텐츠';

/// 값을 적지 않는다는 선택지.
const String _unset = 'null';

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: const {
    'device': 'phone',
    'orientation': 'portrait',
    'finish': 'realistic',
    'width': '200',
    'showCamera': _unset,
    'showStatusBar': _unset,
    'showGestureBar': _unset,
    'screenBrightness': _unset,
  },
  label: mockupDeviceScreenText,
  controls: [
    DocsPlaygroundChoice(
      label: 'device',
      prop: 'device',
      options: [for (final value in CoreMockupDevice.values) value.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'orientation',
      prop: 'orientation',
      options: [for (final value in CoreMockupOrientation.values) value.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'finish',
      prop: 'finish',
      options: [for (final value in CoreMockupDeviceFinish.values) value.name],
      segmented: true,
    ),
    const DocsPlaygroundChoice(
      label: 'width',
      prop: 'width',
      options: ['160', '200', '240', '320'],
      segmented: true,
    ),
    const DocsPlaygroundChoice(
      label: 'showCamera',
      prop: 'showCamera',
      options: [_unset, 'true', 'false'],
      segmented: true,
    ),
    const DocsPlaygroundChoice(
      label: 'showStatusBar',
      prop: 'showStatusBar',
      options: [_unset, 'true', 'false'],
      segmented: true,
    ),
    const DocsPlaygroundChoice(
      label: 'showGestureBar',
      prop: 'showGestureBar',
      options: [_unset, 'true', 'false'],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'screenBrightness',
      prop: 'screenBrightness',
      options: [_unset, for (final value in CoreBrightness.values) value.name],
      segmented: true,
    ),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

String _flutterCode(Map<String, String> props, String? label) => _deviceCode(props, [
  '  child: Center(',
  "    child: Text('${label ?? mockupDeviceScreenText}').bodyMedium.onSurface,",
  '  ),',
]);

/// Web 의 `child` 는 평범한 블록이라, 가운데에 놓는 상자를 직접 둔다.
String _webCode(Map<String, String> props, String? label) => _deviceCode(props, [
  '  child: div(',
  "    classes: 'flex h-full items-center justify-center',",
  "    [Text('${label ?? mockupDeviceScreenText}').bodyMedium.onSurface],",
  '  ),',
]);

/// 두 플랫폼이 함께 쓰는 속성 줄 — `child` 줄만 다르다.
String _deviceCode(Map<String, String> props, List<String> childLines) {
  final device = mockupDevicePreviewKind(props);
  final orientation = mockupDevicePreviewOrientation(props);
  final finish = mockupDevicePreviewFinish(props);
  final width = mockupDevicePreviewWidth(props);
  final camera = mockupDevicePreviewShown(props, 'showCamera');
  final statusBar = mockupDevicePreviewShown(props, 'showStatusBar');
  final gestureBar = mockupDevicePreviewShown(props, 'showGestureBar');
  final brightness = mockupDevicePreviewBrightness(props);

  return [
    'MockupDevice(',
    if (device != CoreMockupDevice.defaultDevice) '  device: CoreMockupDevice.${device.name},',
    if (orientation != CoreMockupOrientation.defaultOrientation)
      '  orientation: CoreMockupOrientation.${orientation.name},',
    if (finish != CoreMockupDeviceFinish.defaultFinish) '  finish: CoreMockupDeviceFinish.${finish.name},',
    if (width != null && width != CoreMockupDeviceStyle.defaultWidthFor(finish)) '  width: ${width.toInt()},',
    if (camera != null) '  showCamera: $camera,',
    if (statusBar != null) '  showStatusBar: $statusBar,',
    if (gestureBar != null) '  showGestureBar: $gestureBar,',
    if (brightness != null) '  screenBrightness: CoreBrightness.${brightness.name},',
    ...childLines,
    ')',
  ].join('\n');
}
