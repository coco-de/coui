/// Returns a Flutter code snippet string for the Breadcrumb component.
String breadcrumbCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class BreadcrumbChainExample extends StatelessWidget {
  const BreadcrumbChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Breadcrumb(
      items: const [
        CoreBreadcrumbItem(label: '홈', href: '/'),
        CoreBreadcrumbItem(label: '라이브러리', href: '/components'),
        CoreBreadcrumbItem(label: '데이터'),
      ],
      onItemTap: (index) {},
    ).withStyle(
      const CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: CoreSpace.space16),
        itemColor: CoreColor.token(CoreColors.onSurfaceVariant),
        currentItemColor: CoreColor.token(CoreColors.primary),
        itemHoverColor: CoreColor.token(CoreColors.tertiary),
        separatorIconStyle: CoreIconStyle(
          size: CoreSize.size12,
          color: CoreColor.token(CoreColors.outline),
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class BreadcrumbDefaultExample extends StatelessWidget {
  const BreadcrumbDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Breadcrumb(
      items: const [
        CoreBreadcrumbItem(label: '홈', href: '/'),
        CoreBreadcrumbItem(label: '라이브러리', href: '/components'),
        CoreBreadcrumbItem(label: '데이터'),
      ],
      onItemTap: (index) {},
    );
  }
}''',
  };
}
