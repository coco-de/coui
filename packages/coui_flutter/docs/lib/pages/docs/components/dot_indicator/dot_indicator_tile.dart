import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class DotIndicatorTile extends StatelessWidget implements IComponentPage {
  const DotIndicatorTile({super.key});

  @override
  String get title => 'Dot Indicator';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'dot_indicator',
      title: 'Dot Indicator',
      example: Card(
        child: Column(
          children: [
            const Text('Page Indicators:').bold(),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  width: 12,
                  height: 12,
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    shape: BoxShape.circle,
                  ),
                  width: 8,
                  height: 8,
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    shape: BoxShape.circle,
                  ),
                  width: 8,
                  height: 8,
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    shape: BoxShape.circle,
                  ),
                  width: 8,
                  height: 8,
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    shape: BoxShape.circle,
                  ),
                  width: 8,
                  height: 8,
                ),
              ],
            ),
            const Gap(16),
            const Text('Step 1 of 5').muted(),
          ],
        ).withPadding(all: 16),
      ),
      scale: 1.2,
    );
  }
}
