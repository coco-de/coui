import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'text_area.stories.g.dart';

const _kInitialHeight = 150.0;
const _kMaxHeight = 400.0;

/// Interactive demo host for [TextArea] stories.
///
/// Owns the [TextEditingController] so typed text survives rebuilds.
class TextAreaDemo extends StatefulWidget {
  /// Creates a [TextAreaDemo].
  const TextAreaDemo({
    super.key,
    this.enabled = true,
    this.readOnly = false,
    this.expandableHeight = true,
    this.expandableWidth = false,
    this.placeholder = 'Enter your message...',
  });

  /// Whether the text area accepts input.
  final bool enabled;

  /// Whether the text area is read-only.
  final bool readOnly;

  /// Whether the height can be resized by dragging.
  final bool expandableHeight;

  /// Whether the width can be resized by dragging.
  final bool expandableWidth;

  /// Placeholder text shown while empty.
  final String placeholder;

  @override
  State<TextAreaDemo> createState() => _TextAreaDemoState();
}

class _TextAreaDemoState extends State<TextAreaDemo> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextArea(
      placeholder: widget.placeholder,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      textAreaStyle: const CoreTextAreaStyle(
        initialHeight: _kInitialHeight,
        maxHeight: _kMaxHeight,
      ),
      expandableHeight: widget.expandableHeight,
      expandableWidth: widget.expandableWidth,
      controller: _controller,
    );
  }
}

/// Navigation metadata for the TextArea component.
const kComponentMeta = ComponentMeta(name: 'TextArea', path: 'form');

/// Story metadata for [TextAreaDemo].
const kMeta = Meta(TextAreaDemo.new);

/// Resizable text area with state knobs.
final $Default = _Story();
