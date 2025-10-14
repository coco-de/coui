// ignore_for_file: library_private_types_in_public_api
import 'package:coui_flutter/coui_flutter.dart';

class ToggleExample1 extends StatefulWidget {
  const ToggleExample1({super.key});

  @override
  _ToggleExample1State createState() => _ToggleExample1State();
}

class _ToggleExample1State extends State<ToggleExample1> {
  bool value = false;

  @override
  Widget build(BuildContext context) {
    return Toggle(
      onChanged: (v) {
        setState(() {
          value = v;
        });
      },
      trailing: const Text('Toggle'),
      value: value,
    );
  }
}
