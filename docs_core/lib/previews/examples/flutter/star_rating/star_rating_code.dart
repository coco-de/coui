/// Returns a Flutter code snippet string for the StarRating component.
String starRatingCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
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
}''',
    _ =>
      '''
class StarRatingDefaultExample extends StatefulWidget {
  const StarRatingDefaultExample({super.key});

  @override
  State<StarRatingDefaultExample> createState() =>
      _StarRatingDefaultExampleState();
}

class _StarRatingDefaultExampleState extends State<StarRatingDefaultExample> {
  double _value = 3;

  @override
  Widget build(BuildContext context) {
    return StarRating(
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}''',
  };
}
