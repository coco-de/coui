import 'package:coui_web/coui_web.dart';

class EmptyStateSuccessExample extends StatefulComponent {
  const EmptyStateSuccessExample({super.key});

  @override
  State<EmptyStateSuccessExample> createState() => _EmptyStateSuccessExampleState();
}

class _EmptyStateSuccessExampleState extends State<EmptyStateSuccessExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      tone: CoreEmptyStateTone.success,
      icon: Icon(LucideIcons.circleCheck),
      title: Text('모두 끝났어요'),
      description: Text('모든 항목을 처리했어요.'),
    );
  }
}
