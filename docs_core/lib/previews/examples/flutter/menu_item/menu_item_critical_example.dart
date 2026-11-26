import 'package:coui_flutter/coui_flutter.dart';

class MenuItemCriticalExample extends StatelessWidget {
  const MenuItemCriticalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreLayout.layout280,
      child: MenuItem(
        onPressed: () {},
        tone: CoreMenuItemTone.critical,
        label: const Text('삭제'),
        leading: const Icon(LucideIcons.trash2),
      ),
    );
  }
}
