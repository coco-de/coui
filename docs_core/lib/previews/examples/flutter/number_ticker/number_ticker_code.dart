/// Returns a Flutter code snippet string for the NumberTicker component.
String numberTickerCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class NumberTickerChainExample extends StatefulWidget {
  const NumberTickerChainExample({super.key});

  @override
  State<NumberTickerChainExample> createState() => _NumberTickerChainExampleState();
}

class _NumberTickerChainExampleState extends State<NumberTickerChainExample> {
  @override
  Widget build(BuildContext context) {
    return NumberTicker(
      value: 1234,
      initialValue: 0,
    ).withStyle(
      const CoreNumberTickerStyle(
        duration: Duration(milliseconds: CoreDuration.slow),
        textStyle: CoreTextStyle.token(
          CoreTextStyles.headlineSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class NumberTickerDefaultExample extends StatefulWidget {
  const NumberTickerDefaultExample({super.key});

  @override
  State<NumberTickerDefaultExample> createState() =>
      _NumberTickerDefaultExampleState();
}

class _NumberTickerDefaultExampleState
    extends State<NumberTickerDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return NumberTicker(
      value: 1234,
      initialValue: 0,
    );
  }
}''',
  };
}
