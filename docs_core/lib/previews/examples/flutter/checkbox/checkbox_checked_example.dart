import 'package:coui_flutter/coui_flutter.dart';

class CheckboxCheckedExample extends StatefulWidget {
  const CheckboxCheckedExample({super.key});

  @override
  State<CheckboxCheckedExample> createState() => _CheckboxCheckedExampleState();
}

class _CheckboxCheckedExampleState extends State<CheckboxCheckedExample> {
  bool? _checked = true;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '선택됨',
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}
