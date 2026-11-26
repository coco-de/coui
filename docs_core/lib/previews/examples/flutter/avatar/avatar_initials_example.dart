import 'package:coui_flutter/coui_flutter.dart';

class AvatarInitialsExample extends StatefulWidget {
  const AvatarInitialsExample({super.key});

  @override
  State<AvatarInitialsExample> createState() => _AvatarInitialsExampleState();
}

class _AvatarInitialsExampleState extends State<AvatarInitialsExample> {
  @override
  Widget build(BuildContext context) {
    return const Avatar(
      initials: 'A',
    );
  }
}
