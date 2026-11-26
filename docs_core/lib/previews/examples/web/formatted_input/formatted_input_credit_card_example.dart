import 'package:coui_web/coui_web.dart';

class FormattedInputCreditCardExample extends StatelessComponent {
  const FormattedInputCreditCardExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.creditCard(
      onChanged: (value) => print('Card: $value'),
    );
  }
}
