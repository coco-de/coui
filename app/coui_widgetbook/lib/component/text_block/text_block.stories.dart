import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'text_block.stories.g.dart';

const _kPreviewWidth = 360.0;
const _kBodyText =
    'Body copy renders with the paragraph role and its semantic typography.';

/// Typography preset applied to a [TextBlock].
enum TextBlockPresetOption {
  /// Bold emphasis preset.
  bold,

  /// Inline code preset.
  inlineCode,

  /// Italic emphasis preset.
  italic,

  /// Lead paragraph preset.
  lead,

  /// Muted (subdued color) preset.
  muted,

  /// No preset — plain semantic element typography.
  none,
}

/// Knob input for [TextBlock] stories.
class TextBlockInput {
  /// Creates a [TextBlockInput].
  const TextBlockInput({
    this.text = _kBodyText,
    this.element = CoreTextBlockElement.p,
    this.preset = TextBlockPresetOption.none,
  });

  /// Text content to render.
  final String text;

  /// Semantic element role.
  final CoreTextBlockElement element;

  /// Typography preset applied on top of the element role.
  final TextBlockPresetOption preset;
}

/// Navigation metadata for the TextBlock component.
const kComponentMeta = ComponentMeta(name: 'TextBlock', path: 'text');

/// Story metadata for [TextBlock].
const kMeta = Meta(TextBlock.new, argsType: TextBlockInput.new);

/// Default builder mapping [TextBlockInput] args to a [TextBlock].
final TextBlockDefaults defaults = _Defaults(
  setup: (context, child, args) =>
      SizedBox(width: _kPreviewWidth, child: child),
  builder: (context, args) => TextBlock(
    text: args.text,
    element: args.element,
    presets: switch (args.preset) {
      .none => null,
      .bold => const [TextBlock.bold],
      .italic => const [TextBlock.italic],
      .muted => [TextBlock.muted(context)],
      .lead => [TextBlock.lead(context)],
      .inlineCode => [TextBlock.inlineCode(context)],
    },
  ),
);

/// Paragraph body copy with element and preset knobs.
final $Default = _Story();

/// Heading (h3) semantic element.
final $Heading = _Story(
  args: _Args(
    text: StringArg('Document Title'),
    element: EnumArg(
      CoreTextBlockElement.h3,
      values: CoreTextBlockElement.values,
    ),
  ),
);

/// Blockquote semantic element.
final $Blockquote = _Story(
  args: _Args(
    element: EnumArg(
      CoreTextBlockElement.blockquote,
      values: CoreTextBlockElement.values,
    ),
  ),
);

/// Bold emphasis preset.
final $Bold = _Story(
  args: _Args(
    text: StringArg('Bold emphasis'),
    preset: EnumArg(
      TextBlockPresetOption.bold,
      values: TextBlockPresetOption.values,
    ),
  ),
);

/// Italic emphasis preset.
final $Italic = _Story(
  args: _Args(
    text: StringArg('Italic emphasis'),
    preset: EnumArg(
      TextBlockPresetOption.italic,
      values: TextBlockPresetOption.values,
    ),
  ),
);

/// Muted subtitle preset.
final $Muted = _Story(
  args: _Args(
    text: StringArg('A muted subtitle'),
    preset: EnumArg(
      TextBlockPresetOption.muted,
      values: TextBlockPresetOption.values,
    ),
  ),
);

/// Lead paragraph preset.
final $Lead = _Story(
  args: _Args(
    text: StringArg('A lead paragraph introduces the section.'),
    preset: EnumArg(
      TextBlockPresetOption.lead,
      values: TextBlockPresetOption.values,
    ),
  ),
);

/// Inline code preset.
final $InlineCode = _Story(
  name: 'Inline Code',
  args: _Args(
    text: StringArg('inlineCodeSnippet()'),
    preset: EnumArg(
      TextBlockPresetOption.inlineCode,
      values: TextBlockPresetOption.values,
    ),
  ),
);
