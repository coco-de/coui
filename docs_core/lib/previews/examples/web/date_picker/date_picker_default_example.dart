import 'package:coui_web/coui_web.dart';

/// Default `DatePicker` preview — single date selection with the
/// popover layer (`Popover` + `OverlayHost.popover`).
///
/// Wrapped in a fixed-width 256 px box so the trigger renders at the
/// same width as the Flutter preview (`SizedBox(width: CoreSpace.
/// space256)`), keeping cross-platform visual parity inside the
/// docs preview pane.
class DatePickerDefaultExample extends StatefulComponent {
  const DatePickerDefaultExample({super.key});

  @override
  State<DatePickerDefaultExample> createState() => _DatePickerDefaultExampleState();
}

class _DatePickerDefaultExampleState extends State<DatePickerDefaultExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DatePicker(
          onChanged: (v) => setState(() => _value = v),
          placeholder: '날짜를 선택해 주세요',
          value: _value,
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
