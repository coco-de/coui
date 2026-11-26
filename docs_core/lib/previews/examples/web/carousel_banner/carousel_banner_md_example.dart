import 'package:coui_web/coui_web.dart';

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
}
