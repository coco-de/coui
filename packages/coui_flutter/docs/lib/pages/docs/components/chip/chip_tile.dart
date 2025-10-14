import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ChipTile extends StatelessWidget implements IComponentPage {
  const ChipTile({super.key});

  @override
  String get title => 'Chip';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'chip',
      title: 'Chip',
      example: Card(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(child: const Text('Default'), onPressed: () {}),
            Chip(
              leading: const Icon(LucideIcons.user),
              onPressed: () {},
              child: const Text('With Icon'),
            ),
            Chip(
              onPressed: () {},
              trailing: const Icon(LucideIcons.x),
              child: const Text('Removable'),
            ),
            const Chip(child: Text('Disabled')),
          ],
        ).withPadding(all: 16),
      ),
      scale: 1.5,
    );
  }
}
