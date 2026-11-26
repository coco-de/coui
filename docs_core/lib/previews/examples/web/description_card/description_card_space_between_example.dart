import 'package:coui_web/coui_web.dart';

class DescriptionCardSpaceBetweenExample extends StatelessComponent {
  const DescriptionCardSpaceBetweenExample({super.key});

  @override
  Component build(BuildContext context) {
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
