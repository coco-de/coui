import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCodeDiffStyle] slot without constructing the component
/// from scratch.
class CodeDiffChainExample extends StatelessComponent {
  const CodeDiffChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const CodeDiff(
      lines: [
        CoreCodeDiffLine(
          text: "import 'package:coui_web/coui_web.dart';",
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 1,
        ),
        CoreCodeDiffLine(
          text: '',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 2,
        ),
        CoreCodeDiffLine(
          text: 'class MyWidget extends StatelessComponent {',
          type: CoreCodeDiffLineType.unchanged,
          lineNumber: 3,
        ),
        CoreCodeDiffLine(
          text: '  Component build(BuildContext context) {',
          type: CoreCodeDiffLineType.removed,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: '  Component build(BuildContext context) {',
          type: CoreCodeDiffLineType.added,
          lineNumber: 4,
        ),
        CoreCodeDiffLine(
          text: "    return text('Hello');",
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
}
