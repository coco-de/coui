/// Returns a Flutter code snippet string for the Chat component.
String chatCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ChatChainExample extends StatelessWidget {
  const ChatChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Chat(
          avatar: Avatar(initials: 'C'),
          header: Text('이코드'),
          bubble: ChatBubble(
            child: Text('오늘 점심 뭐 먹을까요?'),
          ),
          footer: Text('오전 11:30'),
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
    );
  }
}''',
    'neutral' =>
      '''
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
}''',
    'primary' =>
      '''
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
}''',
    'secondary' =>
      '''
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
}''',
    'accent' =>
      '''
class ChatAccentExample extends StatelessWidget {
  const ChatAccentExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.accent,
            child: Text('강조 말풍선'),
          ),
        ),
      ],
    );
  }
}''',
    'info' =>
      '''
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
}''',
    'success' =>
      '''
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
}''',
    'warning' =>
      '''
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
}''',
    'tail-corner' =>
      '''
class ChatTailCornerExample extends StatelessWidget {
  const ChatTailCornerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          avatar: Avatar(initials: 'C'),
          bubble: ChatBubble(
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
              tailCornerRadius: CoreRadius.radius6,
            ),
            child: Text('오후 3시 픽업은 그대로인가요?'),
          ),
          footer: Text('오후 2:10'),
        ),
        Gap.space12(),
        Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            tail: false,
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
              tailCornerRadius: CoreRadius.radius6,
            ),
            child: Text('네, 역에서 봬요.'),
          ),
          footer: Text('오후 2:14'),
        ),
      ],
    );
  }
}''',
    'tail-top' =>
      '''
class ChatTailTopExample extends StatelessWidget {
  const ChatTailTopExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          header: Text('박코드'),
          bubble: ChatBubble(
            tail: true,
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
            ),
            child: Text('방금 출발했어요. 10분 뒤에 도착해요.'),
          ),
        ),
        Gap.space12(),
        Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            alignment: CoreChatAlignment.end,
            variant: CoreChatBubbleVariant.primary,
            tail: true,
            chatBubbleStyle: CoreChatBubbleStyle(
              tailEdge: CoreChatBubbleTailEdge.top,
            ),
            child: Text('천천히 와요!'),
          ),
        ),
      ],
    );
  }
}''',
    'plain' =>
      '''
class ChatPlainExample extends StatelessWidget {
  const ChatPlainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            child: Text('이번 주말에 뭐 해요?'),
          ),
        ),
        Gap.space12(),
        Chat(
          bubble: ChatBubble(
            variant: CoreChatBubbleVariant.plain,
            child: Text('등산 가려고요. 같이 갈래요?'),
          ),
        ),
      ],
    );
  }
}''',
    'error' =>
      '''
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
}''',
    _ =>
      '''
class ChatDefaultExample extends StatelessWidget {
  const ChatDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Chat(
          avatar: Avatar(initials: 'C'),
          header: Text('이코드'),
          bubble: ChatBubble(
            child: Text('오늘 점심 뭐 먹을까요?'),
          ),
          footer: Text('오전 11:30'),
        ),
        Gap.space12(),
        Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            child: Text('회사 앞 국숫집 어때요?'),
          ),
          footer: Text('오전 11:31'),
        ),
      ],
    );
  }
}''',
  };
}
