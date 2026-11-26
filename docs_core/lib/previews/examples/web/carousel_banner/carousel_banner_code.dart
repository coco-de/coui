/// Web code snippets for the `CarouselBanner` docs page.
library;

String carouselBannerWebCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CarouselBannerChainExample extends StatelessComponent {
  const CarouselBannerChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return CarouselBanner(
      thumbnail: const Icon(LucideIcons.image),
      title: Text('회원 할인'),
      description: Text('묶음 상품 20% 할인'),
    ).withStyle(
      const CoreCarouselBannerStyle(
        backgroundColor: CoreColor.token(CoreColors.secondaryContainer),
        thumbnailBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    );
  }
}''',
    'md' =>
      '''
class CarouselBannerMdExample extends StatelessComponent {
  const CarouselBannerMdExample({super.key});

  @override
  Component build(BuildContext context) {
    return CarouselBanner(
      size: CoreCarouselBannerSize.md,
      thumbnail: const Icon(LucideIcons.image),
      title: Text('회원 할인'),
      description: Text('4월 말까지 묶음 상품 20% 할인'),
    );
  }
}''',
    _ =>
      '''
class CarouselBannerDefaultExample extends StatelessComponent {
  const CarouselBannerDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return CarouselBanner(
      thumbnail: const Icon(LucideIcons.image),
      title: Text('겨울 시즌 할인'),
      description: Text('12월 31일까지 전 상품 20% 할인'),
    );
  }
}''',
  };
}
