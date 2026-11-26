import 'package:coui_web/coui_web.dart';

class ChatNeutralExample extends StatelessComponent {
  const ChatNeutralExample({super.key});

  @override
  Component build(BuildContext context) {
    return Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.neutral,
        child: Text('중립 말풍선'),
      ),
    );
  }
}
