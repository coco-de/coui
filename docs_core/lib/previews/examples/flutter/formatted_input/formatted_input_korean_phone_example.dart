import 'package:coui_flutter/coui_flutter.dart';

class FormattedInputKoreanPhoneExample extends StatelessWidget {
  const FormattedInputKoreanPhoneExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.koreanPhone(
      onChanged: (value) => debugPrint('Phone: $value'),
    );
  }
}
