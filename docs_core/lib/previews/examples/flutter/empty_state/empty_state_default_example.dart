import 'package:coui_flutter/coui_flutter.dart';

class EmptyStateDefaultExample extends StatefulWidget {
  const EmptyStateDefaultExample({super.key});

  @override
  State<EmptyStateDefaultExample> createState() => _EmptyStateDefaultExampleState();
}

class _EmptyStateDefaultExampleState extends State<EmptyStateDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    );
  }
}
