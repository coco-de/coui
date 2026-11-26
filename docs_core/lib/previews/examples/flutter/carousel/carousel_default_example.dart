import 'package:coui_flutter/coui_flutter.dart';

class CarouselDefaultExample extends StatefulWidget {
  const CarouselDefaultExample({super.key});

  @override
  State<CarouselDefaultExample> createState() => _CarouselDefaultExampleState();
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
    );
  }
}
