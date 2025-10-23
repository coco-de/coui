import 'package:coui_flutter/coui_flutter.dart';

class AvatarExample2 extends StatelessWidget {
  const AvatarExample2({super.key});

  @override
  Widget build(BuildContext context) {
    return Avatar(initials: Avatar.getInitials('coco-de'), size: 64);
  }
}
