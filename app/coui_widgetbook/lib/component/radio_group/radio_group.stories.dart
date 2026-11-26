import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'radio_group.stories.g.dart';

/// Interactive demo host for [RadioGroup] stories.
class RadioGroupDemo extends material.StatefulWidget {
  /// Creates a [RadioGroupDemo].
  const RadioGroupDemo({
    super.key,
    this.orientation = CoreRadioGroupOrientation.vertical,
    this.size = CoreComponentSize.md,
    this.enabled = true,
  });

  /// Layout direction of the radio options.
  final CoreRadioGroupOrientation orientation;

  /// Size of the radio controls.
  final CoreComponentSize size;

  /// Whether selection changes are enabled.
  final bool enabled;

  @override
  material.State<RadioGroupDemo> createState() => _RadioGroupDemoState();
}

class _RadioGroupDemoState extends material.State<RadioGroupDemo> {
  String? _selected = 'option1';

  void handleChanged(String? value) {
    setState(() => _selected = value);
  }

  @override
  material.Widget build(material.BuildContext context) {
    return RadioGroup<String>(
      onChanged: widget.enabled ? handleChanged : null,
      value: _selected,
      options: const [
        (value: 'option1', label: 'Option 1'),
        (value: 'option2', label: 'Option 2'),
        (value: 'option3', label: 'Option 3'),
      ],
      size: widget.size,
      orientation: widget.orientation,
    );
  }
}

/// Navigation metadata for the RadioGroup component.
const kComponentMeta = ComponentMeta(name: 'RadioGroup', path: 'form');

/// Story metadata for [RadioGroupDemo].
const kMeta = Meta(RadioGroupDemo.new);

/// Vertical radio group with a live selection.
final $Default = _Story();

/// Radio group rendered at a larger control size.
final $Sizes = _Story(
  args: _Args(
    size: EnumArg(CoreComponentSize.lg, values: CoreComponentSize.values),
  ),
);
