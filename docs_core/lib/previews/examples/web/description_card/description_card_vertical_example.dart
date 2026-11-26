import 'package:coui_web/coui_web.dart';

class DescriptionCardVerticalExample extends StatelessComponent {
  const DescriptionCardVerticalExample({super.key});

  @override
  Component build(BuildContext context) {
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
}
