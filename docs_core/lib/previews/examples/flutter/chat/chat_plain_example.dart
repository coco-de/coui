import 'package:coui_flutter/coui_flutter.dart';

class ChatPlainExample extends StatelessWidget {
  const ChatPlainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            child: Text('이번 주말에 뭐 해요?'),
          ),
        ),
        Gap.space12(),
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.plain,
            child: Text('등산 가려고요. 같이 갈래요?'),
          ),
        ),
      ],
    );
  }
}
