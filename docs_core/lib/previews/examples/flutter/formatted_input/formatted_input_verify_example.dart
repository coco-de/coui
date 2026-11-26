import 'package:coui_flutter/coui_flutter.dart';

/// The real-world use case that started Epic #3866: a phone-number field
/// with an inline "send verification code" action, no separate row layout
/// needed now that the whole mask lives in one real, focusable field.
class FormattedInputVerifyExample extends StatelessWidget {
  const FormattedInputVerifyExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FormattedInput.koreanPhone(
      onChanged: (value) => debugPrint('Phone: $value'),
      trailing: Button(
        onPressed: () => debugPrint('Send verification code'),
        variant: .plain,
        size: .sm,
        child: Text('인증번호 보내기').labelMedium,
      ),
    );
  }
}
