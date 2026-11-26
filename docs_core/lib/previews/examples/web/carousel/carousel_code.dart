/// Returns a Web code snippet string for the Carousel component.
String carouselCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CarouselChainExample extends StatefulComponent {
  const CarouselChainExample({super.key});

  @override
  State<CarouselChainExample> createState() => _CarouselChainExampleState();
}

class _CarouselChainExampleState extends State<CarouselChainExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return Carousel(
          currentIndex: _index,
          onIndexChanged: (idx) => setState(() => _index = idx),
          items: [
            div(
              [Text('슬라이드 1')],
              styles: Styles(
                raw: {
                  'background': '#3B82F6',
                  'color': 'white',
                  'font-size': '18px',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                  'padding': 'var(--coui-space-64)',
                },
              ),
            ),
            div(
              [Text('슬라이드 2')],
              styles: Styles(
                raw: {
                  'background': '#22C55E',
                  'color': 'white',
                  'font-size': '18px',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                  'padding': 'var(--coui-space-64)',
                },
              ),
            ),
            div(
              [Text('슬라이드 3')],
              styles: Styles(
                raw: {
                  'background': '#F97316',
                  'color': 'white',
                  'font-size': '18px',
                  'display': 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                  'padding': 'var(--coui-space-64)',
                },
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
}''',
    _ =>
      '''
class CarouselDefaultExample extends StatefulComponent {
  const CarouselDefaultExample({super.key});

  @override
  State<CarouselDefaultExample> createState() =>
      _CarouselDefaultExampleState();
}

class _CarouselDefaultExampleState extends State<CarouselDefaultExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return Carousel(
      currentIndex: _index,
      onIndexChanged: (idx) => setState(() => _index = idx),
      items: [
        div(
          [Text('슬라이드 1')],
          styles: Styles(raw: {
            'background': '#3B82F6',
            'color': 'white',
            'font-size': '18px',
            'display': 'flex',
            'align-items': 'center',
            'justify-content': 'center',
            'padding': 'var(--coui-space-64)',
          }),
        ),
        div(
          [Text('슬라이드 2')],
          styles: Styles(raw: {
            'background': '#22C55E',
            'color': 'white',
            'font-size': '18px',
            'display': 'flex',
            'align-items': 'center',
            'justify-content': 'center',
            'padding': 'var(--coui-space-64)',
          }),
        ),
        div(
          [Text('슬라이드 3')],
          styles: Styles(raw: {
            'background': '#F97316',
            'color': 'white',
            'font-size': '18px',
            'display': 'flex',
            'align-items': 'center',
            'justify-content': 'center',
            'padding': 'var(--coui-space-64)',
          }),
        ),
      ],
    );
  }
}''',
  };
}
