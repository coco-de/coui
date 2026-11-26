import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain sugar for quickly patching
/// `Chat.chatStyle` on an already-built instance, instead of only being
/// able to pass `chatStyle: CoreChatStyle(...)` in the constructor.
class ChatChainExample extends StatelessComponent {
  const ChatChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Chat(
          avatar: Avatar(initials: 'C'),
          header: const Text('이코드'),
          bubble: const ChatBubble(
            child: Text('오늘 점심 뭐 먹을까요?'),
          ),
          footer: const Text('오전 11:30'),
        ).withStyle(
          const CoreChatStyle(
            avatarSpacing: CoreSpace.space16,
            groupSpacing: CoreSpace.space4,
            headerTextStyle: CoreTextStyle.token(
              CoreTextStyles.labelLarge,
              color: CoreColor.token(CoreColors.primary),
            ),
            footerTextStyle: CoreTextStyle.token(
              CoreTextStyles.labelSmall,
              color: CoreColor.token(CoreColors.onSurfaceVariant),
            ),
          ),
        ),
        const Gap.space12(),
        const Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            child: Text('회사 앞 국숫집 어때요?'),
          ),
          footer: Text('오전 11:31'),
        ),
      ],
      classes: 'flex flex-col w-full',
    );
  }
}
