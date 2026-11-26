import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCarouselBannerStyle] slot without constructing the
/// widget from scratch. The strip has no primitive-token getter axis, so
/// full control is the whole chain here.
class CarouselBannerChainExample extends StatelessWidget {
  const CarouselBannerChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
}
