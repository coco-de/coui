import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'text_field.stories.g.dart';

const _kMaxLinesDefault = 1;
const _kMaxLengthDefault = 100;
const _kMultilineMaxLines = 5;

/// Interactive demo host for [TextField] stories.
///
/// Owns the [TextEditingController] so typed text survives rebuilds.
class TextFieldDemo extends StatefulWidget {
  /// Creates a [TextFieldDemo].
  const TextFieldDemo({
    super.key,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = _kMaxLinesDefault,
    this.maxLength = _kMaxLengthDefault,
    this.placeholder = '',
    this.hintText = '',
    this.showLeadingIcon = false,
    this.showTrailingIcon = false,
  });

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether the entered text is obscured.
  final bool obscureText;

  /// Maximum number of visible lines.
  final int maxLines;

  /// Maximum number of characters (enforced).
  final int maxLength;

  /// Placeholder text shown while empty (empty string hides it).
  final String placeholder;

  /// Hint text shown below the field (empty string hides it).
  final String hintText;

  /// Whether a leading search icon is shown.
  final bool showLeadingIcon;

  /// Whether a trailing clear icon is shown.
  final bool showTrailingIcon;

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      // `obscureText` is a mount-time seed, so the knob remounts the field
      // to take effect.
      key: ValueKey(widget.obscureText),
      onChanged: (value) {},
      placeholder: widget.placeholder.isEmpty ? null : Text(widget.placeholder),
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      prefix: widget.showLeadingIcon ? const Icon(LucideIcons.search) : null,
      suffix: widget.showTrailingIcon ? const Icon(LucideIcons.x) : null,
      hintText: widget.hintText.isEmpty ? null : widget.hintText,
      controller: _controller,
      maxLengthEnforcement: .enforced,
    );
  }
}

/// Navigation metadata for the TextField component.
const kComponentMeta = ComponentMeta(name: 'TextField', path: 'form');

/// Story metadata for [TextFieldDemo].
const kMeta = Meta(TextFieldDemo.new);

/// Single-line text field with state knobs.
final $Default = _Story();

/// Text field with a placeholder shown while empty.
final $WithPlaceholder = _Story(
  name: 'With Placeholder',
  args: _Args(placeholder: StringArg('Enter your name')),
);

/// Text field with a hint text below the field.
final $WithHint = _Story(
  name: 'With Hint',
  args: _Args(hintText: StringArg('Type here')),
);

/// Text field with leading and trailing icons.
final $WithIcons = _Story(
  name: 'With Icons',
  args: _Args(
    showLeadingIcon: BoolArg(true),
    // distinct story knobs share the same value.
    showTrailingIcon: BoolArg(true),
  ),
);

/// Multiline text field.
final $Multiline = _Story(
  args: _Args(
    maxLines: IntArg(_kMultilineMaxLines),
    placeholder: StringArg('Enter your message...'),
  ),
);
