import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreTimePickerStyle] slot without constructing the
/// component from scratch.
class TimePickerChainExample extends StatefulComponent {
  const TimePickerChainExample({super.key});

  @override
  State<TimePickerChainExample> createState() => _TimePickerChainExampleState();
}

class _TimePickerChainExampleState extends State<TimePickerChainExample> {
  String? _value;

  @override
  Component build(BuildContext context) {
    return div(
      [
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
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
