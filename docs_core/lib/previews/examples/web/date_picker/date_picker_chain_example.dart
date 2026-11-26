import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreDatePickerStyle] slot without constructing the
/// component from scratch.
class DatePickerChainExample extends StatefulComponent {
  const DatePickerChainExample({super.key});

  @override
  State<DatePickerChainExample> createState() => _DatePickerChainExampleState();
}

class _DatePickerChainExampleState extends State<DatePickerChainExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
        DatePicker(
          onChanged: (v) => setState(() => _value = v),
          placeholder: '날짜를 선택해 주세요',
          value: _value,
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
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
