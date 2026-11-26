import 'package:coui_web/coui_web.dart';

class ChatPlainExample extends StatelessComponent {
  const ChatPlainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        const Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            child: Text('이번 주말에 뭐 해요?'),
          ),
        ),
        const Gap.space12(),
        const Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.plain,
            child: Text('등산 가려고요. 같이 갈래요?'),
          ),
        ),
      ],
      classes: 'flex flex-col w-full',
    );
  }
}
