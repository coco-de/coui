/// Returns a Flutter code snippet string for the Collapsible component.
String collapsibleCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class CollapsibleChainExample extends StatelessWidget {
  const CollapsibleChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Collapsible(
      trigger: Text('고급 설정'),
      content: Text(
        '고급 사용자를 위한 옵션이에요.',
      ),
      expanded: true,
    ).withStyle(
      const CoreCollapsibleStyle(
        contentInset: CoreEdgeInsets.all(CoreSpace.space24),
        duration: Duration(milliseconds: CoreDuration.moderate),
        triggerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
        iconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class CollapsibleDefaultExample extends StatelessWidget {
  const CollapsibleDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Collapsible(
      trigger: Text('고급 설정'),
      content: Text(
        '고급 사용자를 위한 옵션이에요.',
      ),
    );
  }
}''',
  };
}
