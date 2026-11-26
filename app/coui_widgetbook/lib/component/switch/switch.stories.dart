import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'switch.stories.g.dart';

/// Interactive demo host for [Toggle] (switch) stories.
class ToggleDemo extends StatefulWidget {
  /// Creates a [ToggleDemo].
  const ToggleDemo({
    super.key,
    this.initialValue = false,
    this.enabled = true,
    this.showLabel = true,
    this.label = 'Notifications',
  });

  /// Initial on / off value.
  final bool initialValue;

  /// Whether the toggle reacts to input.
  final bool enabled;

  /// Whether the trailing label is shown.
  final bool showLabel;

  /// Trailing label text.
  final String label;

  @override
  State<ToggleDemo> createState() => _ToggleDemoState();
}

class _ToggleDemoState extends State<ToggleDemo> {
  // deferred init must read widget.
  late bool _value = widget.initialValue;

  @override
  void didUpdateWidget(ToggleDemo oldWidget) {
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
    return Toggle(
      onChanged: widget.enabled ? handleChanged : null,
      value: _value,
      suffix: widget.showLabel ? Text(widget.label) : null,
    );
  }
}

/// Navigation metadata for the Switch component.
const kComponentMeta = ComponentMeta(name: 'Switch', path: 'form');

/// Story metadata for [ToggleDemo].
const kMeta = Meta(ToggleDemo.new);

/// Labeled switch with editable knobs.
final $Default = _Story();

/// Switch without a trailing label.
final $WithoutLabel = _Story(
  name: 'Without Label',
  args: _Args(showLabel: BoolArg(false)),
);
