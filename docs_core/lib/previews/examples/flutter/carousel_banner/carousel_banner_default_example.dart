import 'package:coui_flutter/coui_flutter.dart';

class CarouselBannerDefaultExample extends StatelessWidget {
  const CarouselBannerDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return CarouselBanner(
      thumbnail: const Icon(LucideIcons.image),
      title: Text('겨울 시즌 할인'),
      description: Text('12월 31일까지 전 상품 20% 할인'),
    );
  }
}
