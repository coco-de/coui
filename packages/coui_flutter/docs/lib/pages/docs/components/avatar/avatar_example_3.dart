import 'package:coui_flutter/coui_flutter.dart';

class AvatarExample3 extends StatelessWidget {
  const AvatarExample3({super.key});

  @override
  Widget build(BuildContext context) {
    return Avatar(
      badge: const AvatarBadge(color: Colors.green, size: 20),
      initials: Avatar.getInitials('sunarya-thito'),
      size: 64,
    );
  }
}
