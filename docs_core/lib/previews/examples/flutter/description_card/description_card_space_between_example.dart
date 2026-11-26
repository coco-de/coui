import 'package:coui_flutter/coui_flutter.dart';

class DescriptionCardSpaceBetweenExample extends StatelessWidget {
  const DescriptionCardSpaceBetweenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DescriptionCard(
      alignment: CoreDescriptionCardAlignment.spaceBetween,
      showRowDividers: true,
      rows: [
        DescriptionRow(label: '상품', value: 'AirPods Pro 2'),
        DescriptionRow(label: '브랜드', value: 'Apple'),
        DescriptionRow(label: '가격', value: '369,000원'),
        DescriptionRow(label: '재고', value: '12'),
      ],
    );
  }
}
