import 'package:coui_web/coui_web.dart';

class FormLabelDefaultExample extends StatelessComponent {
  const FormLabelDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormLabel(label: Text('이메일'), isRequired: true);
  }
}
