import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class SheetTile extends StatelessWidget implements IComponentPage {
  const SheetTile({super.key});

  @override
  String get title => 'Sheet';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'sheet',
      title: 'Sheet',
      example: SheetWrapper(
        position: OverlayPosition.right,
        size: const Size(300, 300),
        stackIndex: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sheet!').large().medium(),
            const Gap(4),
            const Text(
              'This is a sheet that you can use to display content',
            ).muted(),
          ],
        ).withPadding(horizontal: 32, vertical: 48),
      ).sized(height: 300, width: 300),
      verticalOffset: 0,
      scale: 1,
    );
  }
}
