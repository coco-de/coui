import 'package:coui_web/coui_web.dart';

class LabelDisabledExample extends StatelessComponent {
  const LabelDisabledExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Label(text: '이메일', disabled: true);
  }
}
