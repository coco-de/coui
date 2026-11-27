/// MockupBrowser 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="mockup-browser/...">`
/// 가 읽는다. 같은 이름의 Web 파일(`mockup_browser_web.dart`)과 컴포넌트 ·
/// 속성 · 장면 이름이 같아야 한다.
///
/// Flutter 의 `MockupBrowser` 는 폭이 정해진 부모가 필요하고, 툴바의 점 ·
/// 아이콘 캡슐은 줄지 않는다. 그래서 창은 정한 크기로 그리고, 자리가 더
/// 좁으면 그림 전체를 줄인다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'mockup_browser_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _mockupBrowser;

/// 장면 이름(`mockup-browser/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'mockup-browser/anatomy': () => _window(
    width: mockupBrowserAnatomyWidth,
    height: mockupBrowserAnatomyHeight,
    MockupBrowser(
      addressBar: mockupBrowserShortAddress,
      child: _centered([const Text(mockupBrowserSlotText).labelMedium.onSurfaceVariant]),
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
          child: SizedBox(
            height: mockupBrowserChildHeight,
            child: Center(child: const Text(mockupBrowserPageText).bodySmall.onSurfaceVariant),
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
    SizedBox(width: mockupBrowserRelatedWidth, child: MockupCode.fromString(mockupBrowserSampleCode)),
  ]),
  'mockup-browser/related-mockup-device': () => MockupDevice(
    width: mockupBrowserPhoneWidth,
    child: _screen(mockupBrowserScreenText),
  ),
  'mockup-browser/related-mockup-code': () => SizedBox(
    width: mockupBrowserRelatedWidth,
    child: MockupCode.fromString(mockupBrowserSampleCode),
  ),
  'mockup-browser/related-card': () => SizedBox(
    width: mockupBrowserRelatedWidth,
    child: Card(body: const Text(mockupBrowserPageText).bodyMedium.onSurface),
  ),
};

Widget _mockupBrowser(Map<String, String> props, String? label) => _window(
  width: mockupBrowserPlaygroundWidth,
  height: mockupBrowserPlaygroundHeight,
  MockupBrowser(
    showControls: mockupBrowserShowControls(props),
    addressBar: mockupBrowserAddress(props),
    mockupBrowserStyle: mockupBrowserCentersAddress(props)
        ? const CoreMockupBrowserStyle(addressBarTextAlign: CoreTextAlign.center)
        : null,
    child: Center(child: Text(mockupBrowserBodyText(props))),
  ),
);

/// 폭(과 높이)을 정한 상자 — 자리가 더 좁으면 그림 전체를 줄인다.
Widget _window(Widget child, {required double width, double? height}) => FittedBox(
  fit: BoxFit.scaleDown,
  child: SizedBox(width: width, height: height, child: child),
);

/// 세로 · 가로 가운데에 놓는 칸.
Widget _centered(List<Widget> children) => Center(
  child: Column(mainAxisSize: MainAxisSize.min, children: children),
);

/// 제목 한 줄을 담은 정적인 화면.
Widget _screen(String title) => _centered([Text(title).titleSmall.onSurface]);

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
