import 'package:coui_web/coui_web.dart';

class DescriptionCardDefaultExample extends StatelessComponent {
  const DescriptionCardDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DescriptionCard(
      title: '주문 상세',
      rows: [
        DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
        DescriptionRow(label: '상품', value: 'AirPods Pro 2'),
        DescriptionRow(label: '합계', value: '369,000원', isEmphasized: true),
      ],
    );
  }
}
