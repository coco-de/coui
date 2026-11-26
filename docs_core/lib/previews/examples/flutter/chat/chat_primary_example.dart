import 'package:coui_flutter/coui_flutter.dart';

class ChatPrimaryExample extends StatelessWidget {
  const ChatPrimaryExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.primary,
            child: Text('기본 말풍선'),
          ),
        ),
      ],
    );
  }
}
