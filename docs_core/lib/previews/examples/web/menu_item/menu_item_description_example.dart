import 'package:coui_web/coui_web.dart';

class MenuItemDescriptionExample extends StatelessComponent {
  const MenuItemDescriptionExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        MenuItem(
          onPressed: () {},
          size: CoreMenuItemSize.lg,
          label: const Text('보관'),
          description: const Text('보관 폴더로 옮겨요'),
          leading: const Icon(LucideIcons.archive),
        ),
      ],
      classes: 'w-${CoreLayout.scale.layout280}',
    );
  }
}
