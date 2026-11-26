/// Returns a Web code snippet string for the TextField component.
String textFieldCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class TextFieldChainExample extends StatefulComponent {
  const TextFieldChainExample({super.key});

  @override
  State<TextFieldChainExample> createState() => _TextFieldChainExampleState();
}

class _TextFieldChainExampleState extends State<TextFieldChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        TextField(placeholder: Text('이메일을 입력해 주세요')).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TextField(placeholder: Text('이메일을 입력해 주세요')).withStyle(
          const CoreTextFieldStyle(
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'error' =>
      '''
class TextFieldErrorExample extends StatefulComponent {
  const TextFieldErrorExample({super.key});

  @override
  State<TextFieldErrorExample> createState() => _TextFieldErrorExampleState();
}

class _TextFieldErrorExampleState extends State<TextFieldErrorExample> {
  @override
  Component build(BuildContext context) {
    return TextField(
      placeholder: Text('이메일을 입력해 주세요'),
      errorText: '필수 항목이에요.',
    );
  }
}''',
    _ =>
      '''
class TextFieldDefaultExample extends StatefulComponent {
  const TextFieldDefaultExample({super.key});

  @override
  State<TextFieldDefaultExample> createState() =>
      _TextFieldDefaultExampleState();
}

class _TextFieldDefaultExampleState extends State<TextFieldDefaultExample> {
  @override
  Component build(BuildContext context) {
    return TextField(
      placeholder: Text('이메일을 입력해 주세요'),
    );
  }
}''',
  };
}
