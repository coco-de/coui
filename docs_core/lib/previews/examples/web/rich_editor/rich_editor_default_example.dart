import 'package:coui_web/coui_web.dart';

class RichEditorDefaultExample extends StatelessComponent {
  const RichEditorDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return RichEditor(
      placeholder: '댓글을 입력해 주세요',
      initialValue:
          '## 리뷰 메모\n'
          '\n'
          '**좋아요!** 작은 수정 두 가지만 부탁해요.\n'
          '\n'
          '- 툴바 그룹 이름 바꾸기\n'
          '- 빠진 툴팁 추가하기\n'
          '\n'
          '> CI가 통과하면 배포해 주세요.',
    );
  }
}
