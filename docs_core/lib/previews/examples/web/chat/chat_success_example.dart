import 'package:coui_web/coui_web.dart';

class ChatSuccessExample extends StatelessComponent {
  const ChatSuccessExample({super.key});

  @override
  Component build(BuildContext context) {
    return Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.success,
        child: Text('성공 말풍선'),
      ),
    );
  }
}
