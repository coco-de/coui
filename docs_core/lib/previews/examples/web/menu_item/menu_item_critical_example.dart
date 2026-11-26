import 'package:coui_web/coui_web.dart';

class MenuItemCriticalExample extends StatelessComponent {
  const MenuItemCriticalExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        MenuItem(
          onPressed: () {},
          tone: CoreMenuItemTone.critical,
          label: const Text('삭제'),
          leading: const Icon(LucideIcons.trash2),
        ),
      ],
      classes: 'w-${CoreLayout.scale.layout280}',
    );
  }
}
