/// Returns a Web code snippet string for the HeroSection component.
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
class HeroSectionChainExample extends StatelessComponent {
  const HeroSectionChainExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return div(
      [
        Hero(
              child: div(
                [
                  div(
                    [Text('CoUI에 오신 것을 환영해요')],
                    classes:
                        'text-\${CoreTextStyles.titleLarge.name} font-\${CoreFontWeight.scale.semibold} text-\${cs.onSurface}',
                  ),
                  const Gap.space12(),
                  div(
                    [
                      Text(
                        'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
                      ),
                    ],
                    classes: 'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurfaceVariant} text-center',
                  ),
                ],
                classes: 'flex flex-col items-center',
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
      ],
      // w-full 은 클래스로 — docs 의 폭 부여 룰(:has(.w-full))이
      // 클래스만 매칭해서 inline width 로는 래퍼가 content-size 로 남는다.
      classes: 'w-full',
      styles: const Styles(raw: {'height': '280px'}),
    );
  }
}''',
    'appear' =>
      '''
class HeroSectionAppearExample extends StatelessComponent {
  const HeroSectionAppearExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Hero(
          appear: true,
          semanticLabel: 'CoUI 소개',
          heroStyle: const CoreHeroStyle(minHeight: 280),
          child: div(
            [
              Text('CoUI에 오신 것을 환영해요').titleLarge.semiBold.onSurface,
              const Gap.space12(),
              Text(
                'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
                textAlign: .center,
              ).bodyMedium.onSurfaceVariant,
            ],
            classes: 'flex flex-col items-center',
          ),
        ),
      ],
      classes: 'w-full',
      styles: const Styles(raw: {'height': '280px'}),
    );
  }
}''',
    _ =>
      '''
class HeroSectionDefaultExample extends StatelessComponent {
  const HeroSectionDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return div(
      [
        Hero(
          heroStyle: const CoreHeroStyle(minHeight: 280),
          child: div(
            [
              div(
                [Text('CoUI에 오신 것을 환영해요')],
                classes:
                    'text-\${CoreTextStyles.titleLarge.name} font-\${CoreFontWeight.scale.semibold} text-\${cs.onSurface}',
              ),
              const Gap.space12(),
              div(
                [
                  Text(
                    'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
                  ),
                ],
                classes:
                    'text-\${CoreTextStyles.bodyMedium.name} text-\${cs.onSurfaceVariant} text-center',
              ),
            ],
            classes: 'flex flex-col items-center',
          ),
        ),
      ],
      // w-full 은 클래스로 — docs 의 폭 부여 룰(:has(.w-full))이
      // 클래스만 매칭해서 inline width 로는 래퍼가 content-size 로 남는다.
      classes: 'w-full',
      styles: const Styles(raw: {'height': '280px'}),
    );
  }
}''',
  };
}
