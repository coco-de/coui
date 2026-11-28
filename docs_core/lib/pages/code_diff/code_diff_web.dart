/// CodeDiff 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="code-diff/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`code_diff_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'code_diff_page.dart'
    show
        codeDiffAnatomyLines,
        codeDiffOutlinedStyle,
        codeDiffPartialNumberLines,
        codeDiffPlaygroundLines,
        codeDiffSaveLines,
        codeDiffTapCaption,
        codeDiffUnchangedLines,
        codeDiffWrapLines;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _codeDiff;

/// 장면 이름(`code-diff/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 구조 표시를 감싼 상자는 내용 폭이라, 폭을 화면에서 뺀 값으로 묶는다.
  'code-diff/anatomy': () => div(
    styles: Styles(raw: {'width': 'min(18rem, calc(100vw - 8rem))'}),
    [const CodeDiff(lines: codeDiffAnatomyLines)],
  ),
  'code-diff/line-types': () => _frame(const CodeDiff(lines: codeDiffSaveLines)),
  'code-diff/line-numbers': () => _stack([
    const CodeDiff(lines: codeDiffSaveLines),
    const Text('showLineNumbers: true (기본값)').bodySmall.onSurfaceVariant,
    const Gap.space8(),
    const CodeDiff(lines: codeDiffSaveLines, showLineNumbers: false),
    const Text('showLineNumbers: false').bodySmall.onSurfaceVariant,
  ]),
  'code-diff/wrap': () => _frame(const CodeDiff(lines: codeDiffWrapLines), width: '16rem'),
  'code-diff/do-change': () => _frame(const CodeDiff(lines: codeDiffAnatomyLines), width: '18rem'),
  'code-diff/dont-unchanged': () => _frame(const CodeDiff(lines: codeDiffUnchangedLines), width: '18rem'),
  'code-diff/do-numbered': () => _frame(const CodeDiff(lines: codeDiffSaveLines), width: '18rem'),
  'code-diff/dont-partial-number': () => _frame(const CodeDiff(lines: codeDiffPartialNumberLines), width: '18rem'),
  'code-diff/style': () => _frame(const CodeDiff(lines: codeDiffSaveLines, codeDiffStyle: codeDiffOutlinedStyle)),
  'code-diff/related-code-snippet': () => _frame(
    const CodeSnippet(code: 'store.commit(data);', mode: 'dart'),
    width: '16rem',
  ),
  // 두 면은 색만 다르게 두고 이름표로 어느 쪽인지 알린다 — 가운데에 글을 두면
  // 분할선이 글을 가른다.
  'code-diff/related-diff': () => _frame(
    Diff(
      ariaLabel: '변경 전과 변경 후 비교',
      beforeLabel: const Text('전'),
      afterLabel: const Text('후'),
      before: div(classes: 'w-full h-full bg-surface-container-highest', const []),
      after: div(classes: 'w-full h-full bg-surface-container', const []),
    ),
    width: '16rem',
  ),
};

Component _codeDiff(Map<String, String> props, String? label) {
  final lines = codeDiffPlaygroundLines(props);
  final showLineNumbers = previewFlag(props, 'showLineNumbers', fallback: true);
  return _frame(
    previewFlag(props, 'tappable')
        ? _TapPreview(lines: lines, showLineNumbers: showLineNumbers)
        : CodeDiff(lines: lines, showLineNumbers: showLineNumbers),
    width: '20rem',
  );
}

/// 무대 안에서 diff 의 폭을 정한다 — 무대는 flex 라 그대로 두면 diff 가 내용
/// 폭이 된다.
Component _frame(Component child, {String width = '24rem'}) =>
    div(styles: Styles(raw: {'width': 'min($width, 100%)'}), [child]);

/// diff 와 설명을 위에서 아래로 놓는다.
Component _stack(List<Component> children) => div(
  classes: 'flex flex-col',
  styles: Styles(raw: {'width': 'min(24rem, 100%)'}),
  children,
);

/// 줄 누르기를 켠 미리보기 — 누른 줄을 diff 아래에 적는다.
class _TapPreview extends StatefulComponent {
  const _TapPreview({required this.lines, required this.showLineNumbers});

  final List<CoreCodeDiffLine> lines;
  final bool showLineNumbers;

  @override
  State<_TapPreview> createState() => _TapPreviewState();
}

class _TapPreviewState extends State<_TapPreview> {
  CoreCodeDiffLine? _tapped;

  @override
  void didUpdateComponent(covariant _TapPreview oldComponent) {
    super.didUpdateComponent(oldComponent);
    // 속성이 바뀌면 줄이 새로 만들어지므로 앞서 누른 줄을 지운다.
    if (!identical(oldComponent.lines, component.lines)) _tapped = null;
  }

  @override
  Component build(BuildContext context) => div(classes: 'flex flex-col', [
    CodeDiff(
      lines: component.lines,
      showLineNumbers: component.showLineNumbers,
      onLineTap: (tapped) => setState(() => _tapped = tapped),
    ),
    const Gap.space8(),
    Text(codeDiffTapCaption(_tapped)).bodySmall.onSurfaceVariant,
  ]);
}
