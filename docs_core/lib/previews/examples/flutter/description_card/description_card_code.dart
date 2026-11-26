/// Returns a Flutter code snippet string for the DescriptionCard component.
String descriptionCardCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class DescriptionCardChainExample extends StatelessWidget {
  const DescriptionCardChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
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
        ).radius16.primary,
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
            backgroundColor: CoreColor.token(CoreColors.tertiary),
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
}''',
    'filled' =>
      '''
class DescriptionCardFilledExample extends StatelessWidget {
  const DescriptionCardFilledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DescriptionCard(
      title: '프로필',
      variant: CoreDescriptionCardVariant.filled,
      rows: [
        DescriptionRow(label: '이름', value: '김코드'),
        DescriptionRow(label: '이메일', value: 'hong@example.com'),
        DescriptionRow(label: '전화번호', value: '010-1234-5678'),
      ],
    );
  }
}''',
    'ghost' =>
      '''
class DescriptionCardGhostExample extends StatelessWidget {
  const DescriptionCardGhostExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DescriptionCard(
      variant: CoreDescriptionCardVariant.ghost,
      rows: [
        DescriptionRow(label: '이름', value: '이코드'),
        DescriptionRow(label: '이메일', value: 'kim@example.com'),
        DescriptionRow(label: '전화번호', value: '010-1234-5678'),
      ],
    );
  }
}''',
    'vertical' =>
      '''
class DescriptionCardVerticalExample extends StatelessWidget {
  const DescriptionCardVerticalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DescriptionCard(
      title: '식물 관리',
      layout: CoreDescriptionCardLayout.vertical,
      rowWeight: CoreDescriptionCardRowWeight.labelProminent,
      rows: [
        DescriptionRow(label: '품종', value: '몬스테라 델리시오사'),
        DescriptionRow(label: '물 주기', value: '7일마다'),
        DescriptionRow(label: '빛', value: '밝은 간접광'),
        DescriptionRow(label: '온도', value: '18°C – 27°C'),
      ],
    );
  }
}''',
    'space-between' =>
      '''
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
}''',
    'placeholder' =>
      '''
class DescriptionCardPlaceholderExample extends StatelessWidget {
  const DescriptionCardPlaceholderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DescriptionCard(
      title: '빈 항목',
      emptyValueBehavior: CoreDescriptionCardEmptyBehavior.placeholder,
      emptyPlaceholder: '정보 없음',
      rows: [
        DescriptionRow(label: '이름', value: '김코드'),
        DescriptionRow(label: '전화번호'),
        DescriptionRow(label: '이메일'),
        DescriptionRow(label: '주소', value: '서울 강남구'),
      ],
    );
  }
}''',
    _ =>
      '''
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
}''',
  };
}
