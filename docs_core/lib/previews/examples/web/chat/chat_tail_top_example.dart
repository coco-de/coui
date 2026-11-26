import 'package:coui_web/coui_web.dart';

class ChatTailTopExample extends StatelessComponent {
  const ChatTailTopExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        const Chat(
          header: Text('박코드'),
          bubble: ChatBubble(
            tail: true,
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
            ),
            child: Text('방금 출발했어요. 10분 뒤에 도착해요.'),
          ),
        ),
        const Gap.space12(),
        const Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            alignment: CoreChatAlignment.end,
            variant: CoreChatBubbleVariant.primary,
            tail: true,
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
            ),
            child: Text('천천히 와요!'),
          ),
        ),
      ],
      classes: 'flex flex-col w-full',
    );
  }
}
