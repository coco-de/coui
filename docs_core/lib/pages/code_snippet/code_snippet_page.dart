/// CodeSnippet 페이지 — 플레이그라운드와 두 플랫폼 장면이 함께 쓰는 예시 코드.
/// 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `code_snippet_web.dart` · `code_snippet_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/code-snippet.md`.
const String slug = 'code-snippet';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 플레이그라운드의 `mode` 선택지와 그 값에 보일 예시 코드. `bash` 는 문법이
/// 없는 값이 어떻게 보이는지를 보인다. 어느 예시든 세 줄 이상이라 줄 톤을
/// 켜면 2 · 3번째 줄에 띠가 놓인다. 첫 줄은 가장 긴 줄보다 넉넉히 짧게 둔다 —
/// 상자가 코드 폭일 때(Flutter) 복사 버튼이 첫 줄 끝과 겹치지 않는다.
const Map<String, String> codeSnippetSamples = {
  'dart': "void main() {\n  const name = 'CoUI';\n  print(name);\n}",
  'json': '{\n  "name": "coui",\n  "private": false\n}',
  'yaml': 'name: coui\nversion: 1.0.0\npublish_to: none',
  'sql': 'SELECT id, name\nFROM users\nWHERE active = true;',
  'bash': 'dart pub get\ndart format lib test\ndart test',
};

/// 속성의 `mode` — 선택지에 없는 값은 `dart`.
String codeSnippetPreviewMode(Map<String, String> props) =>
    codeSnippetSamples.containsKey(props['mode']) ? props['mode']! : 'dart';

/// 플레이그라운드와 `code-snippet/line-tones` 장면이 켜는 줄 톤.
const Map<int, CoreCodeLineTone> codeSnippetPreviewTones = {
  2: CoreCodeLineTone.success,
  3: CoreCodeLineTone.error,
};

/// 줄 톤 장면의 코드 — 3번째 줄에 오타가 있다.
const String codeSnippetToneSample = "void main() {\n  final greeting = 'Hello, CoUI!';\n  print(greting);\n}";

/// 구조 · 면 장면의 코드. 첫 줄이 짧아 복사 버튼과 겹치지 않는다.
const String codeSnippetHello = "void main() {\n  print('Hello, CoUI!');\n}";

/// 언어 장면 — `mode` 와 아래에 붙이는 설명.
const List<(String, String)> codeSnippetLanguageScenes = [
  ('json', 'json'),
  ('yaml', 'yaml'),
  ('sql', 'sql'),
  ('bash', 'bash — 문법이 없어 한 가지 색'),
];

/// 긴 줄 장면의 코드.
const String codeSnippetLongLine =
    "// 긴 줄\nfinal message = 'This line is longer than the box, so the code area scrolls sideways.';";

/// 높이 제한 장면의 코드와 높이(logical px).
const String codeSnippetTall =
    'enum Status {\n  draft,\n  review,\n  approved,\n  published,\n  archived,\n  deleted,\n}';

/// 높이 제한 장면의 `maxHeight`.
const double codeSnippetCappedHeight = 120;

/// 사용 가이드의 SQL 장면 코드.
const String codeSnippetQuery = 'SELECT id, name\nFROM users\nWHERE active = true;';

/// 사용 가이드의 줄바꿈 장면 코드 — 끝에 줄바꿈이 없다.
const String codeSnippetCommands = 'flutter pub get\nflutter run';

final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: const {'mode': 'dart', 'showLineNumbers': 'true', 'showCopyButton': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'mode', prop: 'mode', options: [...codeSnippetSamples.keys]),
    const DocsPlaygroundFlag(label: '줄 번호', on: {'showLineNumbers': 'true'}),
    const DocsPlaygroundFlag(label: '줄 톤', on: {'lineTones': 'true'}),
    const DocsPlaygroundFlag(label: '복사 버튼', on: {'showCopyButton': 'true'}),
  ],
  code: _codeSnippetCode,
);

/// 속성 → 코드. 기본값(`showLineNumbers: false` · `showCopyButton: true` · 빈
/// `lineTones`)은 적지 않는다. 여러 줄 문자열의 안쪽 줄은 들여쓰지 않는다 —
/// 들여쓰면 보여 줄 코드가 달라진다.
String _codeSnippetCode(Map<String, String> props, String? label) {
  final mode = codeSnippetPreviewMode(props);
  final lines = [
    "code: '''\n${codeSnippetSamples[mode]}''',",
    "mode: '$mode',",
    if (previewFlag(props, 'showLineNumbers')) 'showLineNumbers: true,',
    if (previewFlag(props, 'lineTones')) 'lineTones: {2: CoreCodeLineTone.success, 3: CoreCodeLineTone.error},',
    if (!previewFlag(props, 'showCopyButton')) 'showCopyButton: false,',
  ];
  return 'CodeSnippet(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
