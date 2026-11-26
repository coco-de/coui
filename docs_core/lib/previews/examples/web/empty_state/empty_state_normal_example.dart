import 'package:coui_web/coui_web.dart';

class EmptyStateNormalExample extends StatefulComponent {
  const EmptyStateNormalExample({super.key});

  @override
  State<EmptyStateNormalExample> createState() => _EmptyStateNormalExampleState();
}

class _EmptyStateNormalExampleState extends State<EmptyStateNormalExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      variant: CoreEmptyStateVariant.normal,
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    );
  }
}
