import 'package:coui_flutter/coui_flutter.dart';

class SwitchFieldDefaultExample extends StatefulWidget {
  const SwitchFieldDefaultExample({super.key});

  @override
  State<SwitchFieldDefaultExample> createState() => _SwitchFieldDefaultExampleState();
}

class _SwitchFieldDefaultExampleState extends State<SwitchFieldDefaultExample> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return SwitchField(
      label: '알림 받기',
      description: '푸시 알림을 받아요.',
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
