import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreNumberTickerStyle] slot without constructing the
/// component from scratch.
class NumberTickerChainExample extends StatefulComponent {
  const NumberTickerChainExample({super.key});

  @override
  State<NumberTickerChainExample> createState() => _NumberTickerChainExampleState();
}

class _NumberTickerChainExampleState extends State<NumberTickerChainExample> {
  @override
  Component build(BuildContext context) {
    return NumberTicker(value: 1234, initialValue: 0).withStyle(
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
