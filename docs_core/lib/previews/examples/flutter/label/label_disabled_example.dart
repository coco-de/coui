import 'package:coui_flutter/coui_flutter.dart';

class LabelDisabledExample extends StatelessWidget {
  const LabelDisabledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Label(text: '이메일', disabled: true);
  }
}
