/// Returns a Flutter code snippet string for the Loading component.
String loadingCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class LoadingChainExample extends StatelessWidget {
  const LoadingChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading().withStyle(
      const CoreLoadingStyle(
        color: CoreColor.token(CoreColors.tertiary),
        trackColor: CoreColor.token(CoreColors.surfaceContainerHighest),
        size: CoreSize.size48,
        strokeWidth: CoreStrokeWidth.stroke4,
      ),
    );
  }
}''',
    'dots' =>
      '''
class LoadingDotsExample extends StatelessWidget {
  const LoadingDotsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.dots);
  }
}''',
    'bar' =>
      '''
class LoadingBarExample extends StatelessWidget {
  const LoadingBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.bar);
  }
}''',
    'pulse' =>
      '''
class LoadingPulseExample extends StatelessWidget {
  const LoadingPulseExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.pulse);
  }
}''',
    _ =>
      '''
class LoadingDefaultExample extends StatelessWidget {
  const LoadingDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading();
  }
}''',
  };
}
