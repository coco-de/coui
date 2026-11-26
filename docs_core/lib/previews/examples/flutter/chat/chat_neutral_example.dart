import 'package:coui_flutter/coui_flutter.dart';

class ChatNeutralExample extends StatelessWidget {
  const ChatNeutralExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.neutral,
            child: Text('중립 말풍선'),
          ),
        ),
      ],
    );
  }
}
