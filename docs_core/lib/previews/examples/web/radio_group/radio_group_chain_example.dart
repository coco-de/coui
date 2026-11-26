import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreRadioGroupStyle] slot without constructing the widget
/// from scratch.
class RadioGroupChainExample extends StatefulComponent {
  const RadioGroupChainExample({super.key});

  @override
  State<RadioGroupChainExample> createState() => _RadioGroupChainExampleState();
}

class _RadioGroupChainExampleState extends State<RadioGroupChainExample> {
  String? _selected = 'option1';

  @override
  Component build(BuildContext context) {
    return RadioGroup(
      value: _selected,
      onChanged: (v) => setState(() => _selected = v),
      options: const [
        (value: 'option1', label: '옵션 1'),
        (value: 'option2', label: '옵션 2'),
        (value: 'option3', label: '옵션 3'),
      ],
    ).withStyle(
      const CoreRadioGroupStyle(
        indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
        indicatorBorderColor: CoreColor.token(CoreColors.tertiary),
        indicatorBorderWidth: CoreStrokeWidth.stroke3,
        selectedIndicatorBorderWidth: CoreStrokeWidth.stroke6,
        indicatorSize: CoreSize.size24,
        itemSpacing: CoreSpace.space16,
      ),
    );
  }
}
