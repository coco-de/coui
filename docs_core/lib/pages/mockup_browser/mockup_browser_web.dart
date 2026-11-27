/// MockupBrowser 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="mockup-browser/...">`
/// 가 읽는다. 같은 이름의 Flutter 파일(`mockup_browser_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Web 의 `MockupBrowser` 는 부모의 폭을 채우므로, 장면은 폭을 정한 상자 안에
/// 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'mockup_browser_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _mockupBrowser;

/// 장면 이름(`mockup-browser/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — `child` 자리에는 번호가 찾을 표지를 단다.
  'mockup-browser/anatomy': () => _window(
    width: mockupBrowserAnatomyWidth,
    height: mockupBrowserAnatomyHeight,
    MockupBrowser(
      addressBar: mockupBrowserShortAddress,
      child: _centered(
        attributes: const {'data-docs-part': 'content'},
        [const Text(mockupBrowserSlotText).labelMedium.onSurfaceVariant],
      ),
    ),
  ),
  'mockup-browser/compositions': () => _stack([
    for (final (caption, showControls, hasAddress) in mockupBrowserCompositions)
      _captioned(
        caption,
        _window(
          width: mockupBrowserSceneWidth,
          height: mockupBrowserSceneHeight,
          MockupBrowser(
            showControls: showControls,
            addressBar: hasAddress ? mockupBrowserShortAddress : null,
            child: _screen(hasAddress ? mockupBrowserPageText : mockupBrowserAppText),
          ),
        ),
      ),
  ]),
  // `child` 와 부모 높이가 없어 툴바만 보인다.
  'mockup-browser/address': () => _stack([
    for (final (caption, address, align) in mockupBrowserAddressCases)
      _captioned(
        caption,
        _window(
          width: mockupBrowserWideWidth,
          MockupBrowser(
            addressBar: address,
            mockupBrowserStyle: align == null ? null : CoreMockupBrowserStyle(addressBarTextAlign: align),
          ),
        ),
      ),
  ]),
  'mockup-browser/sizing': () => _stack([
    _captioned(
      mockupBrowserChildSizedCaption,
      _window(
        width: mockupBrowserSceneWidth,
        MockupBrowser(
          child: div(
            styles: Styles(
              raw: {
                'display': 'flex',
                'align-items': 'center',
                'justify-content': 'center',
                'height': pinnedLengthCss(mockupBrowserChildHeight),
              },
            ),
            [const Text(mockupBrowserPageText).bodySmall.onSurfaceVariant],
          ),
        ),
      ),
    ),
    _captioned(
      mockupBrowserEmptyCaption,
      _window(width: mockupBrowserSceneWidth, const MockupBrowser()),
    ),
    _captioned(
      mockupBrowserParentSizedCaption,
      _window(
        width: mockupBrowserSceneWidth,
        height: mockupBrowserParentHeight,
        MockupBrowser(child: _screen(mockupBrowserPageText)),
      ),
    ),
  ]),
  'mockup-browser/styled': () => _window(
    width: mockupBrowserSceneWidth,
    height: mockupBrowserCardHeight,
    MockupBrowser(
      addressBar: mockupBrowserShortAddress,
      mockupBrowserStyle: const CoreMockupBrowserStyle(
        contentBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
      child: _screen(mockupBrowserPageText),
    ),
  ),
  'mockup-browser/do-short-address': () => _window(
    width: mockupBrowserSceneWidth,
    height: mockupBrowserCardHeight,
    MockupBrowser(addressBar: mockupBrowserShortAddress, child: _screen(mockupBrowserPageText)),
  ),
  'mockup-browser/dont-long-address': () => _window(
    width: mockupBrowserSceneWidth,
    height: mockupBrowserCardHeight,
    MockupBrowser(addressBar: mockupBrowserLongAddress, child: _screen(mockupBrowserPageText)),
  ),
  'mockup-browser/related-mockup': () => _stack([
    _window(
      width: mockupBrowserRelatedWidth,
      height: mockupBrowserRelatedHeight,
      MockupBrowser(addressBar: null, child: _screen(mockupBrowserAppText)),
    ),
    _window(width: mockupBrowserRelatedWidth, MockupCode.fromString(mockupBrowserSampleCode)),
  ]),
  'mockup-browser/related-mockup-device': () => MockupDevice(
    width: mockupBrowserPhoneWidth,
    child: _screen(mockupBrowserScreenText),
  ),
  'mockup-browser/related-mockup-code': () => _window(
    width: mockupBrowserRelatedWidth,
    MockupCode.fromString(mockupBrowserSampleCode),
  ),
  'mockup-browser/related-card': () => _window(
    width: mockupBrowserRelatedWidth,
    Card(body: const Text(mockupBrowserPageText).bodyMedium.onSurface),
  ),
};

Component _mockupBrowser(Map<String, String> props, String? label) => _window(
  width: mockupBrowserPlaygroundWidth,
  height: mockupBrowserPlaygroundHeight,
  MockupBrowser(
    showControls: mockupBrowserShowControls(props),
    addressBar: mockupBrowserAddress(props),
    mockupBrowserStyle: mockupBrowserCentersAddress(props)
        ? const CoreMockupBrowserStyle(addressBarTextAlign: CoreTextAlign.center)
        : null,
    child: _centered([Text(mockupBrowserBodyText(props))]),
  ),
);

/// 폭(과 높이)을 정한 상자 — 좁은 자리에서는 폭이 함께 줄어든다.
Component _window(Component child, {required double width, double? height}) => div(
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
Component _centered(List<Component> children, {Map<String, String>? attributes}) => div(
  attributes: attributes,
  styles: const Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'justify-content': 'center',
      'height': '100%',
    },
  ),
  children,
);

/// 제목 한 줄을 담은 정적인 화면.
Component _screen(String title) => _centered([Text(title).titleSmall.onSurface]);

/// 위에 설명을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: const Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': 'var(--coui-space-8)',
      'width': '100%',
    },
  ),
  [Text(caption).labelSmall.onSurfaceVariant, child],
);

/// 위에서 아래로 쌓는다.
Component _stack(List<Component> children) => div(
  styles: const Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': 'var(--coui-space-16)',
      'width': '100%',
    },
  ),
  children,
);
