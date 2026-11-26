import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreHeroStyle] slot without constructing the
/// component from scratch — chained with the primitive-token
/// `.surfaceContainer` getter (a direct 1:1 alias for
/// `CoreColors.surfaceContainer`), which is shorter than a second
/// `.withStyle(const CoreHeroStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
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
                        'text-${CoreTextStyles.titleLarge.name} font-${CoreFontWeight.scale.semibold} text-${cs.onSurface}',
                  ),
                  const Gap.space12(),
                  div(
                    [
                      Text(
                        'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
                      ),
                    ],
                    classes: 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurfaceVariant} text-center',
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
}
