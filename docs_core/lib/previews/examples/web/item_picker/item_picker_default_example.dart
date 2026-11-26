import 'package:coui_web/coui_web.dart';

class ItemPickerDefaultExample extends StatefulComponent {
  const ItemPickerDefaultExample({super.key});

  @override
  State<ItemPickerDefaultExample> createState() => _ItemPickerDefaultExampleState();
}

class _ItemPickerDefaultExampleState extends State<ItemPickerDefaultExample> {
  String _selected = '김코드';

  @override
  Component build(BuildContext context) {
    return ItemPicker(
      items: const ['김코드', '이코드', '박코드', '최코드', '정코드'],
      selectedValue: _selected,
      title: '담당자',
      onChanged: (value) => setState(() => _selected = value),
    );
  }
}
