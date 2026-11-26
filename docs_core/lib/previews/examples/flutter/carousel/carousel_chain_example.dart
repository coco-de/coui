import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreCarouselStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter than
/// a second `.withStyle(const CoreCarouselStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
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
}
