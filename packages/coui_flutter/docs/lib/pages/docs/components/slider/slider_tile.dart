import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class SliderTile extends StatelessWidget implements IComponentPage {
  const SliderTile({super.key});

  @override
  String get title => 'Slider';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'slider',
      title: 'Slider',
      example: Slider(
        onChanged: (value) {},
        value: const SliderValue.single(0.75),
      ).sized(width: 100),
      center: true,
      scale: 2,
    );
  }
}
