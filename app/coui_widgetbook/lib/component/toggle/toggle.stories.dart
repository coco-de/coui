import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'toggle.stories.g.dart';

/// Interactive demo host for [Toggle] stories.
///
/// Manages the checked state internally so the toggle can be flipped
/// in the preview.
class ToggleDemo extends StatefulWidget {
  /// Creates a [ToggleDemo].
  const ToggleDemo({
    super.key,
    this.initialValue = false,
    this.enabled = true,
    this.label = 'Toggle',
  });

  /// Initial checked state of the toggle.
  final bool initialValue;

  /// Whether the toggle reacts to user input.
  final bool enabled;

  /// Trailing label text next to the toggle.
  final String label;

  @override
  State<ToggleDemo> createState() => _ToggleDemoState();
}

class _ToggleDemoState extends State<ToggleDemo> {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didUpdateWidget(ToggleDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  void handleChanged(bool value) {
    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) {
    return Toggle(
      onChanged: widget.enabled ? handleChanged : null,
      value: _value,
      suffix: Text(widget.label),
    );
  }
}

/// Navigation metadata for the Toggle component.
const kComponentMeta = ComponentMeta(name: 'Toggle', path: 'form');

/// Story metadata for [ToggleDemo].
const kMeta = Meta(ToggleDemo.new);

/// Interactive toggle with editable knobs.
final $Default = _Story();

/// Toggle starting in the checked state.
final $On = _Story(
  args: _Args(initialValue: BoolArg(true)),
);

/// Toggle that does not react to user input.
final $Disabled = _Story(
  args: _Args(enabled: BoolArg(false)),
);
