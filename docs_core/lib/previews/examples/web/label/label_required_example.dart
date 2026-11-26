import 'package:coui_web/coui_web.dart';

class LabelRequiredExample extends StatelessComponent {
  const LabelRequiredExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(text: '이메일', isRequired: true);
  }
}
