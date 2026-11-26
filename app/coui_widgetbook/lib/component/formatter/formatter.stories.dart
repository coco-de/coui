import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'formatter.stories.g.dart';

const _kFieldWidth = 280.0;
const _kIntegerMaxDefault = 100;

void _handleNoop(String value) {}

/// Interactive demo host for `TextInputFormatters` stories.
///
/// Renders a [TextField] with either integer-only masking or an
/// uppercase transform, driven by the knob parameters.
class FormatterDemo extends StatelessWidget {
  /// Creates a [FormatterDemo].
  const FormatterDemo({
    super.key,
    this.min = 0,
    this.max = _kIntegerMaxDefault,
    this.uppercase = false,
  });

  /// Minimum allowed integer value for the integer-only formatter.
  final int min;

  /// Maximum allowed integer value for the integer-only formatter.
  final int max;

  /// Whether the field transforms input to uppercase instead of
  /// masking to integers.
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kFieldWidth,
      child: uppercase
          ? TextField(
              onChanged: _handleNoop,
              placeholder: const Text('Automatically converted to uppercase'),
              inputFormatters: [TextInputFormatters.toUpperCase()],
            )
          : TextField(
              onChanged: _handleNoop,
              placeholder: Text('Numbers only ($min-$max)'),
              inputFormatters: [
                TextInputFormatters.integerOnly(max: max, min: min),
              ],
            ),
    );
  }
}

/// Navigation metadata for the InputFormatter component.
const kComponentMeta = ComponentMeta(name: 'InputFormatter', path: 'form');

/// Story metadata for [FormatterDemo].
const kMeta = Meta(FormatterDemo.new);

/// Integer-only masking with editable min/max knobs.
final $Default = _Story();

/// Uppercase-transform masking.
final $Uppercase = _Story(
  args: _Args(uppercase: BoolArg(true)),
);
