import 'package:coui_web/coui_web.dart';

/// `TimePicker` with `showSeconds: true` — adds a third numeric
/// segment (`HH:MM:SS`) and exchanges seconds-precision ISO strings.
class TimePickerSecondsExample extends StatefulComponent {
  const TimePickerSecondsExample({super.key});

  @override
  State<TimePickerSecondsExample> createState() => _TimePickerSecondsExampleState();
}

class _TimePickerSecondsExampleState extends State<TimePickerSecondsExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          showSeconds: true,
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
