import 'package:coui_flutter/coui_flutter.dart';

class ChatTailCornerExample extends StatelessWidget {
  const ChatTailCornerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          avatar: Avatar(initials: 'C'),
          bubble: ChatBubble(
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
              tailCornerRadius: CoreRadius.radius6,
            ),
            child: Text('오후 3시 픽업은 그대로인가요?'),
          ),
          footer: Text('오후 2:10'),
        ),
        Gap.space12(),
        Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            tail: false,
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
              tailCornerRadius: CoreRadius.radius6,
            ),
            child: Text('네, 역에서 봬요.'),
          ),
          footer: Text('오후 2:14'),
        ),
      ],
    );
  }
}
