import 'package:coui_flutter/coui_flutter.dart';

class ChatAccentExample extends StatelessWidget {
  const ChatAccentExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.accent,
            child: Text('강조 말풍선'),
          ),
        ),
      ],
    );
  }
}
