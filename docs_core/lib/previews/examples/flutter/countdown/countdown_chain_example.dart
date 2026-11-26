import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCountdownStyle] slot without constructing the widget
/// from scratch.
class CountdownChainExample extends StatefulWidget {
  const CountdownChainExample({super.key});

  @override
  State<CountdownChainExample> createState() => _CountdownChainExampleState();
}

class _CountdownChainExampleState extends State<CountdownChainExample> {
  @override
  Widget build(BuildContext context) {
    return const Countdown(value: 42).withStyle(
      const CoreCountdownStyle(
        fontSize: CoreFontSize.s48,
        color: CoreColor.token(CoreColors.primary),
        animationDuration: Duration(milliseconds: CoreDuration.moderate),
      ),
    );
  }
}
