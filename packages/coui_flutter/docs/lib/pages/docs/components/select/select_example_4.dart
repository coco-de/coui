import 'package:coui_flutter/coui_flutter.dart';

class SelectExample4 extends StatefulWidget {
  const SelectExample4({super.key});

  @override
  State<SelectExample4> createState() => _SelectExample4State();
}

class _SelectExample4State extends State<SelectExample4> {
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
      popup: (context) => const SelectPopup.noVirtualization(
        items: SelectItemList(
          children: [
            SelectItemButton(value: 'Apple', child: Text('Apple')),
            SelectItemButton(value: 'Banana', child: Text('Banana')),
            SelectItemButton(value: 'Cherry', child: Text('Cherry')),
          ],
        ),
      ),
      popupConstraints: const BoxConstraints(maxWidth: 200, maxHeight: 300),
      popupWidthConstraint: PopoverConstraint.intrinsic,
      value: selectedValue,
    );
  }
}
