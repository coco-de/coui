import 'package:coui_flutter/coui_flutter.dart';

class SelectExample1 extends StatefulWidget {
  const SelectExample1({super.key});

  @override
  State<SelectExample1> createState() => _SelectExample1State();
}

class _SelectExample1State extends State<SelectExample1> {
  String? selectedValue;
  @override
  Widget build(BuildContext context) {
    return Select<String>(
      itemBuilder: (context, item) {
        return Text(item);
      },
      onChanged: (value) {
        setState(() {
          selectedValue = value;
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
      popupConstraints: const BoxConstraints(maxWidth: 200, maxHeight: 300),
      value: selectedValue,
    );
  }
}
