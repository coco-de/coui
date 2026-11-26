import 'package:coui_flutter/coui_flutter.dart';

/// `DatePicker` with `mode: CorePromptMode.dialog` — opens the
/// calendar inside a centred [Dialog] with `Cancel` / `Save`
/// actions instead of a popover anchored to the trigger.
class DatePickerDialogExample extends StatefulWidget {
  const DatePickerDialogExample({super.key});

  @override
  State<DatePickerDialogExample> createState() => _DatePickerDialogExampleState();
}

class _DatePickerDialogExampleState extends State<DatePickerDialogExample> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: DatePicker(
        onChanged: (v) => setState(() => _value = v),
        value: _value,
        mode: CorePromptMode.dialog,
        placeholder: '날짜를 선택해 주세요',
        dialogTitle: const Text('날짜 선택'),
      ),
    );
  }
}
