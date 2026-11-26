import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'tag.stories.g.dart';

/// Knob input for [Tag] stories.
class TagInput {
  /// Creates a [TagInput].
  const TagInput({
    this.text = 'Tag',
    this.color = CoreTagContract.defaultColor,
    this.emphasis = CoreTagEmphasis.defaultEmphasis,
    this.size = CoreTagSize.defaultSize,
  });

  /// Tag label text.
  final String text;

  /// Which category hue the tag wears.
  final CoreCategoryColor color;

  /// How loud the tag is — a tint with a line, or the solid fill.
  final CoreTagEmphasis emphasis;

  /// Which of the two steps the tag is drawn at.
  final CoreTagSize size;
}

/// Navigation metadata for the Tag component.
const kComponentMeta = ComponentMeta(name: 'Tag', path: 'display');

/// Story metadata for [Tag].
const kMeta = Meta(Tag.new, argsType: TagInput.new);

/// Default builder mapping [TagInput] args to a [Tag].
final TagDefaults defaults = _Defaults(
  builder: (context, args) => Tag(
    color: args.color,
    emphasis: args.emphasis,
    size: args.size,
    child: Text(args.text),
  ),
);

/// Every default — gray, subtle, md.
final $Default = _Story();

/// A category hue at the subtle emphasis.
final $Colored = _Story(
  args: _Args(
    text: StringArg('Design'),
    color: EnumArg(CoreCategoryColor.blue, values: CoreCategoryColor.values),
  ),
);

/// The bold emphasis — the hue's solid fill.
final $Bold = _Story(
  args: _Args(
    text: StringArg('New'),
    color: EnumArg(CoreCategoryColor.green, values: CoreCategoryColor.values),
    emphasis: EnumArg(CoreTagEmphasis.bold, values: CoreTagEmphasis.values),
  ),
);

/// The small step — for dense rows.
final $Small = _Story(
  args: _Args(
    color: EnumArg(CoreCategoryColor.purple, values: CoreCategoryColor.values),
    size: EnumArg(CoreTagSize.sm, values: CoreTagSize.values),
  ),
);
