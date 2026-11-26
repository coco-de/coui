import 'package:coui_web/coui_web.dart';

class FormattedInputDefaultExample extends StatelessComponent {
  const FormattedInputDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.phone(
      onChanged: (value) => print('Phone: $value'),
    );
  }
}
