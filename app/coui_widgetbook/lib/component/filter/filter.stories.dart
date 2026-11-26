import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'filter.stories.g.dart';

const List<CoreFilterItem<String, Widget>> _kFilterItems = [
  CoreFilterItem(value: 'svelte', label: 'Svelte'),
  CoreFilterItem(value: 'vue', label: 'Vue'),
  CoreFilterItem(value: 'react', label: 'React'),
];

/// Interactive demo host for [Filter] stories.
class FilterDemo extends StatefulWidget {
  /// Creates a [FilterDemo].
  const FilterDemo({super.key, this.showResetButton = true});

  /// Whether the reset button is shown.
  final bool showResetButton;

  @override
  State<FilterDemo> createState() => _FilterDemoState();
}

class _FilterDemoState extends State<FilterDemo> {
  String? _selected = 'svelte';

  void handleValueChanged(String value) {
    setState(() => _selected = value);
  }

  void handleReset() {
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return Filter<String>(
      groupValue: _selected,
      items: _kFilterItems,
      onValueChanged: handleValueChanged,
      onReset: widget.showResetButton ? handleReset : null,
      showResetButton: widget.showResetButton,
    );
  }
}

/// Navigation metadata for the Filter component.
const kComponentMeta = ComponentMeta(name: 'Filter', path: 'control');

/// Story metadata for [FilterDemo].
const kMeta = Meta(FilterDemo.new);

/// Segmented filter with a reset button and editable knobs.
final $Default = _Story();

/// Filter without the reset button.
final $WithoutReset = _Story(
  name: 'Without Reset',
  args: _Args(showResetButton: BoolArg(false)),
);
