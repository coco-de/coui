import 'package:coui_flutter/coui_flutter.dart';

class EmptyStateNormalExample extends StatefulWidget {
  const EmptyStateNormalExample({super.key});

  @override
  State<EmptyStateNormalExample> createState() => _EmptyStateNormalExampleState();
}

class _EmptyStateNormalExampleState extends State<EmptyStateNormalExample> {
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      variant: CoreEmptyStateVariant.normal,
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    );
  }
}
