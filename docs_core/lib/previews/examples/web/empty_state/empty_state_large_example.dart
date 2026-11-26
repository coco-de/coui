import 'package:coui_web/coui_web.dart';

class EmptyStateLargeExample extends StatefulComponent {
  const EmptyStateLargeExample({super.key});

  @override
  State<EmptyStateLargeExample> createState() => _EmptyStateLargeExampleState();
}

class _EmptyStateLargeExampleState extends State<EmptyStateLargeExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      variant: CoreEmptyStateVariant.large,
      icon: Icon(LucideIcons.inbox),
      title: Text('아직 항목이 없어요'),
      description: Text('첫 항목을 추가해 시작해 보세요.'),
    );
  }
}
