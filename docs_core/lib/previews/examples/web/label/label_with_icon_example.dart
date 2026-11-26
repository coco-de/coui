import 'package:coui_web/coui_web.dart';

class LabelWithIconExample extends StatelessComponent {
  const LabelWithIconExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(
      text: '이메일',
      icon: Icon(LucideIcons.mail),
    );
  }
}
