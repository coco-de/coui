import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'mockup_code.stories.g.dart';

// MockupCode widgetbook constants.
const _kSampleCode = "void main() {\n  print('Hello!');\n}";

/// Diff-style lines shown when the diff prefixes knob is enabled.
const _kDiffLines = [
  CoreCodeLine(text: 'void main() {', prefix: ' '),
  CoreCodeLine(text: "  print('Hello!');", prefix: '+'),
  CoreCodeLine(text: "  print('Old');", prefix: '-'),
  CoreCodeLine(text: '}', prefix: ' '),
];

/// Splits [code] into lines that all state [tone]; line numbers stay on.
List<CoreCodeLine> _toneLines(String code, CoreCodeLineTone tone) => [
  for (final (index, text) in code.split('\n').indexed)
    CoreCodeLine(text: text, prefix: '${index + 1}', tone: tone),
];

/// Knob input for [MockupCode] stories.
class MockupCodeInput {
  /// Creates a [MockupCodeInput].
  const MockupCodeInput({
    this.code = _kSampleCode,
    this.showLineNumbers = true,
    this.diffPrefixes = false,
    this.tone = CoreCodeLineTone.defaultTone,
  });

  /// Source code rendered in the mockup.
  final String code;

  /// Whether line numbers are shown.
  final bool showLineNumbers;

  /// Whether diff-style prefixes replace the code knob content.
  final bool diffPrefixes;

  /// Meaning every code line states — drawn with the tone colour slot.
  final CoreCodeLineTone tone;
}

/// Navigation metadata for the MockupCode component.
const kComponentMeta = ComponentMeta(name: 'MockupCode', path: 'display');

/// Story metadata for [MockupCode].
const kMeta = Meta(MockupCode.new, argsType: MockupCodeInput.new);

/// Default builder mapping [MockupCodeInput] args to a [MockupCode].
final MockupCodeDefaults defaults = _Defaults(
  builder: (context, args) => args.diffPrefixes
      ? MockupCode.fromList(_kDiffLines)
      : args.tone == CoreCodeLineTone.defaultTone
      ? MockupCode.fromString(
          args.code,
          showLineNumbers: args.showLineNumbers,
        )
      : MockupCode.fromList(_toneLines(args.code, args.tone)),
);

/// Code mockup with editable source and line-number knobs.
final $Default = _Story();

/// Code mockup with custom diff-style line prefixes.
final $CustomPrefixes = _Story(
  name: 'Custom Prefixes',
  args: _Args(diffPrefixes: BoolArg(true)),
);
