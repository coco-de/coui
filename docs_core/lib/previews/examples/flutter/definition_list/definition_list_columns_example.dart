import 'package:coui_flutter/coui_flutter.dart';

class DefinitionListColumnsExample extends StatelessWidget {
  const DefinitionListColumnsExample({super.key});

  @override
  Widget build(BuildContext context) {
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
