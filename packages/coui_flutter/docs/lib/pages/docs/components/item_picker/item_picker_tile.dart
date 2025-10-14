import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class ItemPickerTile extends StatelessWidget implements IComponentPage {
  const ItemPickerTile({super.key});

  @override
  String get title => 'Item Picker';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'item_picker',
      title: 'Item Picker',
      example: Card(
        child: Column(
          children: [
            const Text('Select an item:').bold(),
            const Gap(16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(child: const Text('Option 1'), onPressed: () {}),
                Chip(child: const Text('Option 2'), onPressed: () {}),
                Chip(child: const Text('Option 3'), onPressed: () {}),
              ],
            ),
          ],
        ).withPadding(all: 16),
      ),
      scale: 1.2,
    );
  }
}
