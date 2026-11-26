import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'checkbox.stories.g.dart';

/// Interactive demo host for [Checkbox] stories.
///
/// Owns the tristate `checked` value so the checkbox toggles on tap.
class CheckboxDemo extends StatefulWidget {
  /// Creates a [CheckboxDemo].
  const CheckboxDemo({
    super.key,
    this.initialChecked = false,
    this.enabled = true,
    this.tristate = false,
    this.label = '',
  });

  /// Initial checkbox state.
  final bool? initialChecked;

  /// Whether the checkbox reacts to taps.
  final bool enabled;

  /// Whether the indeterminate state joins the tap cycle.
  final bool tristate;

  /// Suffix label text — hidden when empty.
  final String label;

  @override
  State<CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<CheckboxDemo> {
  bool? _checked = false;

  @override
  void initState() {
    super.initState();
    _checked = widget.initialChecked;
  }

  @override
  void didUpdateWidget(CheckboxDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialChecked != widget.initialChecked) {
      _checked = widget.initialChecked;
    }
  }

  void handleChanged({required bool? checked}) {
    setState(() => _checked = checked);
  }

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      onChanged: widget.enabled
          ? (checked) => handleChanged(checked: checked)
          : null,
      checked: _checked,
      tristate: widget.tristate,
      suffix: widget.label.isEmpty ? null : Text(widget.label),
    );
  }
}

/// Navigation metadata for the Checkbox component.
const kComponentMeta = ComponentMeta(name: 'Checkbox', path: 'form');

/// Story metadata for [CheckboxDemo].
const kMeta = Meta(CheckboxDemo.new);

/// Toggleable checkbox with editable knobs.
final $Default = _Story();

/// Checkbox with a suffix label.
final $WithLabel = _Story(
  name: 'With Label',
  args: _Args(label: StringArg('Accept terms and conditions')),
);

/// Checkbox cycling through checked / indeterminate / unchecked.
final $Tristate = _Story(
  args: _Args(
    tristate: BoolArg(true),
    label: StringArg('Tristate checkbox'),
  ),
);
