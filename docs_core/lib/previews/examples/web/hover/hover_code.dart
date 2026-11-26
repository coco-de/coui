/// Returns a Web code snippet string for the Hover component.
String hoverCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class HoverChainExample extends StatelessComponent {
  const HoverChainExample({super.key});

  @override
  Component build(BuildContext context) {
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
class HoverFadeExample extends StatelessComponent {
  const HoverFadeExample({super.key});

  @override
  Component build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.fade,
      child: Card(child: const Text('올려 보세요')),
    );
  }
}''',
    'shadow' =>
      '''
class HoverShadowExample extends StatelessComponent {
  const HoverShadowExample({super.key});

  @override
  Component build(BuildContext context) {
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
class HoverDefaultExample extends StatelessComponent {
  const HoverDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Hover(
      effect: CoreHoverEffect.scaleUp,
      child: Card(child: const Text('올려 보세요')),
    );
  }
}''',
  };
}
