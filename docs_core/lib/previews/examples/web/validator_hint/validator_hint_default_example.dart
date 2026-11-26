import 'package:coui_web/coui_web.dart';

class ValidatorHintDefaultExample extends StatelessComponent {
  const ValidatorHintDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return ValidatorHint(
      message: Text('비밀번호는 8자 이상이어야 합니다.'),
      type: CoreValidatorHintType.error,
    );
  }
}
