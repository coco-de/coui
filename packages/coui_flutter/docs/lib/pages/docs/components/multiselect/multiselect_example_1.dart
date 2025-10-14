import 'package:coui_flutter/coui_flutter.dart';

class MultiSelectExample1 extends StatefulWidget {
  const MultiSelectExample1({super.key});

  @override
  State<MultiSelectExample1> createState() => _MultiSelectExample1State();
}

class _MultiSelectExample1State extends State<MultiSelectExample1> {
  Iterable<String>? selectedValues;
  @override
  Widget build(BuildContext context) {
    return MultiSelect<String>(
      constraints: const BoxConstraints(minWidth: 200),
      itemBuilder: (context, item) {
        return MultiSelectChip(value: item, child: Text(item));
      },
      onChanged: (value) {
        setState(() {
          selectedValues = value;
        });
      },
      placeholder: const Text('Select a fruit'),
      popup: (context) => const SelectPopup(
        items: SelectItemList(
          children: [
            SelectItemButton(value: 'Apple', child: Text('Apple')),
            SelectItemButton(value: 'Banana', child: Text('Banana')),
            SelectItemButton(value: 'Cherry', child: Text('Cherry')),
          ],
        ),
      ),
      value: selectedValues,
    );
  }
}
