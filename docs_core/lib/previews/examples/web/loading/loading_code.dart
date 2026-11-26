/// Returns a Web code snippet string for the Loading component.
String loadingCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class LoadingChainExample extends StatelessComponent {
  const LoadingChainExample({super.key});

  @override
  Component build(BuildContext context) {
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
class LoadingDotsExample extends StatelessComponent {
  const LoadingDotsExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.dots);
  }
}''',
    'bar' =>
      '''
class LoadingBarExample extends StatelessComponent {
  const LoadingBarExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.bar);
  }
}''',
    'pulse' =>
      '''
class LoadingPulseExample extends StatelessComponent {
  const LoadingPulseExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.pulse);
  }
}''',
    _ =>
      '''
class LoadingDefaultExample extends StatelessComponent {
  const LoadingDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Loading();
  }
}''',
  };
}
