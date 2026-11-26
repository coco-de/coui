import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'radio.stories.g.dart';

/// Interactive demo host for [Radio] stories.
///
/// Hosts a [RadioGroup] so the radios reflect a live selection.
class RadioDemo extends material.StatefulWidget {
  /// Creates a [RadioDemo].
  const RadioDemo({
    super.key,
    this.enabled = true,
    this.showLabels = false,
  });

  /// Whether selection changes are enabled.
  final bool enabled;

  /// Whether each radio shows a trailing text label.
  final bool showLabels;

  @override
  material.State<RadioDemo> createState() => _RadioDemoState();
}

class _RadioDemoState extends material.State<RadioDemo> {
  String? _selected;

  List<String> get _values => widget.showLabels
      ? const ['small', 'medium', 'large']
      : const ['option1', 'option2', 'option3'];

  @override
  void initState() {
    super.initState();
    _selected = _values.first;
  }

  @override
  void didUpdateWidget(RadioDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showLabels != widget.showLabels) {
      _selected = _values.first;
    }
  }

  void handleChanged(String? value) {
    setState(() => _selected = value);
  }

  @override
  material.Widget build(material.BuildContext context) {
    final radioLabels = t.widgetbook.radio;

    return RadioGroup<String>(
      onChanged: widget.enabled ? handleChanged : null,
      value: _selected,
      child: material.Column(
        mainAxisSize: material.MainAxisSize.min,
        crossAxisAlignment: widget.showLabels
            ? material.CrossAxisAlignment.start
            : material.CrossAxisAlignment.center,
        spacing: CoreSpace.space8,
        children: widget.showLabels
            ? [
                Radio(value: 'small', suffix: Text(radioLabels.small)),
                Radio(value: 'medium', suffix: Text(radioLabels.medium)),
                Radio(value: 'large', suffix: Text(radioLabels.large)),
              ]
            : const [
                Radio(value: 'option1'),
                Radio(value: 'option2'),
                Radio(value: 'option3'),
              ],
      ),
    );
  }
}

/// Navigation metadata for the Radio component.
const kComponentMeta = ComponentMeta(name: 'Radio', path: 'form');

/// Story metadata for [RadioDemo].
const kMeta = Meta(RadioDemo.new);

/// Radio group with a live selection.
final $Default = _Story();

/// Radios with trailing text labels.
final $WithLabels = _Story(
  name: 'With Labels',
  args: _Args(showLabels: BoolArg(true)),
);
