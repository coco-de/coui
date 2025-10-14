import 'package:coui_flutter/coui_flutter.dart';

class SwitchExample1 extends StatefulWidget {
  const SwitchExample1({super.key});

  @override
  State<SwitchExample1> createState() => _SwitchExample1State();
}

class _SwitchExample1State extends State<SwitchExample1> {
  bool value = false;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return Switch(
      onChanged: (value) {
        setState(() {
          this.value = value;
        });
      },
      value: value,
    );
  }
}
