import 'package:coui_web/coui_web.dart';

class CheckboxDisabledExample extends StatefulComponent {
  const CheckboxDisabledExample({super.key});

  @override
  State<CheckboxDisabledExample> createState() => _CheckboxDisabledExampleState();
}

class _CheckboxDisabledExampleState extends State<CheckboxDisabledExample> {
  bool? _checked = false;

  @override
  Component build(BuildContext context) {
    return Checkbox(
      checked: _checked,
      label: '비활성',
      enabled: false,
      onChanged: (value) => setState(() => _checked = value),
    );
  }
}
