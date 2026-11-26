/// Returns a Flutter code snippet string for the Icon component.
String iconCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class IconChainExample extends StatelessWidget {
  const IconChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
class IconSearchExample extends StatelessWidget {
  const IconSearchExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(LucideIcons.search, iconStyle: CoreIconStyle(size: 28));
  }
}''',
    'favorite' =>
      '''
class IconFavoriteExample extends StatelessWidget {
  const IconFavoriteExample({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Icon(
      LucideIcons.heart,
      iconStyle: CoreIconStyle(size: 28, color: scheme.tertiary.toValue()),
    );
  }
}''',
    _ =>
      '''
class IconDefaultExample extends StatelessWidget {
  const IconDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(LucideIcons.house, iconStyle: CoreIconStyle(size: 28));
  }
}''',
  };
}
