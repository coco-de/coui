/// MockupCode 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="mockup-code/...">` 가
/// 읽는다. 같은 이름의 Flutter 파일(`mockup_code_flutter.dart`)과 컴포넌트 ·
/// 속성 · 장면 이름이 같아야 한다.
///
/// Web 의 `MockupCode` 는 부모의 폭을 채우므로, 장면은 폭을 정한 상자 안에
/// 둔다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'mockup_code_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _mockupCode;

/// 장면 이름(`mockup-code/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'mockup-code/anatomy': () => _box(width: mockupCodeAnatomyWidth, MockupCode.fromString(mockupCodeSample)),
  'mockup-code/from-string': () => _box(
    _stack([
      _captioned(mockupCodeNumberedCaption, MockupCode.fromString(mockupCodeShortSample)),
      _captioned(
        mockupCodeUnnumberedCaption,
        MockupCode.fromString(mockupCodeShortSample, showLineNumbers: false),
      ),
    ]),
  ),
  'mockup-code/prefix-symbols': () => _box(
    _stack([
      _captioned(mockupCodeNoPrefixCaption, MockupCode.fromList(mockupCodeNoPrefixLines)),
      _captioned(mockupCodeEmptyPrefixCaption, MockupCode.fromList(mockupCodeEmptyPrefixLines)),
    ]),
  ),
  'mockup-code/tones': () => _box(MockupCode.fromList(mockupCodeToneLines)),
  'mockup-code/do-short': () => _box(
    width: mockupCodeCardWidth,
    MockupCode.fromString(mockupCodeShortSample),
  ),
  'mockup-code/dont-long': () => _box(
    width: mockupCodeCardWidth,
    MockupCode.fromString(mockupCodeLongLine),
  ),
  'mockup-code/do-tone-text': () => _box(
    width: mockupCodeCardWidth,
    MockupCode.fromList(mockupCodeToneWithTextLines),
  ),
  'mockup-code/dont-tone-only': () => _box(
    width: mockupCodeCardWidth,
    MockupCode.fromList(mockupCodeToneOnlyLines),
  ),
  'mockup-code/long-line': () => _box(MockupCode.fromString(mockupCodeClipSample)),
  'mockup-code/theming': () => _box(
    MockupCode.fromString(mockupCodeSample, mockupCodeStyle: mockupCodeThemedStyle),
  ),
  'mockup-code/related-mockup': () => MockupDevice(
    device: CoreMockupDevice.tablet,
    orientation: CoreMockupOrientation.landscape,
    width: mockupCodeCardDeviceWidth,
    child: _centered(const Text(mockupCodeCardScreenText).labelMedium.onSurface),
  ),
  'mockup-code/related-mockup-browser': () => _box(
    width: mockupCodeCardWidth,
    height: mockupCodeCardBrowserHeight,
    MockupBrowser(
      addressBar: mockupCodeCardAddress,
      child: _centered(const Text(mockupCodeCardScreenText).labelMedium.onSurface),
    ),
  ),
  'mockup-code/related-code-snippet': () => _box(
    width: mockupCodeCardWidth,
    const CodeSnippet(code: mockupCodeSnippetSource, mode: 'dart'),
  ),
  'mockup-code/related-code-diff': () => _box(
    width: mockupCodeCardWidth,
    const CodeDiff(lines: mockupCodeDiffLines),
  ),
};

Component _mockupCode(Map<String, String> props, String? label) =>
    _box(MockupCode.fromList(mockupCodePreviewLines(props)));

/// 폭(과 높이)을 정한 상자 — 좁은 자리에서는 폭이 함께 줄어든다.
Component _box(Component child, {double width = mockupCodeFrameWidth, double? height}) => div(
  styles: Styles(
    raw: {
      'width': pinnedLengthCss(width),
      'max-width': '100%',
      if (height != null) 'height': pinnedLengthCss(height),
    },
  ),
  [child],
);

/// 위에서 아래로 쌓는다.
Component _stack(List<Component> children) => div(
  styles: const Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': 'var(--coui-space-16)'}),
  children,
);

/// 위에 설명을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: const Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': 'var(--coui-space-8)'}),
  [Text(caption).labelSmall.onSurfaceVariant, child],
);

/// 틀 안의 가운데에 놓는다.
Component _centered(Component child) => div(
  styles: const Styles(
    raw: {'display': 'flex', 'align-items': 'center', 'justify-content': 'center', 'height': '100%'},
  ),
  [child],
);
