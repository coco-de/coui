/// Returns a Flutter code snippet string for the Range component.
String rangeCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class RangeChainExample extends StatefulWidget {
  const RangeChainExample({super.key});

  @override
  State<RangeChainExample> createState() => _RangeChainExampleState();
}

class _RangeChainExampleState extends State<RangeChainExample> {
  double _min = 20;
  double _max = 80;

  @override
  Widget build(BuildContext context) {
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
''',
    _ =>
      '''
class RangeDefaultExample extends StatefulWidget {
  const RangeDefaultExample({super.key});

  @override
  State<RangeDefaultExample> createState() => _RangeDefaultExampleState();
}

class _RangeDefaultExampleState extends State<RangeDefaultExample> {
  double _min = 20;
  double _max = 80;

  @override
  Widget build(BuildContext context) {
    return Range(
      minValue: _min,
      maxValue: _max,
      onChanged: (min, max) => setState(() {
        _min = min;
        _max = max;
      }),
    );
  }
}''',
  };
}
