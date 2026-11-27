/// MockupCode 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `mockup_code_web.dart` · `mockup_code_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 둘이다: `tone`(마지막 줄의 뜻)과 `showLineNumbers`. 두 플랫폼의
/// 장면이 같은 글과 같은 폭을 쓰도록 그 값들을 이 파일에 둔다. Web 의
/// `MockupCode` 는 줄 앞의 공백을 그리지 않으므로 예시 줄에는 들여쓰기가
/// 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/mockup-code.md`.
const String slug = 'mockup-code';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// MockupCode 에는 크기 단계(`CoreComponentSize`)가 없다. 폭은 부모가,
/// 높이는 줄 수가 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `tone` → 마지막 줄의 뜻. 없거나 모르는 값은 기본값.
CoreCodeLineTone mockupCodePreviewTone(Map<String, String> props) =>
    previewEnum(CoreCodeLineTone.values, props['tone'], CoreCodeLineTone.defaultTone);

/// 속성의 `showLineNumbers`. 없으면 `MockupCode.fromString` 처럼 켠다.
bool mockupCodePreviewNumbers(Map<String, String> props) => previewFlag(props, 'showLineNumbers', fallback: true);

/// 플레이그라운드가 그리는 줄 — 마지막 줄만 고른 뜻을 가진다.
List<CoreCodeLine> mockupCodePreviewLines(Map<String, String> props) {
  final tone = mockupCodePreviewTone(props);
  final numbers = mockupCodePreviewNumbers(props);
  final texts = ['flutter pub get', 'flutter test', _toneSample(tone)];
  return [
    for (final (index, text) in texts.indexed)
      CoreCodeLine(
        text: text,
        prefix: numbers ? '${index + 1}' : null,
        tone: index == texts.length - 1 ? tone : CoreCodeLineTone.defaultTone,
      ),
  ];
}

/// 뜻마다의 예시 줄 — 색이 없어도 뜻이 읽히는 글을 쓴다.
String _toneSample(CoreCodeLineTone tone) => switch (tone) {
  CoreCodeLineTone.neutral => 'flutter run',
  CoreCodeLineTone.muted => '> flutter run',
  CoreCodeLineTone.link => 'http://localhost:8080',
  CoreCodeLineTone.success => 'All tests passed!',
  CoreCodeLineTone.warning => 'Warning: 2 unused imports',
  CoreCodeLineTone.error => 'Error: build failed',
};

/// 코드 틀 미리보기의 폭(logical px).
const double mockupCodeFrameWidth = 320;

/// 구조 그림의 폭 — 390px 화면에서도 번호가 무대 안에 놓이게 양옆을 비운다.
const double mockupCodeAnatomyWidth = 264;

/// 카드 안의 코드 틀 폭(logical px).
const double mockupCodeCardWidth = 240;

/// 카드 안의 태블릿 본체 폭(logical px) — 가로로 둔 틀.
const double mockupCodeCardDeviceWidth = 200;

/// 카드 안의 브라우저 창 높이(logical px).
const double mockupCodeCardBrowserHeight = 128;

/// 구조 · 테마 장면에 넣는 짧은 세 줄.
const String mockupCodeSample = 'flutter pub get\nflutter test\nflutter run';

/// 카드에 넣는 짧은 두 줄.
const String mockupCodeShortSample = 'flutter pub get\nflutter run';

/// `mockup-code/from-string` 장면의 두 설명.
const String mockupCodeNumberedCaption = 'showLineNumbers: true (기본값)';

/// [mockupCodeNumberedCaption] 참고.
const String mockupCodeUnnumberedCaption = 'showLineNumbers: false';

/// `mockup-code/prefix-symbols` 장면의 두 설명.
const String mockupCodeNoPrefixCaption = 'prefix 를 비운 줄';

/// [mockupCodeNoPrefixCaption] 참고.
const String mockupCodeEmptyPrefixCaption = "prefix: '' 를 준 줄";

/// 출력 줄에 `prefix` 가 없다 — 그 줄은 접두 열 자리에서 시작한다.
const List<CoreCodeLine> mockupCodeNoPrefixLines = [
  CoreCodeLine(text: 'flutter test', prefix: r'$'),
  CoreCodeLine(text: 'All tests passed!', tone: CoreCodeLineTone.success),
];

/// 출력 줄에 빈 `prefix` 를 준다 — 두 줄의 본문이 같은 자리에서 시작한다.
const List<CoreCodeLine> mockupCodeEmptyPrefixLines = [
  CoreCodeLine(text: 'flutter test', prefix: r'$'),
  CoreCodeLine(text: 'All tests passed!', prefix: '', tone: CoreCodeLineTone.success),
];

/// 여섯 가지 뜻을 한 번씩 보이는 줄.
const List<CoreCodeLine> mockupCodeToneLines = [
  CoreCodeLine(text: '> flutter run', prefix: '1', tone: CoreCodeLineTone.muted),
  CoreCodeLine(text: 'Building web application...', prefix: '2'),
  CoreCodeLine(text: 'http://localhost:8080', prefix: '3', tone: CoreCodeLineTone.link),
  CoreCodeLine(text: 'Built in 12.4s', prefix: '4', tone: CoreCodeLineTone.success),
  CoreCodeLine(text: '2 unused imports', prefix: '5', tone: CoreCodeLineTone.warning),
  CoreCodeLine(text: 'lib/main.dart:12 failed', prefix: '6', tone: CoreCodeLineTone.error),
];

/// 뜻이 글에도 담긴 줄.
const List<CoreCodeLine> mockupCodeToneWithTextLines = [
  CoreCodeLine(text: 'flutter build web', prefix: r'$', tone: CoreCodeLineTone.muted),
  CoreCodeLine(text: 'Error: build failed', prefix: '', tone: CoreCodeLineTone.error),
];

/// 뜻이 색에만 담긴 줄.
const List<CoreCodeLine> mockupCodeToneOnlyLines = [
  CoreCodeLine(text: 'web build', tone: CoreCodeLineTone.success),
  CoreCodeLine(text: 'ios build', tone: CoreCodeLineTone.error),
];

/// 틀보다 긴 한 줄 — 잘리는 모습을 보인다.
const String mockupCodeLongLine = 'flutter build web --release --base-href /docs/ --dart-define=FLAVOR=production';

/// 짧은 줄과 긴 줄을 함께 둔 두 줄.
const String mockupCodeClipSample = 'flutter pub get\n$mockupCodeLongLine';

/// `mockup-code/theming` 장면의 덮어쓰기 — 본문의 코드 예제와 같은 값이다.
const CoreMockupCodeStyle mockupCodeThemedStyle = CoreMockupCodeStyle(
  backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
  prefixTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.link)),
  lineSpacing: CoreSpace.space8,
  lineNumberWidth: CoreSize.size40,
);

/// 관련 컴포넌트 카드의 주소창 글.
const String mockupCodeCardAddress = 'example.com/docs';

/// 관련 컴포넌트 카드의 화면 글.
const String mockupCodeCardScreenText = '앱 화면';

/// `CodeSnippet` 카드의 코드 — 카드 폭에서 복사 버튼에 가리지 않는 길이.
const String mockupCodeSnippetSource = 'runApp(const App());';

/// `CodeDiff` 카드의 두 줄.
const List<CoreCodeDiffLine> mockupCodeDiffLines = [
  CoreCodeDiffLine(text: "title = 'Old';", type: CoreCodeDiffLineType.removed, lineNumber: 1),
  CoreCodeDiffLine(text: "title = 'New';", type: CoreCodeDiffLineType.added, lineNumber: 1),
];

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'tone': CoreCodeLineTone.defaultTone.name},
  controls: [
    DocsPlaygroundChoice(label: 'tone', prop: 'tone', options: [for (final t in CoreCodeLineTone.values) t.name]),
    const DocsPlaygroundFlag(label: '줄 번호 숨기기', on: {'showLineNumbers': 'false'}),
  ],
  code: _mockupCodeCode,
);

/// 뜻을 정한 줄이 있으면 `fromList`, 없으면 `fromString` 코드를 낸다.
String _mockupCodeCode(Map<String, String> props, String? label) {
  final lines = mockupCodePreviewLines(props);
  const note = '// 폭은 부모가 정합니다.';
  if (mockupCodePreviewTone(props) != CoreCodeLineTone.defaultTone) {
    return [
      note,
      'MockupCode.fromList(const [',
      for (final line in lines) '  ${_lineCode(line)},',
      '])',
    ].join('\n');
  }
  final source = [for (final line in lines) line.text].join(r'\n');
  if (mockupCodePreviewNumbers(props)) return "$note\nMockupCode.fromString('$source')";
  return [
    note,
    'MockupCode.fromString(',
    "  '$source',",
    '  showLineNumbers: false,',
    ')',
  ].join('\n');
}

String _lineCode(CoreCodeLine line) {
  final arguments = [
    "text: '${line.text}'",
    if (line.prefix != null) "prefix: '${line.prefix}'",
    if (line.tone != CoreCodeLineTone.defaultTone) 'tone: CoreCodeLineTone.${line.tone.name}',
  ];
  return 'CoreCodeLine(${arguments.join(', ')})';
}
