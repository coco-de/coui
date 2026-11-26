import 'package:coui_flutter/coui_flutter.dart';

class ChatSuccessExample extends StatelessWidget {
  const ChatSuccessExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.success,
            child: Text('성공 말풍선'),
          ),
        ),
      ],
    );
  }
}
