import 'package:coui_web/coui_web.dart';

/// `DateRangePicker` with `mode: CorePromptMode.dialog` — opens
/// the range calendar inside a centred [Dialog] with `Cancel` /
/// `Save` actions. The default mode of `DateRangePicker`.
class DatePickerRangeDialogExample extends StatefulComponent {
  const DatePickerRangeDialogExample({super.key});

  @override
  State<DatePickerRangeDialogExample> createState() => _DatePickerRangeDialogExampleState();
}

class _DatePickerRangeDialogExampleState extends State<DatePickerRangeDialogExample> {
  ({String start, String end})? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DateRangePicker(
          onChanged: (v) => setState(() => _value = v),
          value: _value,
          placeholder: Text('기간을 선택해 주세요'),
          dialogTitle: const Text('기간 선택'),
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
