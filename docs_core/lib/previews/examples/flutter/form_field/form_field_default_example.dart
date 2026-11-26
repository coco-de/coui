import 'package:coui_flutter/coui_flutter.dart';

class FormFieldDefaultExample extends StatelessWidget {
  const FormFieldDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: FormField(
        label: '이메일',
        description: '회사 이메일을 입력하세요.',
        required: true,
        child: TextField(
          autofillHints: const [AutofillHints.email],
          placeholder: const Text('you@company.com'),
        ),
      ),
    );
  }
}
