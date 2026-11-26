import 'package:coui_web/coui_web.dart';

class ChatInfoExample extends StatelessComponent {
  const ChatInfoExample({super.key});

  @override
  Component build(BuildContext context) {
    return Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.info,
        child: Text('정보 말풍선'),
      ),
    );
  }
}
