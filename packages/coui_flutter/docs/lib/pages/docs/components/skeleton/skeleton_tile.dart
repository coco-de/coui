import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs/pages/docs/components_page.dart';

class SkeletonTile extends StatelessWidget implements IComponentPage {
  const SkeletonTile({super.key});

  @override
  String get title => 'Skeleton';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'skeleton',
      title: 'Skeleton',
      example: Card(
        child: Column(
          children: [
            Basic(
              content: const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
              ),
              leading: const Avatar(initials: '').asSkeleton(),
              title: const Text('Skeleton Example 1'),
              // Note: Avatar and other Image related widget needs its own skeleton
              trailing: const Icon(Icons.arrow_forward),
            ).asSkeleton(),
            const Gap(16),
            Basic(
              content: const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
              ),
              leading: const Avatar(initials: '').asSkeleton(),
              title: const Text('Skeleton Example 1'),
              // Note: Avatar and other Image related widget needs its own skeleton
              trailing: const Icon(Icons.arrow_forward),
            ).asSkeleton(),
            const Gap(16),
            Basic(
              content: const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
              ),
              leading: const Avatar(initials: '').asSkeleton(),
              title: const Text('Skeleton Example 1'),
              // Note: Avatar and other Image related widget needs its own skeleton
              trailing: const Icon(Icons.arrow_forward),
            ).asSkeleton(),
          ],
        ),
      ).sized(height: 300),
      scale: 1,
    );
  }
}
