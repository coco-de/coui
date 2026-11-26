import 'package:coui_flutter/coui_flutter.dart';

class ChatInfoExample extends StatelessWidget {
  const ChatInfoExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.info,
            child: Text('정보 말풍선'),
          ),
        ),
      ],
    );
  }
}
