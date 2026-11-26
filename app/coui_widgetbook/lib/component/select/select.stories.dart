import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'select.stories.g.dart';

/// Interactive demo host for [Select] stories.
///
/// Manages the selected value so choosing an option updates the
/// trigger label. An empty [placeholder] falls back to the widget
/// default (no placeholder).
class SelectDemo extends StatefulWidget {
  /// Creates a [SelectDemo].
  const SelectDemo({
    super.key,
    this.enabled = true,
    this.placeholder = '',
  });

  /// Whether the select is interactive.
  final bool enabled;

  /// Placeholder shown while nothing is selected (empty = none).
  final String placeholder;

  @override
  State<SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<SelectDemo> {
  String? _selectedValue;

  void handleChanged(String value) {
    setState(() => _selectedValue = value);
  }

  @override
  Widget build(BuildContext context) {
    final selectStrings = t.widgetbook.select;

    return Select<String>(
      onChanged: handleChanged,
      items: [
        CoreSelectItem(value: 'apple', label: selectStrings.apple),
        CoreSelectItem(value: 'banana', label: selectStrings.banana),
        CoreSelectItem(value: 'cherry', label: selectStrings.cherry),
        CoreSelectItem(value: 'date', label: selectStrings.date),
      ],
      value: _selectedValue,
      placeholder: widget.placeholder.isEmpty ? null : widget.placeholder,
      enabled: widget.enabled,
    );
  }
}

/// Navigation metadata for the Select component.
const kComponentMeta = ComponentMeta(name: 'Select', path: 'form');

/// Story metadata for [SelectDemo].
const kMeta = Meta(SelectDemo.new);

/// Fruit select with editable knobs.
final $Default = _Story();

/// Select showing a placeholder until a value is chosen.
final $WithPlaceholder = _Story(
  name: 'With Placeholder',
  args: _Args(placeholder: StringArg('Choose a fruit')),
);
