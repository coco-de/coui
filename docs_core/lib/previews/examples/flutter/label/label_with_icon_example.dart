import 'package:coui_flutter/coui_flutter.dart';

class LabelWithIconExample extends StatelessWidget {
  const LabelWithIconExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Label(
      text: '이메일',
      icon: Icon(LucideIcons.mail),
    );
  }
}
