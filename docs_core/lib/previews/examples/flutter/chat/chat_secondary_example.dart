import 'package:coui_flutter/coui_flutter.dart';

class ChatSecondaryExample extends StatelessWidget {
  const ChatSecondaryExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.secondary,
            child: Text('보조 말풍선'),
          ),
        ),
      ],
    );
  }
}
