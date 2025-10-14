import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class TimelineAnimationTile extends StatelessWidget implements IComponentPage {
  const TimelineAnimationTile({super.key});

  @override
  String get title => 'Timeline Animation';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'timeline_animation',
      title: 'Timeline Animation',
      example: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 280,
          child: Column(
            children: [
              const Text('Animated Timeline:').bold(),
              const Gap(16),
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        width: 12,
                        height: 12,
                      ),
                      Container(
                        color: theme.colorScheme.primary,
                        width: 2,
                        height: 40,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        width: 12,
                        height: 12,
                      ),
                      Container(
                        color: theme.colorScheme.muted,
                        width: 2,
                        height: 40,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.muted,
                          shape: BoxShape.circle,
                        ),
                        width: 12,
                        height: 12,
                      ),
                    ],
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Step 1 Completed').bold(),
                        const Gap(4),
                        const Text('Task finished successfully').muted(),
                        const Gap(32),
                        const Text('Step 2 In Progress').bold(),
                        const Gap(4),
                        const Text('Currently working on this task').muted(),
                        const Gap(32),
                        const Text('Step 3 Pending').muted(),
                        const Gap(4),
                        const Text('Waiting to be started').muted(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      scale: 1.2,
    );
  }
}
