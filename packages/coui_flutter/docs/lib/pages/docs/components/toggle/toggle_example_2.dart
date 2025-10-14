// ignore_for_file: library_private_types_in_public_api
import 'package:coui_flutter/coui_flutter.dart';

class ToggleExample2 extends StatefulWidget {
  const ToggleExample2({super.key});

  @override
  _ToggleExample2State createState() => _ToggleExample2State();
}

class _ToggleExample2State extends State<ToggleExample2> {
  int flag = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Toggle(
          onChanged: (v) {
            setState(() {
              flag = v ? 0 : -1;
            });
          },
          trailing: const Text('B').bold().center(),
          value: flag == 0,
        ).sized(height: 40, width: 40),
        Toggle(
          onChanged: (v) {
            setState(() {
              flag = v ? 1 : -1;
            });
          },
          trailing: const Text('I').italic().center(),
          value: flag == 1,
        ).sized(height: 40, width: 40),
        Toggle(
          onChanged: (v) {
            setState(() {
              flag = v ? 2 : -1;
            });
          },
          trailing: const Text('U').underline().center(),
          value: flag == 2,
        ).sized(height: 40, width: 40),
      ],
    ).gap(4);
  }
}
