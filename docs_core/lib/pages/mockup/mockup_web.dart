/// Mockup 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="mockup/...">` 가
/// 읽는다. 같은 이름의 Flutter 파일(`mockup_flutter.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
///
/// Web 의 `MockupBrowser` · `MockupCode` 는 부모의 폭을 채우므로, 장면은
/// 폭을 정한 상자 안에 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'mockup_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _mockup;

/// 장면 이름(`mockup/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
    _captioned(
      mockupDecoratedCaption,
      MockupDevice(width: mockupPhoneWidth, child: _filled(mockupSafeAreaText)),
    ),
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
  ]),
  'mockup/safe-area-fill': () => _pair([
    _captioned(
      mockupChildFillCaption,
      MockupDevice(width: mockupPhoneWidth, child: _filled(mockupScreenText)),
    ),
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
  'mockup/related-mockup-foldable': () => _box(
    width: mockupCardFoldableWidth,
    MockupFoldable(width: mockupCardFoldableWidth, child: _screen(mockupScreenText)),
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

Component _mockup(Map<String, String> props, String? label) => switch (mockupPageFrame(props)) {
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
  MockupPageFrame.phone => MockupDevice(
    width: mockupPhoneWidth,
    child: const Text(mockupScreenText).bodyMedium.onSurface,
  ),
  MockupPageFrame.tablet => MockupDevice(
    device: CoreMockupDevice.tablet,
    width: mockupTabletWidth,
    child: const Text(mockupScreenText).bodyMedium.onSurface,
  ),
  MockupPageFrame.code => _box(width: mockupFrameWidth, MockupCode.fromString(mockupSampleCode)),
};

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

/// 세로 · 가로 가운데에 놓는 칸 — 부모의 높이를 채운다.
Component _centered(List<Component> children) => div(
  styles: const Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': 'var(--coui-space-4)',
      'height': '100%',
    },
  ),
  children,
);

/// 제목과 설명 줄을 담은 정적인 화면.
Component _screen(String title, [List<String> lines = const []]) => _centered([
  Text(title).titleSmall.onSurface,
  for (final line in lines) Text(line).bodySmall.onSurfaceVariant,
]);

/// 받은 영역을 색으로 채우는 자식 — 안전 영역이 어디까지인지 보인다.
Component _filled(String text) => div(
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

/// 위에 설명을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: const Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': 'var(--coui-space-8)'},
  ),
  [Text(caption).labelSmall.onSurfaceVariant, child],
);

/// 위에서 아래로 쌓는다.
Component _stack(List<Component> children) => div(
  styles: const Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': 'var(--coui-space-16)'},
  ),
  children,
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
  children,
);
