import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreHeroStyle] slot without constructing the
/// widget from scratch — chained with the primitive-token
/// `.surfaceContainer` getter (a direct 1:1 alias for
/// `CoreColors.surfaceContainer`), which is shorter than a second
/// `.withStyle(const CoreHeroStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
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
}
