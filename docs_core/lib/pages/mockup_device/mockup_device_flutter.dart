/// MockupDevice 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="mockup-device/...">` 가
/// 읽는다. 같은 이름의 Web 파일(`mockup_device_web.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
///
/// Flutter 의 `MockupDevice` 는 받은 자리를 차지하고 그 위쪽 가운데에 본체를
/// 두며, 자리가 본체보다 좁아도 스스로 줄지 않는다. 장면은 기기를
/// `FittedBox` 에 담아 본체 크기로 두고, 좁은 자리에서는 그림 전체를 줄인다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'mockup_device_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _playgroundDevice;

/// 장면 이름(`mockup-device/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'mockup-device/anatomy': () => _fit(
    MockupDevice(
      width: mockupDeviceAnatomyWidth,
      child: _filled(mockupDeviceScreenText),
    ),
  ),
  'mockup-device/devices': () => _pair([
    _captioned(
      CoreMockupDevice.phone.name,
      MockupDevice(width: mockupDevicePhoneWidth, child: _screen(mockupDeviceScreenText)),
    ),
    _captioned(
      CoreMockupDevice.tablet.name,
      MockupDevice(
        device: CoreMockupDevice.tablet,
        width: mockupDeviceTabletWidth,
        child: _screen(mockupDeviceScreenText),
      ),
    ),
  ]),
  'mockup-device/orientation-phone': () => _pair([
    _captioned(
      CoreMockupOrientation.portrait.name,
      MockupDevice(width: mockupDevicePhoneWidth, child: _screen(mockupDeviceScreenText)),
    ),
    _captioned(
      CoreMockupOrientation.landscape.name,
      MockupDevice(
        orientation: CoreMockupOrientation.landscape,
        width: mockupDeviceLandscapeWidth,
        child: _screen(mockupDeviceScreenText),
      ),
    ),
  ]),
  'mockup-device/orientation-tablet': () => _pair([
    _captioned(
      CoreMockupOrientation.portrait.name,
      MockupDevice(
        device: CoreMockupDevice.tablet,
        width: mockupDeviceTabletWidth,
        child: _screen(mockupDeviceScreenText),
      ),
    ),
    _captioned(
      CoreMockupOrientation.landscape.name,
      MockupDevice(
        device: CoreMockupDevice.tablet,
        orientation: CoreMockupOrientation.landscape,
        width: mockupDeviceLandscapeWidth,
        child: _screen(mockupDeviceScreenText),
      ),
    ),
  ]),
  'mockup-device/finish': () => _pair([
    _captioned(
      mockupDeviceRealisticCaption,
      MockupDevice(width: mockupDevicePhoneWidth, child: _screen(mockupDeviceScreenText)),
    ),
    _captioned(
      mockupDeviceFlatCaption,
      MockupDevice(
        finish: CoreMockupDeviceFinish.flat,
        width: mockupDevicePhoneWidth,
        child: _screen(mockupDeviceScreenText),
      ),
    ),
  ]),
  'mockup-device/flat-decorations': () => _pair([
    _captioned(
      mockupDeviceFlatPlainCaption,
      MockupDevice(
        finish: CoreMockupDeviceFinish.flat,
        width: mockupDevicePhoneWidth,
        child: _filled(mockupDeviceSafeAreaText),
      ),
    ),
    _captioned(
      mockupDeviceFlatDecoratedCaption,
      MockupDevice(
        finish: CoreMockupDeviceFinish.flat,
        width: mockupDevicePhoneWidth,
        showCamera: true,
        showStatusBar: true,
        showGestureBar: true,
        child: _filled(mockupDeviceSafeAreaText),
      ),
    ),
  ]),
  'mockup-device/widths': () => _pair([
    for (final width in mockupDeviceSceneWidths)
      _captioned(
        'width: ${width.toInt()}',
        MockupDevice(width: width, child: _screen(mockupDeviceScreenText)),
      ),
  ]),
  'mockup-device/safe-area': () => _pair([
    _captioned(
      mockupDeviceDecoratedCaption,
      MockupDevice(width: mockupDevicePhoneWidth, child: _filled(mockupDeviceSafeAreaText)),
    ),
    _captioned(
      mockupDeviceUndecoratedCaption,
      MockupDevice(
        width: mockupDevicePhoneWidth,
        showCamera: false,
        showStatusBar: false,
        showGestureBar: false,
        child: _filled(mockupDeviceSafeAreaText),
      ),
    ),
    _captioned(
      mockupDeviceTurnedCaption,
      MockupDevice(
        orientation: CoreMockupOrientation.landscape,
        width: mockupDeviceLandscapeWidth,
        child: _filled(mockupDeviceSafeAreaText),
      ),
    ),
  ]),
  'mockup-device/screen-brightness': () => _fit(
    BrightnessScope(
      brightness: CoreBrightness.dark,
      child: _box(
        width: mockupDeviceBrightCardWidth,
        Card(
          body: MockupDevice(
            finish: CoreMockupDeviceFinish.flat,
            width: mockupDeviceBrightDeviceWidth,
            screenBrightness: CoreBrightness.light,
            child: _column([
              Text(mockupDeviceBrightTitle).titleMedium.onSurface,
              Button(onPressed: () {}, child: const Text(mockupDeviceBrightButton)),
            ]),
          ),
        ),
      ),
    ),
  ),
  'mockup-device/do-screen-fill': () => _fit(
    MockupDevice(
      width: mockupDevicePhoneWidth,
      mockupDeviceStyle: const CoreMockupDeviceStyle(
        backgroundColor: CoreColor.token(CoreColors.primaryContainer),
      ),
      child: _column([const Text(mockupDeviceScreenText).labelMedium.onPrimaryContainer]),
    ),
  ),
  'mockup-device/dont-child-fill': () => _fit(
    MockupDevice(
      width: mockupDevicePhoneWidth,
      child: _filled(mockupDeviceScreenText),
    ),
  ),
  'mockup-device/related-mockup': () => _fit(
    _box(width: mockupDeviceRelatedWidth, MockupCode.fromString(mockupDeviceRelatedCode)),
  ),
  // 폴더블은 본체 폭이 고정이라, 카드가 더 좁으면 그림 전체를 줄인다.
  'mockup-device/related-mockup-foldable': () => _fit(
    _box(
      width: mockupDeviceRelatedFoldableWidth,
      MockupFoldable(width: mockupDeviceRelatedFoldableWidth, child: _screen(mockupDeviceScreenText)),
    ),
  ),
  'mockup-device/related-mockup-browser': () => _fit(
    _box(
      width: mockupDeviceRelatedWidth,
      height: mockupDeviceRelatedBrowserHeight,
      MockupBrowser(
        addressBar: mockupDeviceRelatedAddress,
        child: _screen(mockupDeviceRelatedPageText),
      ),
    ),
  ),
  'mockup-device/related-card': () => _box(
    width: mockupDeviceRelatedWidth,
    Card(body: const Text(mockupDeviceRelatedCardText).bodyMedium.onSurface),
  ),
};

Widget _playgroundDevice(Map<String, String> props, String? label) => _fit(
  MockupDevice(
    device: mockupDevicePreviewKind(props),
    orientation: mockupDevicePreviewOrientation(props),
    finish: mockupDevicePreviewFinish(props),
    width: mockupDevicePreviewWidth(props),
    showCamera: mockupDevicePreviewShown(props, 'showCamera'),
    showStatusBar: mockupDevicePreviewShown(props, 'showStatusBar'),
    showGestureBar: mockupDevicePreviewShown(props, 'showGestureBar'),
    screenBrightness: mockupDevicePreviewBrightness(props),
    child: _screen(label ?? mockupDeviceScreenText),
  ),
);

/// 안전 영역을 채우고 가운데에 세로로 놓는 칸.
Widget _column(List<Widget> children) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space12,
    children: children,
  ),
);

/// 가운데에 글 한 줄을 놓은 화면.
Widget _screen(String text) => _column([Text(text).bodyMedium.onSurface]);

/// 받은 영역을 색으로 채우는 자식 — 안전 영역이 어디까지인지 보인다.
Widget _filled(String text) => Builder(
  builder: (context) => ColoredBox(
    color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.primaryContainer)).toValue(),
    child: Center(child: Text(text).labelMedium.onPrimaryContainer),
  ),
);

/// 폭(과 높이)을 정한 상자.
Widget _box(Widget child, {required double width, double? height}) =>
    SizedBox(width: width, height: height, child: child);

/// [child] 를 자기 크기로 두고, 자리가 좁으면 그림 전체를 줄인다.
Widget _fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, child: child);

/// 위에 설명을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [Text(caption).labelSmall.onSurfaceVariant, child],
);

/// 나란히 놓고, 자리가 좁으면 다음 줄로 넘긴다.
Widget _pair(List<Widget> children) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: [for (final child in children) _fit(child)],
);
