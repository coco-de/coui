/// Returns a Web code snippet string for the Form component.
String formCode(String? variant) {
  return '''
class FormDefaultExample extends StatelessComponent {
  const FormDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Form(
      children: [
        FormField(
          label: '사용자 이름',
          child: TextField(
            onChanged: (_) {},
            autofillHints: const ['username'],
            placeholder: Text('사용자 이름을 입력해 주세요'),
          ),
        ),
        FormField(
          label: '이메일',
          child: TextField(
            onChanged: (_) {},
            autofillHints: const ['email'],
            placeholder: Text('이메일을 입력해 주세요'),
          ),
        ),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('제출'),
        ),
      ],
    );
  }
}''';
}
