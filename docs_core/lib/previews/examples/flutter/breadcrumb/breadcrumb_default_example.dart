import 'package:coui_flutter/coui_flutter.dart';

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
}
