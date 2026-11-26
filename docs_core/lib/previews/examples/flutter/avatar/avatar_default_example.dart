import 'package:coui_flutter/coui_flutter.dart';

class AvatarDefaultExample extends StatefulWidget {
  const AvatarDefaultExample({super.key});

  @override
  State<AvatarDefaultExample> createState() => _AvatarDefaultExampleState();
}

class _AvatarDefaultExampleState extends State<AvatarDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const Avatar(
      initials: 'A',
    );
  }
}
