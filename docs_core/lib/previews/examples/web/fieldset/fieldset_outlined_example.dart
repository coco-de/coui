import 'package:coui_web/coui_web.dart';

/// `outlined` 변형 — 채움 없이 외곽선만. 내용은 기본 예제와 같다.
///
/// Fixed-width wrapper — see `FieldsetDefaultExample`.
class FieldsetOutlinedExample extends StatelessComponent {
  const FieldsetOutlinedExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Fieldset(
          variant: CoreFieldsetVariant.outlined,
          legend: const Text('계정'),
          description: const Text('로그인에 쓰는 정보예요.'),
          children: [
            TextField(
              autofillHints: const ['name'],
              placeholder: const Text('이름'),
            ),
            TextField(
              autofillHints: const ['email'],
              placeholder: const Text('이메일'),
            ),
          ],
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
