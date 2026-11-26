import 'package:coui_flutter/coui_flutter.dart';

class DescriptionCardDefaultExample extends StatelessWidget {
  const DescriptionCardDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
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
