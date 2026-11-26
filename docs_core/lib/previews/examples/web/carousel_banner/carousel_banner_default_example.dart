import 'package:coui_web/coui_web.dart';

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
}
