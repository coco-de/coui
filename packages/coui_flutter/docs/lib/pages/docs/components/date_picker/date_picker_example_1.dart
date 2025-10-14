import 'package:coui_flutter/coui_flutter.dart';

class DatePickerExample1 extends StatefulWidget {
  const DatePickerExample1({super.key});

  @override
  State<DatePickerExample1> createState() => _DatePickerExample1State();
}

class _DatePickerExample1State extends State<DatePickerExample1> {
  DateTime? _value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DatePicker(
          mode: PromptMode.popover,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
          },
          stateBuilder: (date) {
            if (date.isAfter(DateTime.now())) {
              return DateState.disabled;
            }
            return DateState.enabled;
          },
          value: _value,
        ),
        const Gap(16),
        DatePicker(
          dialogTitle: const Text('Select Date'),
          mode: PromptMode.dialog,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
          },
          stateBuilder: (date) {
            if (date.isAfter(DateTime.now())) {
              return DateState.disabled;
            }
            return DateState.enabled;
          },
          value: _value,
        ),
      ],
    );
  }
}
