import 'package:coui_flutter/coui_flutter.dart';

class LabelRequiredExample extends StatelessWidget {
  const LabelRequiredExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Label(text: '이메일', isRequired: true);
  }
}
