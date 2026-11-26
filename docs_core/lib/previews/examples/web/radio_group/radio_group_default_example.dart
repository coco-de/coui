import 'package:coui_web/coui_web.dart';

class RadioGroupDefaultExample extends StatefulComponent {
  const RadioGroupDefaultExample({super.key});

  @override
  State<RadioGroupDefaultExample> createState() => _RadioGroupDefaultExampleState();
}

class _RadioGroupDefaultExampleState extends State<RadioGroupDefaultExample> {
  String? _selected = 'option1';

  @override
  Component build(BuildContext context) {
    return RadioGroup(
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
