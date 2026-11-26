import 'package:coui_flutter/coui_flutter.dart';

class ToggleDefaultExample extends StatefulWidget {
  const ToggleDefaultExample({super.key});

  @override
  State<ToggleDefaultExample> createState() => _ToggleDefaultExampleState();
}

class _ToggleDefaultExampleState extends State<ToggleDefaultExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      label: '다크 모드',
    );
  }
}
