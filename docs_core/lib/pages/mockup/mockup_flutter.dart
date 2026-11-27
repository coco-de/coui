/// Mockup 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="mockup/...">` 가
/// 읽는다. 같은 이름의 Web 파일(`mockup_web.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
///
/// Flutter 의 `MockupBrowser` · `MockupCode` 는 부모의 폭을 채우므로 폭이 정해진
/// 부모가 필요하다. `MockupDevice` 는 받은 폭을 모두 차지하고 본체를 가운데에
/// 두므로, 나란히 놓을 때는 본체 폭의 상자에 담는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'mockup_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _mockup;

/// 장면 이름(`mockup/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'mockup/browser': () => _box(
    width: mockupFrameWidth,
    height: mockupBrowserHeight,
    MockupBrowser(
      addressBar: mockupSampleAddress,
      child: _screen(mockupPageText, [mockupPageNote]),
    ),
  ),
  'mockup/app-window': () => _stack([
    _captioned(
      mockupAppWindowCaption,
      _box(
        width: mockupFrameWidth,
        height: mockupAppWindowHeight,
        MockupBrowser(addressBar: null, child: _screen(mockupAppText)),
      ),
    ),
    _captioned(
      mockupBareWindowCaption,
      _box(
        width: mockupFrameWidth,
        height: mockupAppWindowHeight,
        MockupBrowser(addressBar: null, showControls: false, child: _screen(mockupAppText)),
      ),
    ),
  ]),
  'mockup/code': () => _box(width: mockupFrameWidth, MockupCode.fromString(mockupCommandLines)),
  'mockup/decorations': () => _pair([
    _box(
      width: mockupPhoneWidth,
      _captioned(
        mockupDecoratedCaption,
        MockupDevice(width: mockupPhoneWidth, child: _filled(mockupSafeAreaText)),
      ),
    ),
    _box(
      width: mockupPhoneWidth,
      _captioned(
        mockupUndecoratedCaption,
        MockupDevice(
          width: mockupPhoneWidth,
          showCamera: false,
          showStatusBar: false,
          showGestureBar: false,
          child: _filled(mockupSafeAreaText),
        ),
      ),
    ),
  ]),
  'mockup/safe-area-fill': () => _pair([
    _box(
      width: mockupPhoneWidth,
      _captioned(
        mockupChildFillCaption,
        MockupDevice(width: mockupPhoneWidth, child: _filled(mockupScreenText)),
      ),
    ),
    _box(
      width: mockupPhoneWidth,
      _captioned(
        mockupScreenFillCaption,
        MockupDevice(
          width: mockupPhoneWidth,
          mockupDeviceStyle: const CoreMockupDeviceStyle(
            backgroundColor: CoreColor.token(CoreColors.primaryContainer),
          ),
          child: _centered([const Text(mockupScreenText).labelMedium.onPrimaryContainer]),
        ),
      ),
    ),
  ]),
  'mockup/do-sample-screen': () => MockupDevice(
    width: mockupPhoneWidth,
    child: _screen(mockupOrderTitle, mockupOrderLines),
  ),
  'mockup/do-short-code': () => _box(width: mockupCardWidth, MockupCode.fromString(mockupSampleCode)),
  'mockup/dont-long-code': () => _box(width: mockupCardWidth, MockupCode.fromString(mockupLongCodeLine)),
  'mockup/related-mockup-browser': () => _box(
    width: mockupCardWidth,
    height: mockupCardBrowserHeight,
    MockupBrowser(addressBar: mockupSampleAddress, child: _screen(mockupPageText)),
  ),
  'mockup/related-mockup-device': () => MockupDevice(width: mockupPhoneWidth, child: _screen(mockupScreenText)),
  'mockup/related-mockup-code': () => _box(width: mockupCardWidth, MockupCode.fromString(mockupSampleCode)),
  // 폴더블은 본체 폭이 고정이라, 카드가 더 좁으면 그림 전체를 줄인다.
  'mockup/related-mockup-foldable': () => FittedBox(
    fit: BoxFit.scaleDown,
    child: _box(
      width: mockupCardFoldableWidth,
      MockupFoldable(width: mockupCardFoldableWidth, child: _screen(mockupScreenText)),
    ),
  ),
  'mockup/related-card': () => _box(
    width: mockupCardWidth,
    Card(body: const Text(mockupPageText).bodyMedium.onSurface),
  ),
  'mockup/related-code-snippet': () => _box(
    width: mockupCardWidth,
    const CodeSnippet(code: mockupSnippetCode, mode: 'dart', showCopyButton: false),
  ),
};

Widget _mockup(Map<String, String> props, String? label) => switch (mockupPageFrame(props)) {
  MockupPageFrame.browser => _box(
    width: mockupFrameWidth,
    height: mockupBrowserHeight,
    MockupBrowser(
      addressBar: mockupSampleAddress,
      child: const Text(mockupPageText).bodyMedium.onSurface,
    ),
  ),
  MockupPageFrame.app => _box(
    width: mockupFrameWidth,
    height: mockupBrowserHeight,
    MockupBrowser(
      addressBar: null,
      child: const Text(mockupAppText).bodyMedium.onSurface,
    ),
  ),
  MockupPageFrame.phone => _fit(
    width: mockupPhoneWidth,
    MockupDevice(width: mockupPhoneWidth, child: const Text(mockupScreenText).bodyMedium.onSurface),
  ),
  MockupPageFrame.tablet => _fit(
    width: mockupTabletWidth,
    MockupDevice(
      device: CoreMockupDevice.tablet,
      width: mockupTabletWidth,
      child: const Text(mockupScreenText).bodyMedium.onSurface,
    ),
  ),
  MockupPageFrame.code => _box(width: mockupFrameWidth, MockupCode.fromString(mockupSampleCode)),
};

/// 폭(과 높이)을 정한 상자 — 좁은 자리에서는 폭이 함께 줄어든다.
Widget _box(Widget child, {required double width, double? height}) =>
    SizedBox(width: width, height: height, child: child);

/// 폭을 정한 기기 — 자리가 더 좁으면 그림 전체를 줄인다.
Widget _fit(Widget child, {required double width}) => FittedBox(
  fit: BoxFit.scaleDown,
  child: SizedBox(width: width, child: child),
);

/// 세로 · 가로 가운데에 놓는 칸.
Widget _centered(List<Widget> children) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space4,
    children: children,
  ),
);

/// 제목과 설명 줄을 담은 정적인 화면.
Widget _screen(String title, [List<String> lines = const []]) => _centered([
  Text(title).titleSmall.onSurface,
  for (final line in lines) Text(line).bodySmall.onSurfaceVariant,
]);

/// 받은 영역을 색으로 채우는 자식 — 안전 영역이 어디까지인지 보인다.
Widget _filled(String text) => Builder(
  builder: (context) => ColoredBox(
    color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.primaryContainer)).toValue(),
    child: Center(child: Text(text).labelMedium.onPrimaryContainer),
  ),
);

/// 위에 설명을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [Text(caption).labelSmall.onSurfaceVariant, child],
);

/// 위에서 아래로 쌓는다.
Widget _stack(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space16,
  children: children,
);

/// 나란히 놓고, 자리가 좁으면 다음 줄로 넘긴다.
Widget _pair(List<Widget> children) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: children,
);
