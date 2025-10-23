import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class AvatarTile extends StatelessWidget implements IComponentPage {
  const AvatarTile({super.key});

  @override
  String get title => 'Avatar';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'avatar',
      title: 'Avatar',
      example: Card(
        child: Row(
          children: [
            Avatar(
              initials: Avatar.getInitials('coco-de'),
              provider: const NetworkImage(
                'https://avatars.githubusercontent.com/u/64018564?v=4',
              ),
            ),
            const Gap(16),
            Avatar(initials: Avatar.getInitials('coco-de')),
          ],
        ),
      ),
      scale: 1.5,
    );
  }
}
