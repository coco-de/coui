import 'package:docs/pages/docs/components_page.dart';
import 'package:flutter/material.dart' as material;
import 'package:coui_flutter/coui_flutter.dart';

class AvatarGroupTile extends StatelessWidget implements IComponentPage {
  const AvatarGroupTile({super.key});

  @override
  String get title => 'Avatar Group';

  @override
  Widget build(BuildContext context) {
    return ComponentCard(
      name: 'avatar_group',
      title: 'Avatar Group',
      example: AvatarGroup.toLeft(
        children: [
          Avatar(
            backgroundColor: material.Colors.red,
            initials: Avatar.getInitials('coco-de'),
          ),
          Avatar(
            backgroundColor: material.Colors.green,
            initials: Avatar.getInitials('coco-de'),
          ),
          Avatar(
            backgroundColor: material.Colors.blue,
            initials: Avatar.getInitials('coco-de'),
          ),
          Avatar(
            backgroundColor: material.Colors.yellow,
            initials: Avatar.getInitials('coco-de'),
          ),
        ],
      ),
      center: true,
      scale: 1.5,
    );
  }
}
