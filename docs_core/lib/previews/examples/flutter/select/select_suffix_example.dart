import 'package:coui_flutter/coui_flutter.dart';

class SelectSuffixExample extends StatefulWidget {
  const SelectSuffixExample({super.key});

  @override
  State<SelectSuffixExample> createState() => _SelectSuffixExampleState();
}

class _SelectSuffixExampleState extends State<SelectSuffixExample> {
  String? _value = 'apple';

  void handleChanged(String value) {
    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) {
    return Select<String>(
      items: const [
        CoreSelectItem(value: 'apple', label: '사과'),
        CoreSelectItem(value: 'banana', label: '바나나'),
        CoreSelectItem(value: 'orange', label: '오렌지'),
      ],
      value: _value,
      suffix: const Text('변경'),
      placeholder: '과일을 선택해 주세요',
      onChanged: handleChanged,
    );
  }
}
