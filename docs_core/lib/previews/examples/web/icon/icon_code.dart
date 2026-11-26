/// Returns a Web code snippet string for the Icon component.
String iconCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class IconChainExample extends StatelessComponent {
  const IconChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Icon(
      LucideIcons.house,
      iconStyle: CoreIconStyle(size: 28),
    ).withStyle(
      const CoreIconStyle(
        size: CoreIconSize.size32,
        color: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
''',
    'search' =>
      '''
class IconSearchExample extends StatelessComponent {
  const IconSearchExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Icon(LucideIcons.search, iconStyle: CoreIconStyle(size: 28));
  }
}''',
    'favorite' =>
      '''
class IconFavoriteExample extends StatelessComponent {
  const IconFavoriteExample({super.key});

  @override
  Component build(BuildContext context) {
    return Icon(
      LucideIcons.heart,
      iconStyle: CoreIconStyle(size: 28, color: context.colorScheme.tertiary),
    );
  }
}''',
    _ =>
      '''
class IconDefaultExample extends StatelessComponent {
  const IconDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Icon(LucideIcons.house, iconStyle: CoreIconStyle(size: 28));
  }
}''',
  };
}
