/// Returns a Flutter code snippet string for the DropdownMenu component.
String dropdownMenuCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class DropdownMenuChainExample extends StatelessWidget {
  const DropdownMenuChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      trigger: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('메뉴 열기'),
      ),
      items: [
        CoreMenuItem.action('프로필', onPressed: () {}),
        CoreMenuItem.action('설정', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('로그아웃', onPressed: () {}),
      ],
    ).withStyle(
      const CoreDropdownMenuStyle(
        menuOffset: CoreSpace.space16,
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space16,
              vertical: CoreSpace.space8,
            ),
          ),
          labelTextStyle: CoreTextStyle.token(
            CoreTextStyles.labelLarge,
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      ),
    );
  }
}
''',
    _ =>
      '''
class DropdownMenuDefaultExample extends StatelessWidget {
  const DropdownMenuDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      trigger: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('메뉴 열기'),
      ),
      items: [
        CoreMenuItem.action('프로필', onPressed: () {}),
        CoreMenuItem.action('설정', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('로그아웃', onPressed: () {}),
      ],
    );
  }
}''',
  };
}
