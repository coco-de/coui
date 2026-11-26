import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputDefaultExample extends StatelessWidget {
  const FormattedInputDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.phone(
      onChanged: (value) => debugPrint('Phone: $value'),
    );
  }
}
