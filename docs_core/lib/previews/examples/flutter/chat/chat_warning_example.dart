import 'package:coui_flutter/coui_flutter.dart';

class ChatWarningExample extends StatelessWidget {
  const ChatWarningExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.warning,
            child: Text('경고 말풍선'),
          ),
        ),
      ],
    );
  }
}
