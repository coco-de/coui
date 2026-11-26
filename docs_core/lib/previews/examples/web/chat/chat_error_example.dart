import 'package:coui_web/coui_web.dart';

class ChatErrorExample extends StatelessComponent {
  const ChatErrorExample({super.key});

  @override
  Component build(BuildContext context) {
    return Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.error,
        child: Text('오류 말풍선'),
      ),
    );
  }
}
