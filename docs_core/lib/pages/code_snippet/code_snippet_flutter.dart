/// CodeSnippet 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="code-snippet/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`code_snippet_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 모든 장면은 폭의 상한만 주고 폭을 강제하지 않는다. 폭을 강제하면 상자는
/// 코드 폭에 머무는데 복사 버튼은 강제된 폭의 끝에 놓인다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'code_snippet_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _codeSnippet;

/// 장면 이름(`code-snippet/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'code-snippet/anatomy': () => _box(
    const CodeSnippet(
      code: codeSnippetHello,
      mode: 'dart',
      showLineNumbers: true,
      actions: [Badge(child: Text('Dart'))],
    ),
    width: 320,
  ),
  'code-snippet/languages': () => _captioned([
    for (final (mode, caption) in codeSnippetLanguageScenes)
      (caption, CodeSnippet(code: codeSnippetSamples[mode]!, mode: mode, showCopyButton: false)),
  ]),
  'code-snippet/faces': () => _captioned([
    ('기본 면 — 강조 켜짐', const CodeSnippet(code: codeSnippetHello, mode: 'dart', showLineNumbers: true)),
    (
      'surfaceContainer — 강조 켜짐',
      const CodeSnippet(code: codeSnippetHello, mode: 'dart', showLineNumbers: true).surfaceContainer,
    ),
    (
      'primary — 강조 꺼짐, 번호와 글리프는 onPrimary',
      const CodeSnippet(code: codeSnippetHello, mode: 'dart', showLineNumbers: true).primary,
    ),
  ]),
  'code-snippet/line-tones': () => _box(
    const CodeSnippet(
      code: codeSnippetToneSample,
      mode: 'dart',
      showLineNumbers: true,
      lineTones: codeSnippetPreviewTones,
    ),
  ),
  'code-snippet/long-line': () => _box(const CodeSnippet(code: codeSnippetLongLine, mode: 'dart'), width: 320),
  'code-snippet/max-height': () => _box(
    const CodeSnippet(
      code: codeSnippetTall,
      mode: 'dart',
      showLineNumbers: true,
      showCopyButton: false,
      codeSnippetStyle: CoreCodeSnippetStyle(maxHeight: codeSnippetCappedHeight),
    ),
  ),
  'code-snippet/do-mode': () => _box(const CodeSnippet(code: codeSnippetQuery, mode: 'sql', showCopyButton: false)),
  'code-snippet/dont-mode': () => _box(const CodeSnippet(code: codeSnippetQuery, mode: 'SQL', showCopyButton: false)),
  'code-snippet/do-trim': () => _box(
    const CodeSnippet(code: codeSnippetCommands, mode: 'bash', showLineNumbers: true, showCopyButton: false),
  ),
  'code-snippet/dont-trim': () => _box(
    const CodeSnippet(code: '$codeSnippetCommands\n', mode: 'bash', showLineNumbers: true, showCopyButton: false),
  ),
  'code-snippet/related-code-diff': () => _box(
    const CodeDiff(
      lines: [
        CoreCodeDiffLine(text: 'final count = 1;', type: CoreCodeDiffLineType.removed, lineNumber: 1),
        CoreCodeDiffLine(text: 'final count = 2;', type: CoreCodeDiffLineType.added, lineNumber: 1),
      ],
    ),
    width: 256,
  ),
  'code-snippet/related-mockup-code': () => _box(
    const MockupCode(
      lines: [CoreCodeLine(text: 'flutter pub get', prefix: r'$')],
    ),
    width: 256,
  ),
  'code-snippet/related-kbd': () => const Kbd(keys: ['⌘', 'C']),
  'code-snippet/related-text': () => const Text('설정 파일을 열어 값을 바꿉니다.').bodyMedium,
};

Widget _codeSnippet(Map<String, String> props, String? label) {
  final mode = codeSnippetPreviewMode(props);
  return _box(
    CodeSnippet(
      code: codeSnippetSamples[mode]!,
      mode: mode,
      showLineNumbers: previewFlag(props, 'showLineNumbers'),
      lineTones: previewFlag(props, 'lineTones') ? codeSnippetPreviewTones : const {},
      showCopyButton: previewFlag(props, 'showCopyButton'),
    ),
    width: 320,
  );
}

/// 폭의 상한을 정한 상자.
Widget _box(Widget child, {double width = 384}) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: width),
  child: child,
);

/// 스니펫마다 아래에 설명을 붙여 세로로 놓는다.
Widget _captioned(List<(String, Widget)> items) => _box(
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space16,
    children: [
      for (final (caption, snippet) in items)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space6,
          children: [snippet, Text(caption).labelSmall.onSurfaceVariant],
        ),
    ],
  ),
);
