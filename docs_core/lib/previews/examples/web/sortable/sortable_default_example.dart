import 'package:coui_web/coui_web.dart';

class SortableDefaultExample extends StatefulComponent {
  const SortableDefaultExample({super.key});

  @override
  State<SortableDefaultExample> createState() => _SortableDefaultExampleState();
}

class _SortableDefaultExampleState extends State<SortableDefaultExample> {
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
        classes: 'flex items-center flex-1 gap-${CoreSpace.scale.space10}',
      ),
    );
  }
}
