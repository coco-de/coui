import 'package:coui_flutter/coui_flutter.dart';

/// `DateRangePicker` with `mode: CorePromptMode.dialog` — opens the
/// range calendar inside a centred [Dialog] with `Cancel` /
/// `Save` actions. The default mode of `DateRangePicker`.
class DatePickerRangeDialogExample extends StatefulWidget {
  const DatePickerRangeDialogExample({super.key});

  @override
  State<DatePickerRangeDialogExample> createState() => _DatePickerRangeDialogExampleState();
}

class _DatePickerRangeDialogExampleState extends State<DatePickerRangeDialogExample> {
  DateTimeRange? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: DateRangePicker(
        onChanged: (v) => setState(() => _value = v),
        value: _value,
        placeholder: const Text('기간을 선택해 주세요'),
        dialogTitle: const Text('기간 선택'),
      ),
    );
  }
}
