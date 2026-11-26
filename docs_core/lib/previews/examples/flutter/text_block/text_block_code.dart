String textBlockCode(String? variant) {
  return switch (variant) {
    'chain' =>
      r'''
class TextBlockChainExample extends StatelessWidget {
  const TextBlockChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          TextBlock(text: '문서 제목', element: CoreTextBlockElement.h3),
          TextBlock(
            text: '본문은 paragraph 역할로 렌더됩니다. element 가 시맨틱 타이포 역할을 고릅니다.',
          ),
          TextBlock(
            text: 'blockquote 는 왼쪽에 강조 테두리를 가진다.',
            element: CoreTextBlockElement.blockquote,
          ).withStyle(
            const CoreTextBlockStyle(
              blockQuoteBorderColor: CoreColor.token(CoreColors.primary),
              blockQuoteBorderWidth: CoreStrokeWidth.stroke4,
              blockQuotePadding: CoreEdgeInsets.directional(
                start: CoreSpace.space16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}''',
    _ =>
      r'''
class TextBlockDefaultExample extends StatelessWidget {
  const TextBlockDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          TextBlock(text: '문서 제목', element: CoreTextBlockElement.h3),
          TextBlock(
            text: '본문은 paragraph 역할로 렌더됩니다. element 가 시맨틱 타이포 역할을 고릅니다.',
          ),
        ],
      ),
    );
  }
}''',
  };
}
