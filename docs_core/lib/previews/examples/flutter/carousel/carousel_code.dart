/// Returns a Flutter code snippet string for the Carousel component.
String carouselCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CarouselChainExample extends StatefulWidget {
  const CarouselChainExample({super.key});

  @override
  State<CarouselChainExample> createState() => _CarouselChainExampleState();
}

class _CarouselChainExampleState extends State<CarouselChainExample> {
  @override
  Widget build(BuildContext context) {
    return Carousel(
          transition: CarouselTransition.sliding(),
          items: [
            Container(
              alignment: Alignment.center,
              color: const Color(0xFF3B82F6),
              padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
              child: const Text(
                '슬라이드 1',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Container(
              alignment: Alignment.center,
              color: const Color(0xFF22C55E),
              padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
              child: const Text(
                '슬라이드 2',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Container(
              alignment: Alignment.center,
              color: const Color(0xFFF97316),
              padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
              child: const Text(
                '슬라이드 3',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        )
        .withStyle(
          const CoreCarouselStyle(
            indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
            indicatorSize: CoreSpace.space12,
            indicatorSpacing: CoreSpace.space12,
          ),
        )
        .radius16;
  }
}''',
    'banner' =>
      '''
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
}''',
    _ =>
      '''
class CarouselDefaultExample extends StatefulWidget {
  const CarouselDefaultExample({super.key});

  @override
  State<CarouselDefaultExample> createState() =>
      _CarouselDefaultExampleState();
}

class _CarouselDefaultExampleState extends State<CarouselDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return Carousel(
      transition: CarouselTransition.sliding(),
      items: [
        Container(
          alignment: Alignment.center,
          color: const Color(0xFF3B82F6),
          padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
          child: const Text('슬라이드 1',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
        Container(
          alignment: Alignment.center,
          color: const Color(0xFF22C55E),
          padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
          child: const Text('슬라이드 2',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
        Container(
          alignment: Alignment.center,
          color: const Color(0xFFF97316),
          padding: const CoreEdgeInsets.all(CoreSpace.space64).toValue(geometry: Theme.of(context).geometry),
          child: const Text('슬라이드 3',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ],
    );
  }
}''',
  };
}
