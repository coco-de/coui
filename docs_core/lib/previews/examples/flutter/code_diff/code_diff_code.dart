String codeDiffCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
class CodeDiffChainExample extends StatelessWidget {
  const CodeDiffChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const CodeDiff(
      lines: [
        CoreCodeDiffLine(
          text: "import 'package:coui_flutter/coui_flutter.dart';",
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 1,
        ),
        CoreCodeDiffLine(
          text: '',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 2,
        ),
        CoreCodeDiffLine(
          text: 'class MyWidget extends StatelessWidget {',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 3,
        ),
        CoreCodeDiffLine(
          text: '  Widget build(BuildContext context) {',
          type: CoreCodeDiffLineType.removed,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: '  Widget build(BuildContext context) {',
          type: CoreCodeDiffLineType.added,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: "    return Text('Hello');",
          type: CoreCodeDiffLineType.removed,
          lineNumber: 5,
        ),
        CoreCodeDiffLine(
          text: "    return Text('Hello').bodyMedium;",
          type: CoreCodeDiffLineType.added,
          lineNumber: 5,
        ),
        CoreCodeDiffLine(
          text: '  }',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 6,
        ),
        CoreCodeDiffLine(
          text: '}',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 7,
        ),
      ],
    ).withStyle(
      const CoreCodeDiffStyle(
        cornerRadius: CoreBorderRadius.all(CoreRadius.radius4),
        borderWidth: CoreStrokeWidth.stroke2,
        outlineColor: CoreColor.token(CoreColors.primary),
        addedBackgroundColor: CoreColor.token(CoreColors.infoContainer),
        addedForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
        removedBackgroundColor: CoreColor.token(CoreColors.warningContainer),
        removedForegroundColor: CoreColor.token(CoreColors.onWarningContainer),
        linePadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space4,
        ),
      ),
    );
  }
}''',
    _ =>
      r'''
class CodeDiffDefaultExample extends StatelessWidget {
  const CodeDiffDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const CodeDiff(
      lines: [
        CoreCodeDiffLine(
          text: "import 'package:coui_flutter/coui_flutter.dart';",
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 1,
        ),
        CoreCodeDiffLine(
          text: '',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 2,
        ),
        CoreCodeDiffLine(
          text: 'class MyWidget extends StatelessWidget {',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 3,
        ),
        CoreCodeDiffLine(
          text: '  Widget build(BuildContext context) {',
          type: CoreCodeDiffLineType.removed,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: '  Widget build(BuildContext context) {',
          type: CoreCodeDiffLineType.added,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: "    return Text('Hello');",
          type: CoreCodeDiffLineType.removed,
          lineNumber: 5,
        ),
        CoreCodeDiffLine(
          text: "    return Text('Hello').bodyMedium;",
          type: CoreCodeDiffLineType.added,
          lineNumber: 5,
        ),
        CoreCodeDiffLine(
          text: '  }',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 6,
        ),
        CoreCodeDiffLine(
          text: '}',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 7,
        ),
      ],
    );
  }
}''',
  };
}
