import 'package:coui_flutter/coui_flutter.dart';

class CheckboxDisabledExample extends StatefulWidget {
  const CheckboxDisabledExample({super.key});

  @override
  State<CheckboxDisabledExample> createState() => _CheckboxDisabledExampleState();
}

class _CheckboxDisabledExampleState extends State<CheckboxDisabledExample> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '비활성',
      enabled: false,
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}
