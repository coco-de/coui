import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDatePickerStyle] slot without constructing the
/// widget from scratch.
class DatePickerChainExample extends StatefulWidget {
  const DatePickerChainExample({super.key});

  @override
  State<DatePickerChainExample> createState() => _DatePickerChainExampleState();
}

class _DatePickerChainExampleState extends State<DatePickerChainExample> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child:
          ControlledDatePicker(
            placeholder: '날짜를 선택해 주세요',
            onChanged: (_) {},
          ).withStyle(
            const CoreDatePickerStyle(
              contentColor: CoreColor.token(CoreColors.primary),
              placeholderColor: CoreColor.token(CoreColors.onSurfaceVariant),
              valueTypography: CoreTextStyle.token(CoreTextStyles.bodyLarge),
              trailingIconStyle: CoreIconStyle(
                size: CoreSize.size20,
                color: CoreColor.token(CoreColors.primary),
              ),
            ),
          ),
    );
  }
}
