import 'package:coui_flutter/coui_flutter.dart';

class CategoryBreakdownDefaultExample extends StatelessWidget {
  const CategoryBreakdownDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
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
}
