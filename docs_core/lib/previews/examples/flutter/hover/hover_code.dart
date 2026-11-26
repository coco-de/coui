/// Returns a Flutter code snippet string for the Hover component.
String hoverCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class HoverChainExample extends StatelessWidget {
  const HoverChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.scaleUp,
      child: Card(child: const Text('올려 보세요')),
    ).withStyle(
      const CoreHoverStyle(
        scaleUpFactor: 1.15,
        effectDuration: Duration(milliseconds: CoreDuration.moderate),
        waitDuration: Duration(milliseconds: CoreDuration.fast),
        shadowBoxShadow: CoreShadow.xl,
        shadowBaseColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
''',
    'fade' =>
      '''
class HoverFadeExample extends StatelessWidget {
  const HoverFadeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.fade,
      child: Card(child: const Text('올려 보세요')),
    );
  }
}''',
    'shadow' =>
      '''
class HoverShadowExample extends StatelessWidget {
  const HoverShadowExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.shadow,
      child: Card(
        cardStyle: const CoreCardStyle(boxShadow: CoreShadow.none),
        child: const Text('올려 보세요'),
      ),
    );
  }
}''',
    _ =>
      '''
class HoverDefaultExample extends StatelessWidget {
  const HoverDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.scaleUp,
      child: Card(child: const Text('올려 보세요')),
    );
  }
}''',
  };
}
