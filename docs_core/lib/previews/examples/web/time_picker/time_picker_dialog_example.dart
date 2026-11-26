import 'package:coui_web/coui_web.dart';

/// `TimePicker` with `mode: CorePromptMode.dialog` — opens the
/// time selection panel inside a centred [Dialog] with `Cancel` /
/// `Save` actions instead of a popover anchored to the trigger.
class TimePickerDialogExample extends StatefulComponent {
  const TimePickerDialogExample({super.key});

  @override
  State<TimePickerDialogExample> createState() => _TimePickerDialogExampleState();
}

class _TimePickerDialogExampleState extends State<TimePickerDialogExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          mode: CorePromptMode.dialog,
          dialogTitle: Text('시간 선택'),
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
