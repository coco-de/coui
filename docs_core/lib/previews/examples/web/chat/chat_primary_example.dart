import 'package:coui_web/coui_web.dart';

class ChatPrimaryExample extends StatelessComponent {
  const ChatPrimaryExample({super.key});

  @override
  Component build(BuildContext context) {
    return Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.primary,
        child: Text('기본 말풍선'),
      ),
    );
  }
}
