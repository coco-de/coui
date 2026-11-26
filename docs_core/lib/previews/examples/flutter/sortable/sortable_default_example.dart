import 'package:coui_flutter/coui_flutter.dart';

class SortableDefaultExample extends StatefulWidget {
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
  Widget build(BuildContext context) {
    return Sortable(
      itemCount: _items.length,
      onReorder: handleReorder,
      itemBuilder: (context, index, dragHandle, removeButton) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Theme.of(context).geometry.space(CoreSpace.space10),
          children: [
            dragHandle,
            Text(_items[index]),
          ],
        );
      },
    );
  }
}
