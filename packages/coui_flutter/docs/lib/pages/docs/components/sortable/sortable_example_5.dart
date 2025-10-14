import 'package:coui_flutter/coui_flutter.dart';

class SortableExample5 extends StatefulWidget {
  const SortableExample5({super.key});

  @override
  State<SortableExample5> createState() => _SortableExample5State();
}

class _SortableExample5State extends State<SortableExample5> {
  List<SortableData<String>> names = [
    const SortableData('James'),
    const SortableData('John'),
    const SortableData('Robert'),
    const SortableData('Michael'),
    const SortableData('William'),
  ];

  @override
  Widget build(BuildContext context) {
    return SortableLayer(
      lock: true,
      child: SortableDropFallback<int>(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < names.length; i++)
              Sortable<String>(
                data: names[i],
                // we only want user to drag the item from the handle,
                // so we disable the drag on the item itself
                enabled: false,
                key: ValueKey(i),
                onAcceptBottom: (value) {
                  setState(() {
                    names.swapItem(value, i + 1);
                  });
                },
                onAcceptTop: (value) {
                  setState(() {
                    names.swapItem(value, i);
                  });
                },
                child: OutlinedContainer(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SortableDragHandle(child: Icon(Icons.drag_handle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(names[i].data)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        onAccept: (value) {
          setState(() {
            names.add(names.removeAt(value.data));
          });
        },
      ),
    );
  }
}
