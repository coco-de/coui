import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'code_diff.stories.g.dart';

/// Sample diff lines rendered by every [CodeDiff] story.
const _kSampleLines = [
  CoreCodeDiffLine(
    text: "import 'package:coui_flutter/coui_flutter.dart';",
    type: .unchanged,
    lineNumber: 1,
  ),
  CoreCodeDiffLine(
    text: 'class MyWidget extends StatelessWidget {',
    type: .unchanged,
    lineNumber: 2,
  ),
  CoreCodeDiffLine(
    text: "    return Text('Hello');",
    type: .removed,
    lineNumber: 3,
  ),
  CoreCodeDiffLine(
    text: "    return Text('Hello').bodyMedium;",
    type: .added,
    lineNumber: 3,
  ),
  CoreCodeDiffLine(
    text: '  }',
    type: .unchanged,
    lineNumber: 4,
  ),
  CoreCodeDiffLine(
    text: '}',
    type: .unchanged,
    lineNumber: 5,
  ),
];

/// Knob input for [CodeDiff] stories.
class CodeDiffInput {
  /// Creates a [CodeDiffInput].
  const CodeDiffInput({this.showLineNumbers = true});

  /// Whether the line-number gutter is shown.
  final bool showLineNumbers;
}

/// Navigation metadata for the CodeDiff component.
const kComponentMeta = ComponentMeta(name: 'CodeDiff', path: 'display');

/// Story metadata for [CodeDiff].
const kMeta = Meta(CodeDiff.new, argsType: CodeDiffInput.new);

/// Default builder mapping [CodeDiffInput] args to a [CodeDiff].
final CodeDiffDefaults defaults = _Defaults(
  builder: (context, args) => CodeDiff(
    lines: _kSampleLines,
    showLineNumbers: args.showLineNumbers,
  ),
);

/// Diff with a line-number gutter.
final $Default = _Story();

/// Diff without a line-number gutter.
final $WithoutLineNumbers = _Story(
  name: 'Without Line Numbers',
  args: _Args(showLineNumbers: BoolArg(false)),
);

/// Line-tap host so the opt-in callback can be exercised in Widgetbook.
class CodeDiffLineTapDemo extends StatefulWidget {
  /// Creates a [CodeDiffLineTapDemo].
  const CodeDiffLineTapDemo({super.key});

  @override
  State<CodeDiffLineTapDemo> createState() => _CodeDiffLineTapDemoState();
}

class _CodeDiffLineTapDemoState extends State<CodeDiffLineTapDemo> {
  String? _last;

  @override
  Widget build(BuildContext context) {
    final last = _last;
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        CodeDiff(
          lines: _kSampleLines,
          onLineTap: (line) => setState(() => _last = line.text),
        ),
        if (last != null) ...[
          const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
          Text('Tapped: $last').bodySmall().onSurface(),
        ],
      ],
    );
  }
}
