import 'package:coui_web/coui_web.dart';

class ChatTailCornerExample extends StatelessComponent {
  const ChatTailCornerExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Chat(
          avatar: Avatar(initials: 'C'),
          bubble: const ChatBubble(
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
              tailCornerRadius: CoreRadius.radius6,
            ),
            child: Text('오후 3시 픽업은 그대로인가요?'),
          ),
          footer: const Text('오후 2:10'),
        ),
        const Gap.space12(),
        const Chat(
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
      classes: 'flex flex-col w-full',
    );
  }
}
