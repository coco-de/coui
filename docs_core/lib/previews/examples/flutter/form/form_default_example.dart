import 'package:coui_flutter/coui_flutter.dart';

class FormDefaultExample extends StatelessWidget {
  const FormDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      children: [
        FormField(
          label: '사용자 이름',
          child: TextField(
            autofillHints: const [AutofillHints.username],
            placeholder: const Text('사용자 이름을 입력해 주세요'),
          ),
        ),
        FormField(
          label: '이메일',
          child: TextField(
            autofillHints: const [AutofillHints.email],
            placeholder: const Text('이메일을 입력해 주세요'),
          ),
        ),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('제출'),
        ),
      ],
    );
  }
}
