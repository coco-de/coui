import 'package:coui_web/coui_web.dart';

/// `DateRangePicker` with the popover layer — opens a range
/// calendar in [Popover] anchored under the trigger. Picking
/// `start` and `end` commits the range and closes the popover.
class DatePickerRangeExample extends StatefulComponent {
  const DatePickerRangeExample({super.key});

  @override
  State<DatePickerRangeExample> createState() => _DatePickerRangeExampleState();
}

class _DatePickerRangeExampleState extends State<DatePickerRangeExample> {
  ({String start, String end})? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DateRangePicker(
          onChanged: (v) => setState(() => _value = v),
          value: _value,
          mode: CorePromptMode.popover,
          placeholder: Text('기간을 선택해 주세요'),
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
