import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreNumberTickerStyle] slot without constructing the
/// widget from scratch.
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
}
