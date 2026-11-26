/// Returns a Web code snippet string for the Menu component.
String menuCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class MenuChainExample extends StatelessComponent {
  const MenuChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Menu(
      ariaLabel: '주 메뉴',
      items: [
        const CoreMenuItem.label('탐색'),
        CoreMenuItem.action('홈', onPressed: () {}, active: true),
        CoreMenuItem.action('프로필', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.checkbox('격자 보기', onChanged: (_) {}, checked: true),
        CoreMenuItem.action('설정', disabled: true),
      ],
    ).withStyle(
      const CoreMenuStyle(
        itemStyle: CoreMenuItemStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space12,
          ),
          contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          markIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.tertiary),
          ),
        ),
        dividerStyle: CoreDividerStyle(
          color: CoreColor.token(CoreColors.primary),
          thickness: CoreStrokeWidth.stroke2,
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class MenuDefaultExample extends StatelessComponent {
  const MenuDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Menu(
      ariaLabel: '주 메뉴',
      items: [
        const CoreMenuItem.label('탐색'),
        CoreMenuItem.action('홈', onPressed: () {}, active: true),
        CoreMenuItem.action('프로필', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.checkbox('격자 보기', onChanged: (_) {}, checked: true),
        CoreMenuItem.action('설정', disabled: true),
      ],
    );
  }
}''',
  };
}
