import 'package:coui_flutter/coui_flutter.dart';

class EmptyStateFailureExample extends StatefulWidget {
  const EmptyStateFailureExample({super.key});

  @override
  State<EmptyStateFailureExample> createState() => _EmptyStateFailureExampleState();
}

class _EmptyStateFailureExampleState extends State<EmptyStateFailureExample> {
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      tone: CoreEmptyStateTone.failure,
      icon: const Icon(LucideIcons.circleAlert),
      title: const Text('결과를 불러오지 못했어요'),
      description: const Text('연결을 확인하고 다시 시도해 주세요.'),
      action: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('다시 시도'),
      ),
    );
  }
}
