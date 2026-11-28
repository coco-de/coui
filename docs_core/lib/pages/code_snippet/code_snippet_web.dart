/// CodeSnippet 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="code-snippet/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`code_snippet_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'code_snippet_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _codeSnippet;

/// 장면 이름(`code-snippet/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 줄 번호 · 액션 · 복사 버튼을 함께 그린다. 폭은 좁은 화면에서도
  // 번호 표시가 무대 안에 남게 정한다.
  'code-snippet/anatomy': () => _box(
    CodeSnippet(
      code: codeSnippetHello,
      mode: 'dart',
      showLineNumbers: true,
      actions: [
        Badge(attributes: const {'data-docs-part': 'actions'}, child: const Text('Dart')),
      ],
    ),
    width: 'min(20rem, calc(100vw - 8rem))',
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
  'code-snippet/long-line': () => _box(
    const CodeSnippet(code: codeSnippetLongLine, mode: 'dart'),
    width: 'min(100%, 20rem)',
  ),
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
    width: 'min(100%, 16rem)',
  ),
  'code-snippet/related-mockup-code': () => _box(
    const MockupCode(
      lines: [CoreCodeLine(text: 'flutter pub get', prefix: r'$')],
    ),
    width: 'min(100%, 16rem)',
  ),
  'code-snippet/related-kbd': () => const Kbd(keys: ['⌘', 'C']),
  'code-snippet/related-text': () => const Text('설정 파일을 열어 값을 바꿉니다.').bodyMedium,
};

Component _codeSnippet(Map<String, String> props, String? label) {
  final mode = codeSnippetPreviewMode(props);
  return _box(
    CodeSnippet(
      code: codeSnippetSamples[mode]!,
      mode: mode,
      showLineNumbers: previewFlag(props, 'showLineNumbers'),
      lineTones: previewFlag(props, 'lineTones') ? codeSnippetPreviewTones : const {},
      showCopyButton: previewFlag(props, 'showCopyButton'),
    ),
    width: '100%',
  );
}

/// 폭을 정한 상자. `min-width: 0` 이 있어야 긴 줄이 무대를 밀어내지 않고
/// 코드 영역 안에서 가로로 스크롤한다.
Component _box(Component child, {String width = 'min(100%, 24rem)'}) =>
    div(styles: Styles(raw: {'width': width, 'min-width': '0'}), [child]);

/// 스니펫마다 아래에 설명을 붙여 세로로 놓는다.
Component _captioned(List<(String, Component)> items) => _box(
  div(styles: _column('var(--coui-space-16)'), [
    for (final (caption, snippet) in items)
      div(styles: _column('var(--coui-space-6)'), [snippet, Text(caption).labelSmall.onSurfaceVariant]),
  ]),
);

/// 한 칸짜리 grid. 칸의 최소 폭이 0 이라 긴 줄이 칸을 늘리지 않는다.
Styles _column(String gap) => Styles(raw: {'display': 'grid', 'grid-template-columns': 'minmax(0, 1fr)', 'gap': gap});
