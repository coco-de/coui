import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'sortable.stories.g.dart';

/// Default number of sortable items.
const _kDefaultItemCount = 5;

/// Interactive demo host for [Sortable] stories.
///
/// Owns the item list so drag-reordering persists. The list rebuilds
/// whenever the [itemCount] knob changes.
class SortableDemo extends StatefulWidget {
  /// Creates a [SortableDemo].
  const SortableDemo({super.key, this.itemCount = _kDefaultItemCount});

  /// Number of sortable items.
  final int itemCount;

  @override
  State<SortableDemo> createState() => _SortableDemoState();
}

class _SortableDemoState extends State<SortableDemo> {
  // deferred init must read widget.
  late List<String> _items = _freshItems;

  List<String> get _freshItems => [
    for (int i = 1; i <= widget.itemCount; i += 1) 'Item $i',
  ];

  @override
  void didUpdateWidget(SortableDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _items = _freshItems;
    }
  }

  void handleReorder({required int oldIndex, required int newIndex}) {
    setState(() {
      final newItems = [..._items];
      final item = newItems.removeAt(oldIndex);
      newItems.insert(newIndex, item);
      _items = newItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sortable(
      itemCount: _items.length,
      itemBuilder: (context, index, dragHandle, removeButton) {
        return Row(
          mainAxisSize: .min,
          spacing: CoreSpace.space8,
          children: [
            dragHandle,
            Text(_items[index]),
          ],
        );
      },
      onReorder: (oldIndex, newIndex) =>
          handleReorder(oldIndex: oldIndex, newIndex: newIndex),
    );
  }
}

/// Navigation metadata for the Sortable component.
const kComponentMeta = ComponentMeta(name: 'Sortable', path: 'form');

/// Story metadata for [SortableDemo].
const kMeta = Meta(SortableDemo.new);

/// Drag-to-reorder list with an item count knob.
final $Default = _Story();
