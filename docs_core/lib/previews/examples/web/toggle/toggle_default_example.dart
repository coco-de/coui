import 'package:coui_web/coui_web.dart';

class ToggleDefaultExample extends StatefulComponent {
  const ToggleDefaultExample({super.key});

  @override
  State<ToggleDefaultExample> createState() => _ToggleDefaultExampleState();
}

class _ToggleDefaultExampleState extends State<ToggleDefaultExample> {
  bool _value = false;

  @override
  Component build(BuildContext context) {
    return Toggle(
      value: _value,
      label: '다크 모드',
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
