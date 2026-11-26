import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'formatted_input.stories.g.dart';

const _kContentWidth = 300.0;
const _kPartLength = 2;
const _kDigitsPattern = r'\d';
const _kEmptyValue = '';

/// Mask presets selectable in [FormattedInputDemo].
enum FormattedInputFormat {
  /// Date mask: `__/__/____`.
  date,

  /// Time mask: `__:__`.
  time,
}

/// Interactive demo host for [FormattedInput] stories.
class FormattedInputDemo extends StatefulWidget {
  /// Creates a [FormattedInputDemo].
  const FormattedInputDemo({
    super.key,
    this.format = FormattedInputFormat.date,
  });

  /// Mask preset applied to the input.
  final FormattedInputFormat format;

  @override
  State<FormattedInputDemo> createState() => _FormattedInputDemoState();
}

class _FormattedInputDemoState extends State<FormattedInputDemo> {
  String _value = _kEmptyValue;

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) {
    final fiStrings = t.widgetbook.formatted_input;
    final formatLabel = switch (widget.format) {
      .date => fiStrings.date_format,
      .time => fiStrings.time_format,
    };
    final input = switch (widget.format) {
      .date => FormattedInput.date(
        onChanged: handleChanged,
      ),
      .time => FormattedInput(
        onChanged: handleChanged,
        parts: const [
          CoreFormattedInputPart.editable(
            length: _kPartLength,
            pattern: _kDigitsPattern,
          ),
          CoreFormattedInputPart.static(':'),
          CoreFormattedInputPart.editable(
            length: _kPartLength,
            pattern: _kDigitsPattern,
          ),
        ],
      ),
    };

    return SizedBox(
      width: _kContentWidth,
      child: Column(
        mainAxisSize: .min,
        spacing: CoreSpace.space16,
        children: [
          Text(formatLabel).bodySmall().onSurface(),
          input,
          Text(
            fiStrings.current_value(value: _value),
          ).bodySmall().onSurface(),
        ],
      ),
    );
  }
}

/// Navigation metadata for the FormattedInput component.
const kComponentMeta = ComponentMeta(name: 'FormattedInput', path: 'form');

/// Story metadata for [FormattedInputDemo].
const kMeta = Meta(FormattedInputDemo.new);

/// Date-mask input with an editable format knob.
final $DateInput = _Story(name: 'Date Input');

/// Time-mask input built from editable and static parts.
final $TimeInput = _Story(
  name: 'Time Input',
  args: _Args(
    format: EnumArg(
      FormattedInputFormat.time,
      values: FormattedInputFormat.values,
    ),
  ),
);
