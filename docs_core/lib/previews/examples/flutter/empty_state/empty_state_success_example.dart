import 'package:coui_flutter/coui_flutter.dart';

class EmptyStateSuccessExample extends StatefulWidget {
  const EmptyStateSuccessExample({super.key});

  @override
  State<EmptyStateSuccessExample> createState() => _EmptyStateSuccessExampleState();
}

class _EmptyStateSuccessExampleState extends State<EmptyStateSuccessExample> {
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      tone: CoreEmptyStateTone.success,
      icon: Icon(LucideIcons.circleCheck),
      title: Text('모두 끝났어요'),
      description: Text('모든 항목을 처리했어요.'),
    );
  }
}
