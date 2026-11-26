import 'package:coui_flutter/coui_flutter.dart';

class MenuItemDescriptionExample extends StatelessWidget {
  const MenuItemDescriptionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreLayout.layout280,
      child: MenuItem(
        onPressed: () {},
        size: CoreMenuItemSize.lg,
        label: const Text('보관'),
        description: const Text('보관 폴더로 옮겨요'),
        leading: const Icon(LucideIcons.archive),
      ),
    );
  }
}
