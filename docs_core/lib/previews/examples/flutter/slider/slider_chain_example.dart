import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSliderStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter
/// than a second `.withStyle(const CoreSliderStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
class SliderChainExample extends StatefulWidget {
  const SliderChainExample({super.key});

  @override
  State<SliderChainExample> createState() => _SliderChainExampleState();
}

class _SliderChainExampleState extends State<SliderChainExample> {
  double _value = 50;

  @override
  Widget build(BuildContext context) {
    return Slider(
          value: _value,
          min: 0,
          max: 100,
          onChanged: (v) => setState(() => _value = v),
        )
        .withStyle(
          const CoreSliderStyle(
            trackHeight: CoreSpace.space12,
            thumbSize: CoreSpace.space24,
            activeColor: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
