import 'package:coui_flutter/coui_flutter.dart';

class ValidatedDefaultExample extends StatelessWidget {
  const ValidatedDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Validated(
        state: CoreValidationState.invalid,
        message: const Text('필수 항목입니다.'),
        child: TextField(placeholder: const Text('이름')),
      ),
    );
  }
}
