import 'package:coui_flutter/coui_flutter.dart';

class AvatarGroupExample1 extends StatefulWidget {
  const AvatarGroupExample1({super.key});

  @override
  State<AvatarGroupExample1> createState() => _AvatarGroupExample1State();
}

class _AvatarGroupExample1State extends State<AvatarGroupExample1> {
  List<AvatarWidget> getAvatars() {
    return [
      Avatar(
        backgroundColor: Colors.red,
        initials: Avatar.getInitials('coco-de'),
      ),
      Avatar(
        backgroundColor: Colors.green,
        initials: Avatar.getInitials('coco-de'),
      ),
      Avatar(
        backgroundColor: Colors.blue,
        initials: Avatar.getInitials('coco-de'),
      ),
      Avatar(
        backgroundColor: Colors.yellow,
        initials: Avatar.getInitials('coco-de'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        AvatarGroup.toLeft(children: getAvatars()),
        AvatarGroup.toRight(children: getAvatars()),
        AvatarGroup.toTop(children: getAvatars()),
        AvatarGroup.toBottom(children: getAvatars()),
      ],
    );
  }
}
