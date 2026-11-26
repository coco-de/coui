import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputDateExample extends StatelessWidget {
  const FormattedInputDateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.date(
      onChanged: (value) => debugPrint('Date: $value'),
    );
  }
}
