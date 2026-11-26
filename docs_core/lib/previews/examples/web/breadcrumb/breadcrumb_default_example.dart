import 'package:coui_web/coui_web.dart';

class BreadcrumbDefaultExample extends StatelessComponent {
  const BreadcrumbDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
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
