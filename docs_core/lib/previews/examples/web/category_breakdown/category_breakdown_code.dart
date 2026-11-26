/// Returns a Web code snippet string for the CategoryBreakdown component.
String categoryBreakdownCode(String? variant) {
  return switch (variant) {
    'donut' =>
      '''class CategoryBreakdownDonutExample extends StatelessComponent {
  const CategoryBreakdownDonutExample({super.key});

  @override
  Component build(BuildContext context) {
    return CategoryBreakdown(
      variant: CoreCategoryBreakdownVariant.donut,
      semanticLabel: '문의 유형별 분포',
      center: const Text('234건').titleMedium.semiBold,
      items: const [
        CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
        CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
        CoreCategoryBreakdownItem(label: '계정 · 로그인', value: 33, valueLabel: '33건'),
        CoreCategoryBreakdownItem(label: '기타', value: 12, valueLabel: '12건'),
      ],
    );
  }
}''',
    'chain' =>
      '''class CategoryBreakdownChainExample extends StatelessComponent {
  const CategoryBreakdownChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return CategoryBreakdown(
      semanticLabel: '문의 유형별 분포',
      items: const [
        CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
        CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
        CoreCategoryBreakdownItem(label: '계정 · 로그인', value: 33, valueLabel: '33건'),
        CoreCategoryBreakdownItem(label: '기타', value: 12, valueLabel: '12건'),
      ],
    ).withStyle(
      const CoreCategoryBreakdownStyle(
        barHeight: CoreSpace.space12,
        rowSpacing: CoreSpace.space16,
      ),
    );
  }
}''',
    _ =>
      '''class CategoryBreakdownDefaultExample extends StatelessComponent {
  const CategoryBreakdownDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return CategoryBreakdown(
      semanticLabel: '문의 유형별 분포',
      items: const [
        CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
        CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
        CoreCategoryBreakdownItem(label: '계정 · 로그인', value: 33, valueLabel: '33건'),
        CoreCategoryBreakdownItem(label: '기타', value: 12, valueLabel: '12건'),
      ],
    );
  }
}''',
  };
}
