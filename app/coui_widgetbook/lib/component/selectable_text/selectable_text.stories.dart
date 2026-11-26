import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'selectable_text.stories.g.dart';

/// Knob input for [SelectableText] stories.
class SelectableTextInput {
  /// Creates a [SelectableTextInput].
  const SelectableTextInput({
    this.text =
        'This text can be selected. Try clicking and dragging to select it.',
    this.enableInteractiveSelection = true,
    this.showCursor = false,
  });

  /// Selectable text content.
  final String text;

  /// Whether click-and-drag selection is enabled.
  final bool enableInteractiveSelection;

  /// Whether a cursor is shown inside the text.
  final bool showCursor;
}

/// Navigation metadata for the SelectableText component.
const kComponentMeta = ComponentMeta(name: 'SelectableText', path: 'text');

/// Story metadata for [SelectableText].
const kMeta = Meta(SelectableText.new, argsType: SelectableTextInput.new);

/// Default builder mapping [SelectableTextInput] args to a
/// [SelectableText].
final SelectableTextDefaults defaults = _Defaults(
  setup: (context, child, args) => Padding(
    padding: const .all(CoreSpace.space16),
    child: child,
  ),
  builder: (context, args) => SelectableText(
    args.text,
    enableInteractiveSelection: args.enableInteractiveSelection,
    showCursor: args.showCursor,
  ),
);

/// Selectable text with editable knobs.
final $Default = _Story();
