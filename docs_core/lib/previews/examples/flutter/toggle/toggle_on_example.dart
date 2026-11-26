import 'package:coui_flutter/coui_flutter.dart';

class ToggleOnExample extends StatefulWidget {
  const ToggleOnExample({super.key});

  @override
  State<ToggleOnExample> createState() => _ToggleOnExampleState();
}

class _ToggleOnExampleState extends State<ToggleOnExample> {
  bool _value = true;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
      label: '다크 모드',
    );
  }
}
