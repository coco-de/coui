import 'package:coui_flutter/coui_flutter.dart';

import '../carousel_example.dart';

class CarouselExample2 extends StatefulWidget {
  const CarouselExample2({super.key});

  @override
  State<CarouselExample2> createState() => _CarouselExample2State();
}

class _CarouselExample2State extends State<CarouselExample2> {
  final CarouselController controller = CarouselController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlineButton(
            onPressed: () {
              controller.animatePrevious(const Duration(milliseconds: 500));
            },
            shape: ButtonShape.circle,
            child: const Icon(Icons.arrow_upward),
          ),
          const Gap(24),
          Expanded(
            child: SizedBox(
              width: 200,
              child: Carousel(
                alignment: CarouselAlignment.center,
                controller: controller,
                direction: Axis.vertical,
                itemBuilder: (context, index) {
                  return NumberedContainer(index: index);
                },
                sizeConstraint: const CarouselFixedConstraint(200),
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
            child: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
    );
  }
}
