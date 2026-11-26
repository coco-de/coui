import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'chat.stories.g.dart';

// ChatBubble widgetbook constants.
const _kChatWidth = 400.0;

/// Knob input for [ChatBubble] stories.
class ChatBubbleInput {
  /// Creates a [ChatBubbleInput].
  const ChatBubbleInput({
    this.text = 'Hello! How are you?',
    this.variant = CoreChatBubbleVariant.neutral,
    this.alignment = CoreChatAlignment.start,
    this.tail = CoreChatBubbleContract.defaultTail,
  });

  /// Bubble message text.
  final String text;

  /// Bubble color variant.
  final CoreChatBubbleVariant variant;

  /// Bubble alignment inside the chat row.
  final CoreChatAlignment alignment;

  /// Whether the tail pointer is drawn.
  final bool tail;
}

/// Navigation metadata for the ChatBubble component.
const kComponentMeta = ComponentMeta(name: 'Chat Bubble', path: 'display');

/// Story metadata for [ChatBubble].
const kMeta = Meta(ChatBubble.new, argsType: ChatBubbleInput.new);

/// Default builder mapping [ChatBubbleInput] args to a [ChatBubble].
final ChatBubbleDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kChatWidth, child: child),
  builder: (context, args) => ChatBubble(
    variant: args.variant,
    alignment: args.alignment,
    tail: args.tail,
    child: Text(args.text),
  ),
);

/// Start-aligned chat bubble with editable knobs.
final $Default = _Story();

/// End-aligned chat bubble.
final $EndAligned = _Story(
  name: 'End Aligned',
  args: _Args(
    alignment: EnumArg(
      CoreChatAlignment.end,
      values: CoreChatAlignment.values,
    ),
  ),
);
