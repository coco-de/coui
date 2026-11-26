import 'package:coui_web/coui_web.dart';

class CarouselBannerExample extends StatefulComponent {
  const CarouselBannerExample({super.key});

  @override
  State<CarouselBannerExample> createState() => _CarouselBannerExampleState();
}

class _CarouselBannerExampleState extends State<CarouselBannerExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return Carousel(
      currentIndex: _index,
      onIndexChanged: (idx) => setState(() => _index = idx),
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
