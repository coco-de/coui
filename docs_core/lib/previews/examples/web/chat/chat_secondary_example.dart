import 'package:coui_web/coui_web.dart';

class ChatSecondaryExample extends StatelessComponent {
  const ChatSecondaryExample({super.key});

  @override
  Component build(BuildContext context) {
    return Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.secondary,
        child: Text('보조 말풍선'),
      ),
    );
  }
}
