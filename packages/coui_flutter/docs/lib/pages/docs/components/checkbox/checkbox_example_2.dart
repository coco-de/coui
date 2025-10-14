import 'package:coui_flutter/coui_flutter.dart';

class CheckboxExample2 extends StatefulWidget {
  const CheckboxExample2({super.key});

  @override
  State<CheckboxExample2> createState() => _CheckboxExample2State();
}

class _CheckboxExample2State extends State<CheckboxExample2> {
  CheckboxState _state = CheckboxState.unchecked;
  @override
  Widget build(BuildContext context) {
    return Checkbox(
      onChanged: (value) {
        setState(() {
          _state = value;
        });
      },
      state: _state,
      trailing: const Text('Remember me'),
      tristate: true,
    );
  }
}
