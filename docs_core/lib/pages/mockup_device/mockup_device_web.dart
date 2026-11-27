/// MockupDevice 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="mockup-device/...">` 가
/// 읽는다. 같은 이름의 Flutter 파일(`mockup_device_flutter.dart`)과 컴포넌트 ·
/// 속성 · 장면 이름이 같아야 한다.
///
/// `MockupDevice` 의 부품은 `width` 로 계산한 자리에 놓이므로, 여러 대를
/// 늘어놓을 때는 각 기기를 줄어들지 않는 칸에 담는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'mockup_device_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _playgroundDevice;

/// 장면 이름(`mockup-device/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'mockup-device/anatomy': () => MockupDevice(
    width: mockupDeviceAnatomyWidth,
    child: _filled(mockupDeviceScreenText),
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
  'mockup-device/screen-brightness': () => BrightnessScope(
    brightness: CoreBrightness.dark,
    child: _box(
      width: mockupDeviceBrightCardWidth,
      Card(
        body: _hug(
          MockupDevice(
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
  'mockup-device/do-screen-fill': () => MockupDevice(
    width: mockupDevicePhoneWidth,
    mockupDeviceStyle: const CoreMockupDeviceStyle(
      backgroundColor: CoreColor.token(CoreColors.primaryContainer),
    ),
    child: _column([const Text(mockupDeviceScreenText).labelMedium.onPrimaryContainer]),
  ),
  'mockup-device/dont-child-fill': () => MockupDevice(
    width: mockupDevicePhoneWidth,
    child: _filled(mockupDeviceScreenText),
  ),
  'mockup-device/related-mockup': () => _box(
    width: mockupDeviceRelatedWidth,
    MockupCode.fromString(mockupDeviceRelatedCode),
  ),
  'mockup-device/related-mockup-foldable': () => _box(
    width: mockupDeviceRelatedFoldableWidth,
    MockupFoldable(width: mockupDeviceRelatedFoldableWidth, child: _screen(mockupDeviceScreenText)),
  ),
  'mockup-device/related-mockup-browser': () => _box(
    width: mockupDeviceRelatedWidth,
    height: mockupDeviceRelatedBrowserHeight,
    MockupBrowser(
      addressBar: mockupDeviceRelatedAddress,
      child: _screen(mockupDeviceRelatedPageText),
    ),
  ),
  'mockup-device/related-card': () => _box(
    width: mockupDeviceRelatedWidth,
    Card(body: const Text(mockupDeviceRelatedCardText).bodyMedium.onSurface),
  ),
};

Component _playgroundDevice(Map<String, String> props, String? label) => MockupDevice(
  device: mockupDevicePreviewKind(props),
  orientation: mockupDevicePreviewOrientation(props),
  finish: mockupDevicePreviewFinish(props),
  width: mockupDevicePreviewWidth(props),
  showCamera: mockupDevicePreviewShown(props, 'showCamera'),
  showStatusBar: mockupDevicePreviewShown(props, 'showStatusBar'),
  showGestureBar: mockupDevicePreviewShown(props, 'showGestureBar'),
  screenBrightness: mockupDevicePreviewBrightness(props),
  child: _screen(label ?? mockupDeviceScreenText),
);

/// 안전 영역을 채우고 가운데에 세로로 놓는 칸.
Component _column(List<Component> children) => div(
  styles: const Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': 'var(--coui-space-12)',
      'height': '100%',
    },
  ),
  children,
);

/// 가운데에 글 한 줄을 놓은 화면.
Component _screen(String text) => _column([Text(text).bodyMedium.onSurface]);

/// 받은 영역을 색으로 채우는 자식 — 안전 영역이 어디까지인지 보인다.
Component _filled(String text) => div(
  attributes: const {'data-docs-part': 'content'},
  styles: Styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'height': '100%',
      'background-color': const CoreColor.token(CoreColors.primaryContainer).toValue(),
    },
  ),
  [Text(text).labelMedium.onPrimaryContainer],
);

/// 폭(과 높이)을 정한 상자 — 좁은 자리에서는 폭이 함께 줄어든다.
Component _box(Component child, {required double width, double? height}) => div(
  styles: Styles(
    raw: {
      'width': pinnedLengthCss(width),
      'max-width': '100%',
      if (height != null) 'height': pinnedLengthCss(height),
    },
  ),
  [child],
);

/// 본체 크기의 상자를 가로 가운데에 놓는다.
Component _hug(Component child) => div(
  styles: const Styles(raw: {'display': 'flex', 'justify-content': 'center'}),
  [child],
);

/// 위에 설명을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: const Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': 'var(--coui-space-8)'},
  ),
  [Text(caption).labelSmall.onSurfaceVariant, child],
);

/// 나란히 놓고, 자리가 좁으면 다음 줄로 넘긴다.
Component _pair(List<Component> children) => div(
  styles: const Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': 'var(--coui-space-24)',
    },
  ),
  [
    for (final child in children) div(styles: const Styles(raw: {'flex': 'none'}), [child]),
  ],
);
