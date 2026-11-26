import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'switch_field.stories.g.dart';

/// Interactive demo host for [SwitchField] stories.
class SwitchFieldDemo extends StatefulWidget {
  /// Creates a [SwitchFieldDemo].
  const SwitchFieldDemo({
    super.key,
    this.initialValue = false,
    this.label = 'Enable notifications',
    this.description = 'Receive push notifications.',
    this.enabled = true,
  });

  /// Initial on / off value.
  final bool initialValue;

  /// Field label text.
  final String label;

  /// Supporting description text (empty hides the description).
  final String description;

  /// Whether the field reacts to input.
  final bool enabled;

  @override
  State<SwitchFieldDemo> createState() => _SwitchFieldDemoState();
}

class _SwitchFieldDemoState extends State<SwitchFieldDemo> {
  // deferred init must read widget.
  late bool _value = widget.initialValue;

  @override
  void didUpdateWidget(SwitchFieldDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  void handleChanged(bool value) {
    setState(() {
      _value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchField(
      onChanged: widget.enabled ? handleChanged : null,
      label: widget.label,
      value: _value,
      description: widget.description.isEmpty ? null : widget.description,
      enabled: widget.enabled,
    );
  }
}

/// Navigation metadata for the SwitchField component.
const kComponentMeta = ComponentMeta(name: 'SwitchField', path: 'form');

/// Story metadata for [SwitchFieldDemo].
const kMeta = Meta(SwitchFieldDemo.new);

/// Labeled switch field with editable knobs.
final $Default = _Story();

/// Disabled, administrator-managed field.
final $Disabled = _Story(
  args: _Args(
    initialValue: BoolArg(true),
    label: StringArg('Auto-sync data'),
    description: StringArg('Managed by your administrator.'),
    enabled: BoolArg(false),
  ),
);
