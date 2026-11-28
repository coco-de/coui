/// CodeDiff 페이지 — 플레이그라운드와 미리보기의 줄 데이터. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `code_diff_web.dart` · `code_diff_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// CodeDiff 의 모습은 넘긴 줄 데이터가 정하므로, 두 플랫폼이 같은 줄을
/// 그리도록 데이터를 이 파일에만 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/code-diff.md`.
const String slug = 'code-diff';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 플레이그라운드의 줄 — 셋째 줄의 종류(`type`)와 길이(`longLine`)를 속성에서
/// 읽는다. 두 플랫폼의 미리보기와 코드가 함께 쓴다.
List<CoreCodeDiffLine> codeDiffPlaygroundLines(Map<String, String> props) {
  final type = previewEnum(CoreCodeDiffLineType.values, props['type'], CoreCodeDiffLineType.added);
  // 추가한 줄은 지운 줄과 같은 번호를 쓴다 — 한 줄이 바뀐 모양이다.
  final number = type == CoreCodeDiffLineType.added ? 2 : 3;
  return [
    const CoreCodeDiffLine(text: 'void greet() {', type: CoreCodeDiffLineType.unchanged, lineNumber: 1),
    const CoreCodeDiffLine(text: "  print('Hi');", type: CoreCodeDiffLineType.removed, lineNumber: 2),
    CoreCodeDiffLine(
      text: previewFlag(props, 'longLine') ? "  print('Hello, it is good to see you again.');" : "  print('Hello');",
      type: type,
      lineNumber: number,
    ),
    CoreCodeDiffLine(text: '}', type: CoreCodeDiffLineType.unchanged, lineNumber: number + 1),
  ];
}

/// 플레이그라운드에서 줄 누르기를 켰을 때 diff 아래에 적는 글.
String codeDiffTapCaption(CoreCodeDiffLine? line) =>
    line == null ? '줄을 눌러 보세요' : '누른 줄 · ${line.lineNumber}번 · ${line.type.name}';

/// 구조 장면의 줄.
const List<CoreCodeDiffLine> codeDiffAnatomyLines = [
  CoreCodeDiffLine(text: 'total = price;', type: CoreCodeDiffLineType.removed, lineNumber: 12),
  CoreCodeDiffLine(text: 'total = price + tax;', type: CoreCodeDiffLineType.added, lineNumber: 12),
  CoreCodeDiffLine(text: 'return total;', type: CoreCodeDiffLineType.unchanged, lineNumber: 13),
];

/// 세 줄 종류가 모두 나오는 줄.
const List<CoreCodeDiffLine> codeDiffSaveLines = [
  CoreCodeDiffLine(text: 'void save() {', type: CoreCodeDiffLineType.unchanged, lineNumber: 1),
  CoreCodeDiffLine(text: '  store.write(data);', type: CoreCodeDiffLineType.removed, lineNumber: 2),
  CoreCodeDiffLine(text: '  store.commit(data);', type: CoreCodeDiffLineType.added, lineNumber: 2),
  CoreCodeDiffLine(text: '}', type: CoreCodeDiffLineType.unchanged, lineNumber: 3),
];

/// 일부 줄에만 번호를 준 줄 — 번호 칸이 없는 줄이 왼쪽으로 당겨진다.
const List<CoreCodeDiffLine> codeDiffPartialNumberLines = [
  CoreCodeDiffLine(text: 'void save() {', type: CoreCodeDiffLineType.unchanged, lineNumber: 1),
  CoreCodeDiffLine(text: '  store.write(data);', type: CoreCodeDiffLineType.removed),
  CoreCodeDiffLine(text: '  store.commit(data);', type: CoreCodeDiffLineType.added, lineNumber: 2),
  CoreCodeDiffLine(text: '}', type: CoreCodeDiffLineType.unchanged, lineNumber: 3),
];

/// 바뀐 줄이 하나도 없는 줄 — 쓰지 말아야 할 모습.
const List<CoreCodeDiffLine> codeDiffUnchangedLines = [
  CoreCodeDiffLine(text: 'void save() {', type: CoreCodeDiffLineType.unchanged, lineNumber: 1),
  CoreCodeDiffLine(text: '  store.commit(data);', type: CoreCodeDiffLineType.unchanged, lineNumber: 2),
  CoreCodeDiffLine(text: '}', type: CoreCodeDiffLineType.unchanged, lineNumber: 3),
];

/// 좁은 폭에서 줄이 바뀌는 모습을 보는 긴 줄.
const List<CoreCodeDiffLine> codeDiffWrapLines = [
  CoreCodeDiffLine(text: 'final user = loadUser();', type: CoreCodeDiffLineType.unchanged, lineNumber: 7),
  CoreCodeDiffLine(
    text: 'final greeting = buildGreeting(user.name, user.locale, DateTime.now());',
    type: CoreCodeDiffLineType.added,
    lineNumber: 8,
  ),
  CoreCodeDiffLine(text: 'show(greeting);', type: CoreCodeDiffLineType.unchanged, lineNumber: 9),
];

/// `codeDiffStyle` 장면의 값 — 본문의 "하나만 바꾸기" 예제와 같다.
const CoreCodeDiffStyle codeDiffOutlinedStyle = CoreCodeDiffStyle(
  borderWidth: CoreStrokeWidth.stroke1,
  outlineColor: CoreColor.token(CoreColors.outlineVariant),
  linePadding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8, vertical: CoreSpace.space2),
);

// 종류 선택지는 enum 에서 읽는다 — 줄 종류가 늘면 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'type': CoreCodeDiffLineType.added.name},
  controls: [
    DocsPlaygroundChoice(
      label: '셋째 줄 type',
      prop: 'type',
      options: [for (final type in CoreCodeDiffLineType.values) type.name],
    ),
    const DocsPlaygroundFlag(label: '긴 줄', on: {'longLine': 'true'}),
    const DocsPlaygroundFlag(label: '줄 번호 숨기기', on: {'showLineNumbers': 'false'}),
    const DocsPlaygroundFlag(label: '줄 누르기', on: {'tappable': 'true'}),
  ],
  code: _codeDiffCode,
);

/// 속성 → 코드. 기본값인 `showLineNumbers: true` 는 적지 않는다. 두 플랫폼의
/// 코드가 같다.
String _codeDiffCode(Map<String, String> props, String? label) => [
  'CodeDiff(',
  '  lines: const [',
  for (final line in codeDiffPlaygroundLines(props)) ...[
    '    CoreCodeDiffLine(',
    '      text: ${_dartString(line.text)},',
    '      type: CoreCodeDiffLineType.${line.type.name},',
    '      lineNumber: ${line.lineNumber},',
    '    ),',
  ],
  '  ],',
  if (!previewFlag(props, 'showLineNumbers', fallback: true)) '  showLineNumbers: false,',
  if (previewFlag(props, 'tappable')) '  onLineTap: openLine,',
  ')',
].join('\n');

/// 플레이그라운드의 줄을 Dart 문자열 리터럴로 적는다. 줄 데이터에는 `$` 와
/// 역슬래시가 없고, 작은따옴표가 있으면 큰따옴표로 감싼다.
String _dartString(String text) => text.contains("'") ? '"$text"' : "'$text'";
