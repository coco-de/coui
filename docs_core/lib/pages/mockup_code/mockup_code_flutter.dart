/// MockupCode 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="mockup-code/...">` 가
/// 읽는다. 같은 이름의 Web 파일(`mockup_code_web.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
///
/// Flutter 의 `MockupCode` 는 부모의 폭을 채우므로 폭이 정해진 부모가
/// 필요하다. 장면은 폭을 정한 상자 안에 둔다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'mockup_code_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _mockupCode;

/// 장면 이름(`mockup-code/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
    child: Center(child: const Text(mockupCodeCardScreenText).labelMedium.onSurface),
  ),
  'mockup-code/related-mockup-browser': () => _box(
    width: mockupCodeCardWidth,
    height: mockupCodeCardBrowserHeight,
    MockupBrowser(
      addressBar: mockupCodeCardAddress,
      child: Center(child: const Text(mockupCodeCardScreenText).labelMedium.onSurface),
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

Widget _mockupCode(Map<String, String> props, String? label) =>
    _box(MockupCode.fromList(mockupCodePreviewLines(props)));

/// 폭(과 높이)을 정한 상자 — 좁은 자리에서는 폭이 함께 줄어든다.
Widget _box(Widget child, {double width = mockupCodeFrameWidth, double? height}) =>
    SizedBox(width: width, height: height, child: child);

/// 위에서 아래로 쌓는다.
Widget _stack(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space16,
  children: children,
);

/// 위에 설명을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: [Text(caption).labelSmall.onSurfaceVariant, child],
);
