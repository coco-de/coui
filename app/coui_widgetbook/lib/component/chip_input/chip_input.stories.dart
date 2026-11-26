import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'chip_input.stories.g.dart';

// ChipInput widgetbook constants.
const _kDefaultMaxChips = 10;

/// Interactive demo host for [ChipInput] stories.
///
/// Owns the chip list so typed entries are appended on submit and
/// removed chips disappear.
class ChipInputDemo extends StatefulWidget {
  /// Creates a [ChipInputDemo].
  const ChipInputDemo({
    super.key,
    this.enabled = true,
    this.maxChips = _kDefaultMaxChips,
    this.placeholder = 'Add tags...',
  });

  /// Whether the input accepts interaction.
  final bool enabled;

  /// Maximum number of chips.
  final int maxChips;

  /// Placeholder text shown when the field is empty.
  final String placeholder;

  @override
  State<ChipInputDemo> createState() => _ChipInputDemoState();
}

class _ChipInputDemoState extends State<ChipInputDemo> {
  List<String> _chips = ['Flutter', 'Dart'];

  void handleChanged(List<String> chips) {
    setState(() => _chips = chips);
  }

  void handleSubmitted(String value) {
    setState(() => _chips = [..._chips, value]);
  }

  @override
  Widget build(BuildContext context) {
    return ChipInput(
      onChanged: handleChanged,
      chips: _chips,
      placeholder: widget.placeholder,
      enabled: widget.enabled,
      maxChips: widget.maxChips,
      onSubmitted: handleSubmitted,
    );
  }
}

/// Navigation metadata for the ChipInput component.
const kComponentMeta = ComponentMeta(name: 'Chip Input', path: 'form');

/// Story metadata for [ChipInputDemo].
const kMeta = Meta(ChipInputDemo.new);

/// Editable chip input with editable knobs.
final $Default = _Story();

/// Disabled chip input.
final $Disabled = _Story(
  args: _Args(enabled: BoolArg(false)),
);
