import 'package:coui_flutter/coui_flutter.dart';

class SortableExample3 extends StatefulWidget {
  const SortableExample3({super.key});

  @override
  State<SortableExample3> createState() => _SortableExample3State();
}

class _SortableExample3State extends State<SortableExample3> {
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
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < names.length; i++)
                Sortable<String>(
                  data: names[i],
                  key: ValueKey(i),
                  onAcceptLeft: (value) {
                    setState(() {
                      names.swapItem(value, i);
                    });
                  },
                  onAcceptRight: (value) {
                    setState(() {
                      names.swapItem(value, i + 1);
                    });
                  },
                  child: OutlinedContainer(
                    padding: const EdgeInsets.all(12),
                    width: 100,
                    child: Center(child: Text(names[i].data)),
                  ),
                ),
            ],
          ),
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
