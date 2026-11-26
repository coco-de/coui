import 'package:coui_web/coui_web.dart';

class ChatAccentExample extends StatelessComponent {
  const ChatAccentExample({super.key});

  @override
  Component build(BuildContext context) {
    return Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.accent,
        child: Text('강조 말풍선'),
      ),
    );
  }
}
