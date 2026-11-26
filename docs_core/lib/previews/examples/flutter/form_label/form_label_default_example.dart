import 'package:coui_flutter/coui_flutter.dart';

class FormLabelDefaultExample extends StatelessWidget {
  const FormLabelDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormLabel(label: const Text('이메일'), isRequired: true);
  }
}
