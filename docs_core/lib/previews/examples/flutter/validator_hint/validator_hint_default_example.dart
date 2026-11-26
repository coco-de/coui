import 'package:coui_flutter/coui_flutter.dart';

class ValidatorHintDefaultExample extends StatelessWidget {
  const ValidatorHintDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ValidatorHint(
      message: const Text('비밀번호는 8자 이상이어야 합니다.'),
      type: CoreValidatorHintType.error,
    );
  }
}
