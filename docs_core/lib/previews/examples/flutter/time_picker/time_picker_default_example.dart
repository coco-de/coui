import 'package:coui_flutter/coui_flutter.dart';

/// Default `TimePicker` preview — single time selection in popover mode.
///
/// Wrapped in a fixed-width box so the trigger renders at the same
/// width as the Web preview (`w-${CoreSpace.scale.space256}` ≈ 256 px),
/// keeping cross-platform visual parity inside the docs preview pane.
class TimePickerDefaultExample extends StatefulWidget {
  const TimePickerDefaultExample({super.key});

  @override
  State<TimePickerDefaultExample> createState() => _TimePickerDefaultExampleState();
}

class _TimePickerDefaultExampleState extends State<TimePickerDefaultExample> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: TimePicker(
        value: _value,
        placeholder: '시간을 선택해 주세요',
        onChanged: (value) => setState(() => _value = value),
      ),
    );
  }
}
