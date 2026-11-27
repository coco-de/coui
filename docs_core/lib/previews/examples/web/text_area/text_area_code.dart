/// Returns a Web code snippet string for the TextArea component.
String textAreaCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class TextAreaChainExample extends StatefulComponent {
  const TextAreaChainExample({super.key});

  @override
  State<TextAreaChainExample> createState() => _TextAreaChainExampleState();
}

class _TextAreaChainExampleState extends State<TextAreaChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        TextArea(placeholder: '내용을 입력해 주세요', rows: 4).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TextArea(placeholder: '내용을 입력해 주세요', rows: 4).withStyle(
          const CoreTextAreaStyle(
            borderColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'footer' =>
      '''
class TextAreaFooterExample extends StatefulComponent {
  const TextAreaFooterExample({super.key});

  @override
  State<TextAreaFooterExample> createState() => _TextAreaFooterExampleState();
}

class _TextAreaFooterExampleState extends State<TextAreaFooterExample> {
  @override
  Component build(BuildContext context) {
    // 댓글 상자 — 보내기 버튼은 글자 아래, 박스 안의 footer 줄 끝에 둔다.
    return TextArea(
      placeholder: '댓글을 입력해 주세요',
      rows: 3,
      footer: div(
        [
          Button(
            variant: CoreButtonVariant.primary,
            size: CoreComponentSize.sm,
            onPressed: () {},
            child: const Text('보내기'),
          ),
        ],
        classes: 'flex flex-row justify-end',
      ),
    );
  }
}''',
    _ =>
      '''
class TextAreaDefaultExample extends StatefulComponent {
  const TextAreaDefaultExample({super.key});

  @override
  State<TextAreaDefaultExample> createState() =>
      _TextAreaDefaultExampleState();
}

class _TextAreaDefaultExampleState extends State<TextAreaDefaultExample> {
  @override
  Component build(BuildContext context) {
    return TextArea(
      placeholder: '내용을 입력해 주세요',
      rows: 4,
    );
  }
}''',
  };
}
