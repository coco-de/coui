import 'package:coui_web/coui_web.dart';

/// Default `TimePicker` preview — single time selection with the
/// popover layer (`Popover` + `OverlayHost.popover`).
///
/// Wrapped in a fixed-width 256 px box so the trigger renders at the
/// same width as the Flutter preview (`SizedBox(width: CoreSpace.
/// space256)`), keeping cross-platform visual parity inside the docs
/// preview pane.
class TimePickerDefaultExample extends StatefulComponent {
  const TimePickerDefaultExample({super.key});

  @override
  State<TimePickerDefaultExample> createState() => _TimePickerDefaultExampleState();
}

class _TimePickerDefaultExampleState extends State<TimePickerDefaultExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        TimePicker(
          value: _value,
          placeholder: '시간을 선택해 주세요',
          onChanged: (value) => setState(() => _value = value),
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
