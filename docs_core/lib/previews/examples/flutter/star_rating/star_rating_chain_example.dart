import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreStarRatingStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.primary` getter (a
/// direct 1:1 alias for `CoreColors.primary`), which is shorter than a
/// second `.withStyle(const CoreStarRatingStyle(backgroundColor:
/// CoreColor.token(CoreColors.primary)))` call.
class StarRatingChainExample extends StatefulWidget {
  const StarRatingChainExample({super.key});

  @override
  State<StarRatingChainExample> createState() => _StarRatingChainExampleState();
}

class _StarRatingChainExampleState extends State<StarRatingChainExample> {
  double _value = 3;

  @override
  Widget build(BuildContext context) {
    return StarRating(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
        )
        .withStyle(
          const CoreStarRatingStyle(
            starSize: CoreSpace.space32,
            starSpacing: CoreSpace.space12,
            activeColor: CoreColor.token(CoreColors.warning),
          ),
        )
        .primary;
  }
}
