import 'package:coui_web/coui_web.dart';

class AvatarInitialsExample extends StatefulComponent {
  const AvatarInitialsExample({super.key});

  @override
  State<AvatarInitialsExample> createState() => _AvatarInitialsExampleState();
}

class _AvatarInitialsExampleState extends State<AvatarInitialsExample> {
  @override
  Component build(BuildContext context) {
    return Avatar(
      initials: 'A',
    );
  }
}
