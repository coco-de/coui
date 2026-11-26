import 'package:coui_web/coui_web.dart';

class FormattedInputKoreanPhoneExample extends StatelessComponent {
  const FormattedInputKoreanPhoneExample({super.key});

  @override
  Component build(BuildContext context) {
    return FormattedInput.koreanPhone(
      onChanged: (value) => print('Phone: $value'),
    );
  }
}
