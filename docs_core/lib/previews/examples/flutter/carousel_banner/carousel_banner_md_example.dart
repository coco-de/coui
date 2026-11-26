import 'package:coui_flutter/coui_flutter.dart';

class CarouselBannerMdExample extends StatelessWidget {
  const CarouselBannerMdExample({super.key});

  @override
  Widget build(BuildContext context) {
    return CarouselBanner(
      size: CoreCarouselBannerSize.md,
      thumbnail: const Icon(LucideIcons.image),
      title: Text('회원 할인'),
      description: Text('4월 말까지 묶음 상품 20% 할인'),
    );
  }
}
