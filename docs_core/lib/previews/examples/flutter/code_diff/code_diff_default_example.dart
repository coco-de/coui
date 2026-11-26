import 'package:coui_flutter/coui_flutter.dart';

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
}
