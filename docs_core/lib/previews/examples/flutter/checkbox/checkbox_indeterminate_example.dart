import 'package:coui_flutter/coui_flutter.dart';

class CheckboxIndeterminateExample extends StatefulWidget {
  const CheckboxIndeterminateExample({super.key});

  @override
  State<CheckboxIndeterminateExample> createState() => _CheckboxIndeterminateExampleState();
}

class _CheckboxIndeterminateExampleState extends State<CheckboxIndeterminateExample> {
  bool? _checked;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '일부 선택',
      tristate: true,
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}
