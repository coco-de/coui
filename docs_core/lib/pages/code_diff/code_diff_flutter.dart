/// CodeDiff 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="code-diff/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`code_diff_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
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

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _codeDiff;

/// 장면 이름(`code-diff/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'code-diff/anatomy': () => _frame(const CodeDiff(lines: codeDiffAnatomyLines), width: 288),
  'code-diff/line-types': () => _frame(const CodeDiff(lines: codeDiffSaveLines)),
  'code-diff/line-numbers': () => _frame(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CodeDiff(lines: codeDiffSaveLines),
        const Text('showLineNumbers: true (기본값)').bodySmall.onSurfaceVariant,
        const Gap.space8(),
        const CodeDiff(lines: codeDiffSaveLines, showLineNumbers: false),
        const Text('showLineNumbers: false').bodySmall.onSurfaceVariant,
      ],
    ),
  ),
  'code-diff/wrap': () => _frame(const CodeDiff(lines: codeDiffWrapLines), width: 256),
  'code-diff/do-change': () => _frame(const CodeDiff(lines: codeDiffAnatomyLines), width: 288),
  'code-diff/dont-unchanged': () => _frame(const CodeDiff(lines: codeDiffUnchangedLines), width: 288),
  'code-diff/do-numbered': () => _frame(const CodeDiff(lines: codeDiffSaveLines), width: 288),
  'code-diff/dont-partial-number': () => _frame(const CodeDiff(lines: codeDiffPartialNumberLines), width: 288),
  'code-diff/style': () => _frame(const CodeDiff(lines: codeDiffSaveLines, codeDiffStyle: codeDiffOutlinedStyle)),
  'code-diff/related-code-snippet': () => _frame(
    const CodeSnippet(code: 'store.commit(data);', mode: 'dart'),
    width: 256,
  ),
  // 두 면은 색만 다르게 두고 이름표로 어느 쪽인지 알린다 — 가운데에 글을 두면
  // 분할선이 글을 가른다.
  'code-diff/related-diff': () => _frame(
    Diff(
      ariaLabel: '변경 전과 변경 후 비교',
      beforeLabel: const Text('전'),
      afterLabel: const Text('후'),
      before: _face(const CoreColor.token(CoreColors.surfaceContainerHighest)),
      after: _face(const CoreColor.token(CoreColors.surfaceContainer)),
    ),
    width: 256,
  ),
};

Widget _codeDiff(Map<String, String> props, String? label) {
  final lines = codeDiffPlaygroundLines(props);
  final showLineNumbers = previewFlag(props, 'showLineNumbers', fallback: true);
  return _frame(
    previewFlag(props, 'tappable')
        ? _TapPreview(lines: lines, showLineNumbers: showLineNumbers)
        : CodeDiff(lines: lines, showLineNumbers: showLineNumbers),
    width: 360,
  );
}

/// diff 의 가장 넓은 폭을 정한다. CodeDiff 는 받은 폭을 채우므로 폭이 정해진
/// 부모가 필요하다.
Widget _frame(Widget child, {double width = 384}) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: width),
  child: child,
);

/// Diff 장면의 한쪽 면 — 색 토큰 하나로 면 전체를 칠한다.
Widget _face(CoreColor color) => Builder(
  builder: (context) => ColoredBox(
    color: Theme.of(context).colorScheme.resolve(color).toValue(),
    child: const SizedBox.expand(),
  ),
);

/// 줄 누르기를 켠 미리보기 — 누른 줄을 diff 아래에 적는다.
class _TapPreview extends StatefulWidget {
  const _TapPreview({required this.lines, required this.showLineNumbers});

  final List<CoreCodeDiffLine> lines;
  final bool showLineNumbers;

  @override
  State<_TapPreview> createState() => _TapPreviewState();
}

class _TapPreviewState extends State<_TapPreview> {
  CoreCodeDiffLine? _tapped;

  @override
  void didUpdateWidget(covariant _TapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 속성이 바뀌면 줄이 새로 만들어지므로 앞서 누른 줄을 지운다.
    if (!identical(oldWidget.lines, widget.lines)) _tapped = null;
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CoreSpace.space8,
    children: [
      CodeDiff(
        lines: widget.lines,
        showLineNumbers: widget.showLineNumbers,
        onLineTap: (tapped) => setState(() => _tapped = tapped),
      ),
      Text(codeDiffTapCaption(_tapped)).bodySmall.onSurfaceVariant,
    ],
  );
}
