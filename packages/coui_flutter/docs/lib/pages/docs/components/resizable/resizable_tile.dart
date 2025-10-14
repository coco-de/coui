import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';
import 'resizable_example_3.dart';

class ResizableTile extends StatelessWidget implements IComponentPage {
  const ResizableTile({super.key});

  @override
  String get title => 'Resizable';

  @override
  Widget build(BuildContext context) {
    return const ComponentCard(
      name: 'resizable',
      title: 'Resizable',
      example: ResizableExample3(),
      scale: 1,
    );
  }
}
