import 'package:coui_web/coui_web.dart';

class DescriptionCardGhostExample extends StatelessComponent {
  const DescriptionCardGhostExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DescriptionCard(
      variant: CoreDescriptionCardVariant.ghost,
      rows: [
        DescriptionRow(label: '이름', value: '이코드'),
        DescriptionRow(label: '이메일', value: 'kim@example.com'),
        DescriptionRow(label: '전화번호', value: '010-1234-5678'),
      ],
    );
  }
}
