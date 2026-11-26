import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSortableStyle] slot without constructing the widget
/// from scratch. The patch restyles the row surface, its radius and
/// padding, and repaints the drag handle.
class SortableChainExample extends StatefulComponent {
  const SortableChainExample({super.key});

  @override
  State<SortableChainExample> createState() => _SortableChainExampleState();
}

class _SortableChainExampleState extends State<SortableChainExample> {
  List<String> _items = const ['항목 1', '항목 2', '항목 3'];

  void handleReorder(int oldIndex, int newIndex) {
    setState(() {
      final newItems = [..._items];
      final item = newItems.removeAt(oldIndex);
      newItems.insert(newIndex, item);
      _items = newItems;
    });
  }

  @override
  Component build(BuildContext context) {
    return Sortable(
      itemCount: _items.length,
      onReorder: handleReorder,
      itemBuilder: (index, dragHandle, removeButton) => div(
        [
          dragHandle,
          span([Text(_items[index])]),
        ],
        classes: 'flex items-center flex-1 gap-${CoreSpace.scale.space8}',
      ),
    ).withStyle(
      const CoreSortableStyle(
        itemBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        itemPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space12,
        ),
        handleColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
