import 'package:coui_flutter/coui_flutter.dart';

class ChatTailTopExample extends StatelessWidget {
  const ChatTailTopExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          header: Text('박코드'),
          bubble: ChatBubble(
            tail: true,
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
            ),
            child: Text('방금 출발했어요. 10분 뒤에 도착해요.'),
          ),
        ),
        Gap.space12(),
        Chat(
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
    );
  }
}
