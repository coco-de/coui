import 'package:coui_flutter/coui_flutter.dart';

import '../carousel_example.dart';

class CarouselExample4 extends StatefulWidget {
  const CarouselExample4({super.key});

  @override
  State<CarouselExample4> createState() => _CarouselExample4State();
}

class _CarouselExample4State extends State<CarouselExample4> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 200,
      child: Carousel(
        autoplaySpeed: const Duration(seconds: 2),
        controller: controller,
        curve: Curves.linear,
        draggable: false,
        duration: Duration.zero,
        itemBuilder: (context, index) {
          return NumberedContainer(index: index);
        },
        itemCount: 5,
        sizeConstraint: const CarouselSizeConstraint.fixed(200),
        transition: const CarouselTransition.sliding(gap: 24),
      ),
    );
  }
}
