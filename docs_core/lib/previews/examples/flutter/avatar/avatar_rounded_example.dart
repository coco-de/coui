import 'package:coui_flutter/coui_flutter.dart';

class AvatarRoundedExample extends StatelessWidget {
  const AvatarRoundedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Avatar(
      initials: 'A',
      shape: CoreAvatarShape.rounded,
    );
  }
}
