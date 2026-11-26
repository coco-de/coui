import 'package:coui_flutter/coui_flutter.dart';

/// `outlined` 변형 — 채움 없이 외곽선만. 내용은 기본 예제와 같다.
///
/// Fixed-width wrapper — see `FieldsetDefaultExample`.
class FieldsetOutlinedExample extends StatelessWidget {
  const FieldsetOutlinedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: Fieldset(
        variant: CoreFieldsetVariant.outlined,
        legend: const Text('계정'),
        description: const Text('로그인에 쓰는 정보예요.'),
        children: [
          TextField(
            autofillHints: const [AutofillHints.name],
            placeholder: const Text('이름'),
          ),
          TextField(
            autofillHints: const [AutofillHints.email],
            placeholder: const Text('이메일'),
          ),
        ],
      ),
    );
  }
}
