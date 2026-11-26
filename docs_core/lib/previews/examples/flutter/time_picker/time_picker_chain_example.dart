import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreTimePickerStyle] slot without constructing the
/// widget from scratch.
class TimePickerChainExample extends StatefulWidget {
  const TimePickerChainExample({super.key});

  @override
  State<TimePickerChainExample> createState() => _TimePickerChainExampleState();
}

class _TimePickerChainExampleState extends State<TimePickerChainExample> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child:
          TimePicker(
            value: _value,
            placeholder: '시간을 선택해 주세요',
            onChanged: (value) => setState(() => _value = value),
          ).withStyle(
            const CoreTimePickerStyle(
              segmentBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
              segmentBorderColor: CoreColor.token(CoreColors.primary),
              contentColor: CoreColor.token(CoreColors.primary),
              triggerHeight: CoreSpace.space48,
              triggerBorderWidth: CoreStrokeWidth.stroke2,
              trailingIconStyle: CoreIconStyle(
                size: CoreIconSize.size20,
                color: CoreColor.token(CoreColors.primary),
              ),
            ),
          ),
    );
  }
}
