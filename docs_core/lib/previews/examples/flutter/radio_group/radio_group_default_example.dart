import 'package:coui_flutter/coui_flutter.dart';

class RadioGroupDefaultExample extends StatefulWidget {
  const RadioGroupDefaultExample({super.key});

  @override
  State<RadioGroupDefaultExample> createState() => _RadioGroupDefaultExampleState();
}

class _RadioGroupDefaultExampleState extends State<RadioGroupDefaultExample> {
  String? _selected = 'option1';

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      value: _selected,
      onChanged: (v) => setState(() => _selected = v),
      options: const [
        (value: 'option1', label: '옵션 1'),
        (value: 'option2', label: '옵션 2'),
        (value: 'option3', label: '옵션 3'),
      ],
    );
  }
}
