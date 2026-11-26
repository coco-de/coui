import 'package:coui_flutter/coui_flutter.dart';

class ChatDefaultExample extends StatelessWidget {
  const ChatDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          avatar: Avatar(initials: 'C'),
          header: Text('이코드'),
          bubble: ChatBubble(
            child: Text('오늘 점심 뭐 먹을까요?'),
          ),
          footer: Text('오전 11:30'),
        ),
        Gap.space12(),
        Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            child: Text('회사 앞 국숫집 어때요?'),
          ),
          footer: Text('오전 11:31'),
        ),
      ],
    );
  }
}
