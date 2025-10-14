import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class LinearProgressTile extends StatelessWidget implements IComponentPage {
  const LinearProgressTile({super.key});

  @override
  String get title => 'Linear Progress';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'linear_progress',
      title: 'Linear Progress',
      example: Card(
        child: Column(
          children: [
            const Text('Loading Progress:').bold(),
            const Gap(16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.muted,
                borderRadius: BorderRadius.circular(4),
              ),
              width: 250,
              height: 8,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  width: 175, // 70% of 250
                  height: 8,
                ),
              ),
            ),
            const Gap(8),
            const Text('70%').muted(),
          ],
        ).withPadding(all: 16),
      ),
      scale: 1.2,
    );
  }
}
