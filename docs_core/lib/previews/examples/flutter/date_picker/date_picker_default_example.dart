import 'package:coui_flutter/coui_flutter.dart';

/// Default `DatePicker` preview — single date selection in
/// `CorePromptMode.popover` (the picker's default).
///
/// Wrapped in a fixed-width box so the trigger renders at the same
/// width as the Web preview (`w-${CoreSpace.scale.space256}` ≈ 256 px),
/// keeping cross-platform visual parity inside the docs preview pane.
class DatePickerDefaultExample extends StatefulWidget {
  const DatePickerDefaultExample({super.key});

  @override
  State<DatePickerDefaultExample> createState() => _DatePickerDefaultExampleState();
}

class _DatePickerDefaultExampleState extends State<DatePickerDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: DatePicker.simple(
        placeholder: '날짜를 선택해 주세요',
        onChanged: (_) {},
      ),
    );
  }
}
