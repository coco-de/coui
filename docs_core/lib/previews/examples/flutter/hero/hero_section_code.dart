/// Returns a Flutter code snippet string for the HeroSection component.
String heroSectionCode(String? variant) {
  return switch (variant) {
    'split' =>
      '''
Hero(
  layout: CoreHeroLayout.split,
  heroStyle: const CoreHeroStyle(minHeight: 280),
  media: Text('미디어').titleMedium.onSurface,
  child: Text('제품을 출시해 보세요').headlineSmall.onSurface,
)''',
    'chain' =>
      '''
class HeroSectionChainExample extends StatelessWidget {
  const HeroSectionChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 280,
      child:
          Hero(
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Text(
                      'CoUI에 오신 것을 환영해요',
                      style: theme.typography.titleLarge
                          .toValue(theme: theme)
                          .copyWith(
                            color: theme.colorScheme.onSurface.toValue(),
                            fontWeight: FontWeight.values.firstWhere(
                              (w) => w.value == CoreFontWeight.semiBold,
                              orElse: () => .w600,
                            ),
                          ),
                    ),
                    const Gap.space12(),
                    Text(
                      'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
                      textAlign: .center,
                      style: theme.typography.bodyMedium
                          .toValue(theme: theme)
                          .copyWith(
                            color: theme.colorScheme.onSurfaceVariant.toValue(),
                          ),
                    ),
                  ],
                ),
              )
              .withStyle(
                const CoreHeroStyle(
                  overlayColor: CoreColor.token(
                    CoreColors.primary,
                    opacity: CoreOpacity.opacity10,
                  ),
                  minHeight: 280,
                  padding: CoreEdgeInsets.all(CoreSpace.space48),
                ),
              )
              .surfaceContainer,
    );
  }
}''',
    'appear' =>
      '''
class HeroSectionAppearExample extends StatelessWidget {
  const HeroSectionAppearExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Hero(
        appear: true,
        semanticLabel: 'CoUI 소개',
        heroStyle: const CoreHeroStyle(minHeight: 280),
        child: Column(
          mainAxisSize: .min,
          children: [
            Text('CoUI에 오신 것을 환영해요').titleLarge.semiBold.onSurface,
            const Gap.space12(),
            Text(
              'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
              textAlign: .center,
            ).bodyMedium.onSurfaceVariant,
          ],
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class HeroSectionDefaultExample extends StatelessWidget {
  const HeroSectionDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 280,
      child: Hero(
        heroStyle: const CoreHeroStyle(minHeight: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CoUI에 오신 것을 환영해요',
              style: theme.typography.titleLarge.toValue(theme: theme).copyWith(
                color: theme.colorScheme.onSurface.toValue(),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap.space12(),
            Text(
              'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
              textAlign: TextAlign.center,
              style: theme.typography.bodyMedium.toValue(theme: theme).copyWith(
                color: theme.colorScheme.onSurfaceVariant.toValue(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}''',
  };
}
