/// Returns a Flutter code snippet string for the PanelHeader component.
String panelHeaderCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class PanelHeaderChainExample extends StatelessWidget {
  const PanelHeaderChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelHeader(
      title: const Text('최근 파일'),
      action: Button(
        variant: .plain,
        size: .sm,
        onPressed: () {},
        child: const Text('모두 보기'),
        trailing: const Icon(
          LucideIcons.chevronRight,
          iconStyle: CoreIconStyle(size: CoreIconSize.size14),
        ),
      ),
    ).withStyle(
      const CorePanelHeaderStyle(
        titleTextStyle: CoreTextStyle.token(CoreTextStyles.titleSmall),
        padding: CoreEdgeInsets.only(bottom: CoreSpace.space12),
      ),
    );
  }
}''',
    _ =>
      '''
class PanelHeaderDefaultExample extends StatelessWidget {
  const PanelHeaderDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelHeader(
      title: const Text('최근 파일'),
      action: Button(
        variant: .plain,
        size: .sm,
        onPressed: () {},
        child: const Text('모두 보기'),
        trailing: const Icon(
          LucideIcons.chevronRight,
          iconStyle: CoreIconStyle(size: CoreIconSize.size14),
        ),
      ),
    );
  }
}''',
  };
}
