import 'package:coui_flutter/coui_flutter.dart';

/// `TimePicker` with `mode: CorePromptMode.dialog` — opens the
/// time selection panel inside a centred dialog with `Cancel` / `Save`
/// actions instead of a popover anchored to the trigger.
class TimePickerDialogExample extends StatefulWidget {
  const TimePickerDialogExample({super.key});

  @override
  State<TimePickerDialogExample> createState() => _TimePickerDialogExampleState();
}

class _TimePickerDialogExampleState extends State<TimePickerDialogExample> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: TimePicker(
        value: _value,
        placeholder: '시간을 선택해 주세요',
        mode: CorePromptMode.dialog,
        dialogTitle: const Text('시간 선택'),
        onChanged: (value) => setState(() => _value = value),
      ),
    );
  }
}
