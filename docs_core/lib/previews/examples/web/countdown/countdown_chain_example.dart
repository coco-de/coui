import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCountdownStyle] slot without constructing the
/// component from scratch.
class CountdownChainExample extends StatefulComponent {
  const CountdownChainExample({super.key});

  @override
  State<CountdownChainExample> createState() => _CountdownChainExampleState();
}

class _CountdownChainExampleState extends State<CountdownChainExample> {
  @override
  Component build(BuildContext context) {
    return Countdown(value: 42).withStyle(
      const CoreCountdownStyle(
        fontSize: CoreFontSize.s48,
        color: CoreColor.token(CoreColors.primary),
        animationDuration: Duration(milliseconds: CoreDuration.moderate),
      ),
    );
  }
}
