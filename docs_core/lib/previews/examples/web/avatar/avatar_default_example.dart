import 'package:coui_web/coui_web.dart';

class AvatarDefaultExample extends StatefulComponent {
  const AvatarDefaultExample({super.key});

  @override
  State<AvatarDefaultExample> createState() => _AvatarDefaultExampleState();
}

class _AvatarDefaultExampleState extends State<AvatarDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Avatar(
      initials: 'A',
    );
  }
}
