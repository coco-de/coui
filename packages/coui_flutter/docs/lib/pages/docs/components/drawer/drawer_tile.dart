import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class DrawerTile extends StatelessWidget implements IComponentPage {
  const DrawerTile({super.key});

  @override
  String get title => 'Drawer';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'drawer',
      title: 'Drawer',
      example: DrawerWrapper(
        position: OverlayPosition.bottom,
        size: const Size(300, 300),
        stackIndex: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Drawer!').large().medium(),
            const Gap(4),
            const Text(
              'This is a drawer that you can use to display content',
            ).muted(),
          ],
        ).withPadding(horizontal: 32),
      ).sized(height: 300, width: 300),
      scale: 1,
    );
  }
}
