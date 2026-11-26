import 'package:coui_web/coui_web.dart';

class ChatWarningExample extends StatelessComponent {
  const ChatWarningExample({super.key});

  @override
  Component build(BuildContext context) {
    return Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.warning,
        child: Text('경고 말풍선'),
      ),
    );
  }
}
