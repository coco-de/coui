import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputCreditCardExample extends StatelessWidget {
  const FormattedInputCreditCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.creditCard(
      onChanged: (value) => debugPrint('Card: $value'),
    );
  }
}
