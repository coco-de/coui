import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'chat_group.stories.g.dart';

// ChatGroup widgetbook constants.
const _kChatWidth = 400.0;
const _kChatSpacing = 12.0;

/// Conversation demo host for [ChatGroup] stories.
///
/// Renders two chat groups — an incoming (start-aligned) group and
/// an outgoing (end-aligned) group — like a real conversation.
class ChatGroupDemo extends StatelessWidget {
  /// Creates a [ChatGroupDemo].
  const ChatGroupDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: _kChatWidth,
      child: Column(
        mainAxisSize: .min,
        spacing: _kChatSpacing,
        children: [
          ChatGroup(
            bubbles: [
              ChatBubble(child: Text('Hello! How are you?')),
              ChatBubble(child: Text('Nice weather today!')),
            ],
          ),
          ChatGroup(
            bubbles: [
              ChatBubble(child: Text('Doing great, thanks!')),
              ChatBubble(child: Text("Yes, it's beautiful!")),
            ],
            alignment: .end,
          ),
        ],
      ),
    );
  }
}

/// Navigation metadata for the ChatGroup component.
const kComponentMeta = ComponentMeta(name: 'Chat Group', path: 'display');

/// Story metadata for [ChatGroupDemo].
const kMeta = Meta(ChatGroupDemo.new);

/// Two-sided conversation built from chat groups.
final $Conversation = _Story();
