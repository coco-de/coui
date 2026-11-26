import 'package:coui_web/coui_web.dart';

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
}
