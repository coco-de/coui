import 'package:coui_flutter/coui_flutter.dart';

class ToggleDisabledExample extends StatefulWidget {
  const ToggleDisabledExample({super.key});

  @override
  State<ToggleDisabledExample> createState() => _ToggleDisabledExampleState();
}

class _ToggleDisabledExampleState extends State<ToggleDisabledExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      value: _value,
      enabled: false,
      label: '다크 모드',
      onChanged: (value) {
        setState(() {
          _value = value;
        });
      },
    );
  }
}
