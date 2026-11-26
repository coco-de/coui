import 'package:coui_web/coui_web.dart';

class AvatarPlaceholderExample extends StatefulComponent {
  const AvatarPlaceholderExample({super.key});

  @override
  State<AvatarPlaceholderExample> createState() => _AvatarPlaceholderExampleState();
}

class _AvatarPlaceholderExampleState extends State<AvatarPlaceholderExample> {
  @override
  Component build(BuildContext context) {
    return Avatar();
  }
}
