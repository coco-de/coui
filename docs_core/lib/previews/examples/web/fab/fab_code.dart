/// Returns a Web code snippet string for the Fab component.
String fabCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class FabChainExample extends StatelessComponent {
  const FabChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Fab(
      trigger: const Icon(LucideIcons.plus),
      onPressed: () {},
      expandDirection: CoreFabExpandDirection.down,
      actions: [
        FabAction(
          icon: const Icon(LucideIcons.pencil),
          label: Text('편집'),
        ),
        FabAction(
          icon: const Icon(LucideIcons.share2),
          label: Text('공유'),
        ),
      ],
    ).withStyle(
      const CoreFabStyle(
        diameter: CoreSize.size72,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size32,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
        popupStyle: CorePopupStyle(
          backgroundColor: CoreColor.token(CoreColors.primaryContainer),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
        spacing: CoreSpace.space24,
      ),
    );
  }
}
''',
    _ =>
      '''
class FabDefaultExample extends StatelessComponent {
  const FabDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Fab(
      trigger: const Icon(LucideIcons.plus),
      onPressed: () {},
      expandDirection: CoreFabExpandDirection.down,
      actions: [
        FabAction(
          icon: const Icon(LucideIcons.pencil),
          label: Text('편집'),
        ),
        FabAction(
          icon: const Icon(LucideIcons.share2),
          label: Text('공유'),
        ),
      ],
    );
  }
}''',
  };
}
