import 'package:coui_web/coui_web.dart';

class FormattedInputDateExample extends StatelessComponent {
  const FormattedInputDateExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.date(
      onChanged: (value) => print('Date: $value'),
    );
  }
}
