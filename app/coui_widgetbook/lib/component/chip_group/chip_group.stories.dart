import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'chip_group.stories.g.dart';

// ChipGroup widgetbook constants.
const _kResultSpacing = 16.0;

/// Items shown in the wrap layout demo.
const _kWrapItems = ['Flutter', 'React', 'Swift', 'Kotlin'];

/// Items shown in the scroll layout demo.
const _kScrollItems = [
  'All',
  'Frontend',
  'Backend',
  'Mobile',
  'Design',
  'DevOps',
];

/// Interactive demo host for [ChipGroup] stories.
///
/// Owns the selected item set so chips toggle on tap. The scroll
/// layout swaps in a longer item list to demonstrate overflow.
class ChipGroupDemo extends StatefulWidget {
  /// Creates a [ChipGroupDemo].
  const ChipGroupDemo({
    super.key,
    this.selectionMode = CoreChipGroupSelectionMode.multi,
    this.layout = CoreChipGroupLayout.wrap,
    this.allowDeselect = true,
    this.chipColor = CoreChipColor.primary,
  });

  /// Selection mode of the hosted [ChipGroup].
  final CoreChipGroupSelectionMode selectionMode;

  /// Layout of the hosted [ChipGroup].
  final CoreChipGroupLayout layout;

  /// Whether a selected chip can be deselected.
  final bool allowDeselect;

  /// Color role of the chips.
  final CoreChipColor chipColor;

  @override
  State<ChipGroupDemo> createState() => _ChipGroupDemoState();
}

class _ChipGroupDemoState extends State<ChipGroupDemo> {
  Set<String> _selected = const {'Flutter'};

  List<String> get _items =>
      widget.layout == .scroll ? _kScrollItems : _kWrapItems;

  void handleChanged(Set<String> next) {
    setState(() => _selected = next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: _kResultSpacing,
      children: [
        ChipGroup<String>(
          onChanged: handleChanged,
          initialValue: _selected,
          items: _items,
          chipBuilder:
              (item, {required selected, required enabled, required onTap}) =>
                  Chip(
                    onTap: onTap,
                    label: item,
                    chipColor: widget.chipColor,
                    selected: selected,
                    enabled: enabled,
                  ),
          selectionMode: widget.selectionMode,
          layout: widget.layout,
          allowDeselect: widget.allowDeselect,
        ),
        Text('Selected: ${_selected.join(', ')}').bodySmall().onSurface(),
      ],
    );
  }
}

/// Navigation metadata for the ChipGroup component.
const kComponentMeta = ComponentMeta(name: 'Chip Group', path: 'display');

/// Story metadata for [ChipGroupDemo].
const kMeta = Meta(ChipGroupDemo.new);

/// Multi-select wrap layout with editable knobs.
final $Default = _Story();

/// Single-select horizontal scroll layout.
final $Scroll = _Story(
  args: _Args(
    selectionMode: EnumArg(
      CoreChipGroupSelectionMode.single,
      values: CoreChipGroupSelectionMode.values,
    ),
    layout: EnumArg(
      CoreChipGroupLayout.scroll,
      values: CoreChipGroupLayout.values,
    ),
    chipColor: EnumArg(CoreChipColor.neutral, values: CoreChipColor.values),
  ),
);
