import 'package:coui_web/coui_web.dart';

class DefinitionListColumnsExample extends StatelessComponent {
  const DefinitionListColumnsExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DefinitionList(
      items: [
        CoreDefinitionEntry(term: '상호', description: '주식회사 코코드'),
        CoreDefinitionEntry(term: '대표', description: '한동우'),
        CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
      ],
      layout: CoreDefinitionLayout.columns,
      numeric: true,
    );
  }
}
