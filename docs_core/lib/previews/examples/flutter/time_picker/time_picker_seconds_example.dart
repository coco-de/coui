import 'package:coui_flutter/coui_flutter.dart';

/// `TimePicker` with `showSeconds: true` — adds a third numeric
/// segment (`HH:MM:SS`) and exchanges seconds-precision ISO strings.
class TimePickerSecondsExample extends StatefulWidget {
  const TimePickerSecondsExample({super.key});

  @override
  State<TimePickerSecondsExample> createState() => _TimePickerSecondsExampleState();
}

class _TimePickerSecondsExampleState extends State<TimePickerSecondsExample> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: TimePicker(
        value: _value,
        placeholder: '시간을 선택해 주세요',
        showSeconds: true,
        onChanged: (value) => setState(() => _value = value),
      ),
    );
  }
}
