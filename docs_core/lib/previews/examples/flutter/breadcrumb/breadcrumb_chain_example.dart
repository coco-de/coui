import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreBreadcrumbStyle] slot without constructing the
/// widget from scratch.
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
}
