import 'package:coui_web/coui_web.dart';

class CheckboxCheckedExample extends StatefulComponent {
  const CheckboxCheckedExample({super.key});

  @override
  State<CheckboxCheckedExample> createState() => _CheckboxCheckedExampleState();
}

class _CheckboxCheckedExampleState extends State<CheckboxCheckedExample> {
  bool? _checked = true;

  @override
  Component build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '선택됨',
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}
