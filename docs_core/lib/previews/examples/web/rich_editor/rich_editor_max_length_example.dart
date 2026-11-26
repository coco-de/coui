import 'package:coui_web/coui_web.dart';

class RichEditorMaxLengthExample extends StatelessComponent {
  const RichEditorMaxLengthExample({super.key});

  @override
  Component build(BuildContext context) {
    return RichEditor(
      placeholder: '댓글을 입력해 주세요',
      maxLength: 140,
      initialValue:
          '**짧게 써 주세요.** 140자 이내의 답글은 '
          '알림 미리보기에서 바로 다 보여요.',
    );
  }
}
