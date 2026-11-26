import 'package:coui_flutter/coui_flutter.dart';

class RichEditorNoToolbarExample extends StatelessWidget {
  const RichEditorNoToolbarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RichEditor(
      placeholder: '댓글을 입력해 주세요',
      showToolbar: false,
      initialValue: '툴바가 없어도 **단축키**와 `Markdown` 문법은 그대로 쓸 수 있어요.',
    );
  }
}
