/// Returns a Flutter code snippet string for the PageHeader component.
String pageHeaderCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class PageHeaderChainExample extends StatelessWidget {
  const PageHeaderChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      eyebrow: const Text('워크스페이스'),
      title: const Text('설정'),
      actions: [Button(onPressed: () {}, child: const Text('변경 사항 저장'))],
    ).withStyle(
      const CorePageHeaderStyle(
        titleTextStyle: CoreTextStyle.token(CoreTextStyles.headlineSmall),
        textSpacing: CoreSpace.space8,
      ),
    );
  }
}''',
    _ =>
      '''
class PageHeaderDefaultExample extends StatelessWidget {
  const PageHeaderDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      eyebrow: const Text('워크스페이스'),
      title: const Text('설정'),
      description: const Text('멤버, 결제, 연동을 관리해요.'),
      actions: [
        Button(
          variant: .secondary,
          onPressed: () {},
          child: const Text('취소'),
        ),
        Button(onPressed: () {}, child: const Text('변경 사항 저장')),
      ],
    );
  }
}''',
  };
}
