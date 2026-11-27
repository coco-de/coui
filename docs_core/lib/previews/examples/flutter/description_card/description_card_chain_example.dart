import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [DescriptionCard].
class DescriptionCardChainExample extends StatelessWidget {
  const DescriptionCardChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        const DescriptionCard(
          title: '주문 상세',
          rows: [
            DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
            DescriptionRow(label: '상품', value: 'AirPods Pro 2'),
            DescriptionRow(
              label: '합계',
              value: '369,000원',
              isEmphasized: true,
            ),
          ],
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        const DescriptionCard(
          title: '주문 상세',
          rows: [
            DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
            DescriptionRow(label: '상품', value: 'AirPods Pro 2'),
            DescriptionRow(
              label: '합계',
              value: '369,000원',
              isEmphasized: true,
            ),
          ],
        ).withStyle(
          const CoreDescriptionCardStyle(
            backgroundColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            rowSpacing: CoreSpace.space12,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
    );
  }
}
