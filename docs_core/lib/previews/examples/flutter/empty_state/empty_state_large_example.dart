import 'package:coui_flutter/coui_flutter.dart';

class EmptyStateLargeExample extends StatefulWidget {
  const EmptyStateLargeExample({super.key});

  @override
  State<EmptyStateLargeExample> createState() => _EmptyStateLargeExampleState();
}

class _EmptyStateLargeExampleState extends State<EmptyStateLargeExample> {
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      variant: CoreEmptyStateVariant.large,
      icon: Icon(LucideIcons.inbox),
      title: Text('아직 항목이 없어요'),
      description: Text('첫 항목을 추가해 시작해 보세요.'),
    );
  }
}
