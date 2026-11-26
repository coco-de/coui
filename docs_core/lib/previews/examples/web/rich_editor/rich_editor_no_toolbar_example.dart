import 'package:coui_web/coui_web.dart';

class RichEditorNoToolbarExample extends StatelessComponent {
  const RichEditorNoToolbarExample({super.key});

  @override
  Component build(BuildContext context) {
    return RichEditor(
      placeholder: '댓글을 입력해 주세요',
      showToolbar: false,
      initialValue: '툴바가 없어도 **단축키**와 `Markdown` 문법은 그대로 쓸 수 있어요.',
    );
  }
}
