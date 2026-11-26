import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreRangeStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter
/// than a second `.withStyle(const CoreRangeStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
class RangeChainExample extends StatefulComponent {
  const RangeChainExample({super.key});

  @override
  State<RangeChainExample> createState() => _RangeChainExampleState();
}

class _RangeChainExampleState extends State<RangeChainExample> {
  double _min = 20;
  double _max = 80;

  @override
  Component build(BuildContext context) {
    return Range(
          minValue: _min,
          maxValue: _max,
          onChanged: (min, max) => setState(() {
            _min = min;
            _max = max;
          }),
        )
        .withStyle(
          const CoreRangeStyle(
            trackHeight: CoreSpace.space12,
            thumbSize: CoreSpace.space24,
            activeTrackColor: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
