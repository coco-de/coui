import 'package:coui_flutter/coui_flutter.dart';

import '../carousel_example.dart';

class CarouselExample1 extends StatefulWidget {
  const CarouselExample1({super.key});

  @override
  State<CarouselExample1> createState() => _CarouselExample1State();
}

class _CarouselExample1State extends State<CarouselExample1> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      child: Row(
        children: [
          OutlineButton(
            onPressed: () {
              controller.animatePrevious(const Duration(milliseconds: 500));
            },
            shape: ButtonShape.circle,
            child: const Icon(Icons.arrow_back),
          ),
          const Gap(24),
          Expanded(
            child: SizedBox(
              height: 200,
              child: Carousel(
                autoplaySpeed: const Duration(seconds: 2),
                controller: controller,
                duration: const Duration(seconds: 1),
                itemBuilder: (context, index) {
                  return NumberedContainer(index: index);
                },
                itemCount: 5,
                sizeConstraint: const CarouselFixedConstraint(200),
                // frameTransform: Carousel.fadingTransform,
                transition: const CarouselTransition.sliding(gap: 24),
              ),
            ),
          ),
          const Gap(24),
          OutlineButton(
            onPressed: () {
              controller.animateNext(const Duration(milliseconds: 500));
            },
            shape: ButtonShape.circle,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
