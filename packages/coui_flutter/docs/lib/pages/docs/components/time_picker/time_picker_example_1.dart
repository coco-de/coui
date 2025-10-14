import 'package:coui_flutter/coui_flutter.dart';

class TimePickerExample1 extends StatefulWidget {
  const TimePickerExample1({super.key});

  @override
  State<TimePickerExample1> createState() => _TimePickerExample1State();
}

class _TimePickerExample1State extends State<TimePickerExample1> {
  TimeOfDay _value = TimeOfDay.now();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimePicker(
          mode: PromptMode.popover,
          onChanged: (value) {
            setState(() {
              _value = value ?? TimeOfDay.now();
            });
          },
          value: _value,
        ),
        const Gap(16),
        TimePicker(
          dialogTitle: const Text('Select Time'),
          mode: PromptMode.dialog,
          onChanged: (value) {
            setState(() {
              _value = value ?? TimeOfDay.now();
            });
          },
          value: _value,
        ),
      ],
    );
  }
}
