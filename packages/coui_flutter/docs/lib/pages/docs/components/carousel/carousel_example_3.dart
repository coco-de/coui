import 'package:coui_flutter/coui_flutter.dart';

import '../carousel_example.dart';

class CarouselExample3 extends StatefulWidget {
  const CarouselExample3({super.key});

  @override
  State<CarouselExample3> createState() => _CarouselExample3State();
}

class _CarouselExample3State extends State<CarouselExample3> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: Carousel(
              autoplaySpeed: const Duration(seconds: 1),
              controller: controller,
              draggable: false,
              duration: const Duration(seconds: 1),
              itemBuilder: (context, index) {
                return NumberedContainer(index: index);
              },
              itemCount: 5,
              transition: const CarouselTransition.fading(),
            ),
          ),
          const Gap(8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarouselDotIndicator(controller: controller, itemCount: 5),
              const Spacer(),
              OutlineButton(
                onPressed: () {
                  controller.animatePrevious(const Duration(milliseconds: 500));
                },
                shape: ButtonShape.circle,
                child: const Icon(Icons.arrow_back),
              ),
              const Gap(8),
              OutlineButton(
                onPressed: () {
                  controller.animateNext(const Duration(milliseconds: 500));
                },
                shape: ButtonShape.circle,
                child: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
