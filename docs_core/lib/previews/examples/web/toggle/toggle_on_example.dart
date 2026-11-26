import 'package:coui_web/coui_web.dart';

class ToggleOnExample extends StatefulComponent {
  const ToggleOnExample({super.key});

  @override
  State<ToggleOnExample> createState() => _ToggleOnExampleState();
}

class _ToggleOnExampleState extends State<ToggleOnExample> {
  bool _value = true;

  @override
  Component build(BuildContext context) {
    return Toggle(
      value: _value,
      label: '다크 모드',
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
