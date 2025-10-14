import 'package:coui_flutter/coui_flutter.dart';

class SkeletonExample1 extends StatelessWidget {
  const SkeletonExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Basic(
          content: Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          ),
          leading: Avatar(initials: ''),
          title: Text('Skeleton Example 1'),
          trailing: Icon(Icons.arrow_forward),
        ),
        const Gap(24),
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
    );
  }
}
