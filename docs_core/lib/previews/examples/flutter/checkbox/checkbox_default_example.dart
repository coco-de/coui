import 'package:coui_flutter/coui_flutter.dart';

class CheckboxDefaultExample extends StatefulWidget {
  const CheckboxDefaultExample({super.key});

  @override
  State<CheckboxDefaultExample> createState() => _CheckboxDefaultExampleState();
}

class _CheckboxDefaultExampleState extends State<CheckboxDefaultExample> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '약관 동의',
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}
