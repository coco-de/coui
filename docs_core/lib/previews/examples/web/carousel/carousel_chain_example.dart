import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCarouselStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter than
/// a second `.withStyle(const CoreCarouselStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
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
}
