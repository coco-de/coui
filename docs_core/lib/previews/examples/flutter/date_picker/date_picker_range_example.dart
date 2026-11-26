import 'package:coui_flutter/coui_flutter.dart';

/// `DateRangePicker` with the popover layer — opens a range
/// calendar in a [Popover] anchored under the trigger. Picking
/// `start` and `end` commits the range and closes the popover.
class DatePickerRangeExample extends StatefulWidget {
  const DatePickerRangeExample({super.key});

  @override
  State<DatePickerRangeExample> createState() => _DatePickerRangeExampleState();
}

class _DatePickerRangeExampleState extends State<DatePickerRangeExample> {
  DateTimeRange? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: DateRangePicker(
        onChanged: (v) => setState(() => _value = v),
        value: _value,
        mode: CorePromptMode.popover,
        placeholder: const Text('기간을 선택해 주세요'),
      ),
    );
  }
}
