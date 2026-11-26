import 'package:coui_flutter/coui_flutter.dart';

class CarouselBannerExample extends StatelessWidget {
  const CarouselBannerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Carousel(
      transition: CarouselTransition.sliding(),
      variant: CoreCarouselVariant.banner,
      items: [
        for (final (title, body) in const [
          ('이번 주 신간', '새 책 세 권이 들어왔어요'),
          ('독서 챌린지', '4월 한 달 동안 책 두 권을 끝까지 읽어 보세요'),
          ('회원 할인', '묶음 상품 20% 할인'),
        ])
          CarouselBanner(
            thumbnail: const Icon(LucideIcons.image),
            title: Text(title),
            description: Text(body),
          ),
      ],
    );
  }
}
