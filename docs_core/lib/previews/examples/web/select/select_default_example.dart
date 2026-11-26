import 'package:coui_web/coui_web.dart';

class SelectDefaultExample extends StatefulComponent {
  const SelectDefaultExample({super.key});

  @override
  State<SelectDefaultExample> createState() => _SelectDefaultExampleState();
}

class _SelectDefaultExampleState extends State<SelectDefaultExample> {
  String? _value = 'apple';

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Component build(BuildContext context) {
    return Select<String>(
      items: const [
        CoreSelectItem(value: 'apple', label: '사과'),
        CoreSelectItem(value: 'banana', label: '바나나'),
        CoreSelectItem(value: 'orange', label: '오렌지'),
      ],
      value: _value,
      placeholder: '과일을 선택해 주세요',
      onChanged: handleChanged,
    );
  }
}
