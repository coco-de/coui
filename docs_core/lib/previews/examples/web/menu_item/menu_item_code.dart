/// Returns a Web code snippet string for the MenuItem component.
String menuItemCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class MenuItemChainExample extends StatelessComponent {
  const MenuItemChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        MenuItem(
          onPressed: () {},
          label: const Text('복사'),
          shortcut: const Text('⌘C'),
          leading: const Icon(LucideIcons.copy),
        ).withStyle(
          const CoreMenuItemStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space16,
              vertical: CoreSpace.space8,
            ),
            contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
            foregroundColor: CoreColor.token(CoreColors.primary),
          ),
        ),
      ],
      classes: 'w-\${CoreLayout.scale.layout280}',
    );
  }
}''',
    'critical' =>
      '''
class MenuItemCriticalExample extends StatelessComponent {
  const MenuItemCriticalExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        MenuItem(
          onPressed: () {},
          tone: CoreMenuItemTone.critical,
          label: const Text('삭제'),
          leading: const Icon(LucideIcons.trash2),
        ),
      ],
      classes: 'w-\${CoreLayout.scale.layout280}',
    );
  }
}''',
    'description' =>
      '''
class MenuItemDescriptionExample extends StatelessComponent {
  const MenuItemDescriptionExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        MenuItem(
          onPressed: () {},
          size: CoreMenuItemSize.lg,
          label: const Text('보관'),
          description: const Text('보관 폴더로 옮겨요'),
          leading: const Icon(LucideIcons.archive),
        ),
      ],
      classes: 'w-\${CoreLayout.scale.layout280}',
    );
  }
}''',
    _ =>
      '''
class MenuItemDefaultExample extends StatelessComponent {
  const MenuItemDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // 행은 자기 폭을 정하지 않는다 — 메뉴 패널이 정한다. 프리뷰에서는
    // 패널 폭 상한(`layout280`)을 부모가 대신 준다.
    return div(
      [
        MenuItem(
          onPressed: () {},
          label: const Text('복사'),
          shortcut: const Text('⌘C'),
          leading: const Icon(LucideIcons.copy),
        ),
      ],
      classes: 'w-\${CoreLayout.scale.layout280}',
    );
  }
}''',
  };
}
