import 'package:coui_web/coui_web.dart';

class CheckboxDefaultExample extends StatefulComponent {
  const CheckboxDefaultExample({super.key});

  @override
  State<CheckboxDefaultExample> createState() => _CheckboxDefaultExampleState();
}

class _CheckboxDefaultExampleState extends State<CheckboxDefaultExample> {
  bool? _checked = false;

  @override
  Component build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '약관 동의',
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}
