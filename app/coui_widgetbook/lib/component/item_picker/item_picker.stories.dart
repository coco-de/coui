import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'item_picker.stories.g.dart';

// ItemPicker widgetbook constants.
const _kItems = ['Apple', 'Banana', 'Cherry', 'Mango', 'Orange'];

/// Interactive demo host for [ItemPicker] stories.
///
/// Tracks the currently selected item across rebuilds.
class ItemPickerDemo extends StatefulWidget {
  /// Creates an [ItemPickerDemo].
  const ItemPickerDemo({
    super.key,
    this.layout = CoreItemPickerLayout.defaultLayout,
    this.gridColumns = CoreItemPickerLayout.defaultGridColumns,
    this.showSearch = true,
    this.enabled = true,
  });

  /// Layout mode for item arrangement.
  final CoreItemPickerLayout layout;

  /// Number of columns used in the grid layout.
  final int gridColumns;

  /// Whether the search field is shown.
  final bool showSearch;

  /// Whether the picker accepts interaction.
  final bool enabled;

  @override
  State<ItemPickerDemo> createState() => _ItemPickerDemoState();
}

class _ItemPickerDemoState extends State<ItemPickerDemo> {
  String? _selected = 'Apple';

  void handleItemChanged(String value) {
    setState(() => _selected = value);
  }

  @override
  Widget build(BuildContext context) {
    return ItemPicker(
      onChanged: handleItemChanged,
      items: _kItems,
      selectedValue: _selected,
      showSearch: widget.showSearch,
      enabled: widget.enabled,
      layout: widget.layout,
      gridColumns: widget.gridColumns,
      title: 'Fruits',
    );
  }
}

/// Navigation metadata for the ItemPicker component.
const kComponentMeta = ComponentMeta(name: 'ItemPicker', path: 'form');

/// Story metadata for [ItemPickerDemo].
const kMeta = Meta(ItemPickerDemo.new);

/// List-layout picker with editable knobs.
final $Default = _Story();

/// Grid-layout picker.
final $Grid = _Story(
  args: _Args(
    layout: EnumArg(
      CoreItemPickerLayout.grid,
      values: CoreItemPickerLayout.values,
    ),
  ),
);
