import 'package:coui_flutter/coui_flutter.dart';

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
}
