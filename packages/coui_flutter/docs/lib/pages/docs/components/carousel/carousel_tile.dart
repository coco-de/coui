import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';
import '../carousel/carousel_example_1.dart';

class CarouselTile extends StatelessWidget implements IComponentPage {
  const CarouselTile({super.key});

  @override
  String get title => 'Carousel';

  @override
  Widget build(BuildContext context) {
    return const ComponentCard(
      name: 'carousel',
      title: 'Carousel',
      example: SizedBox(width: 550, height: 200, child: CarouselExample1()),
      fit: true,
    );
  }
}
