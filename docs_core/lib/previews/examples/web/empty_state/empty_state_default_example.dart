import 'package:coui_web/coui_web.dart';

class EmptyStateDefaultExample extends StatefulComponent {
  const EmptyStateDefaultExample({super.key});

  @override
  State<EmptyStateDefaultExample> createState() => _EmptyStateDefaultExampleState();
}

class _EmptyStateDefaultExampleState extends State<EmptyStateDefaultExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    );
  }
}
