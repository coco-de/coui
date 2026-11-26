import 'package:coui_web/coui_web.dart';

class FormFieldDefaultExample extends StatelessComponent {
  const FormFieldDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '320px'}),
      [
        FormField(
          label: '이메일',
          description: '회사 이메일을 입력하세요.',
          required: true,
          child: TextField(
            autofillHints: const ['email'],
            placeholder: Text('you@company.com'),
          ),
        ),
      ],
    );
  }
}
