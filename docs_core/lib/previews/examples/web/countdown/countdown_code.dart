/// Returns a Web code snippet string for the Countdown component.
String countdownCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
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
}''',
    _ =>
      '''
class CountdownDefaultExample extends StatefulComponent {
  const CountdownDefaultExample({super.key});

  @override
  State<CountdownDefaultExample> createState() =>
      _CountdownDefaultExampleState();
}

class _CountdownDefaultExampleState extends State<CountdownDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Countdown(value: 42);
  }
}''',
  };
}
