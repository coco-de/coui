import 'package:coui_web/coui_web.dart';

class DescriptionCardPlaceholderExample extends StatelessComponent {
  const DescriptionCardPlaceholderExample({super.key});

  @override
  Component build(BuildContext context) {
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
}
