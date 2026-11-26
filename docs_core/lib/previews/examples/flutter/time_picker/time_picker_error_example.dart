import 'package:coui_flutter/coui_flutter.dart';

/// `TimePicker` with `errorText` — renders the trigger with the
/// error border colour (parity with `TextField.errorText`).
class TimePickerErrorExample extends StatefulWidget {
  const TimePickerErrorExample({super.key});

  @override
  State<TimePickerErrorExample> createState() => _TimePickerErrorExampleState();
}

class _TimePickerErrorExampleState extends State<TimePickerErrorExample> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: TimePicker(
        value: _value,
        placeholder: '시간을 선택해 주세요',
        errorText: '시간을 선택해야 해요',
        onChanged: (value) => setState(() => _value = value),
      ),
    );
  }
}
