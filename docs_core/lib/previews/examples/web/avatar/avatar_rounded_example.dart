import 'package:coui_web/coui_web.dart';

class AvatarRoundedExample extends StatelessComponent {
  const AvatarRoundedExample({super.key});

  @override
  Component build(BuildContext context) {
    return Avatar(
      initials: 'A',
      shape: CoreAvatarShape.rounded,
    );
  }
}
