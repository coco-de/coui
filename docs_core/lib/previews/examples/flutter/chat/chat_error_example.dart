import 'package:coui_flutter/coui_flutter.dart';

class ChatErrorExample extends StatelessWidget {
  const ChatErrorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.error,
            child: Text('오류 말풍선'),
          ),
        ),
      ],
    );
  }
}
