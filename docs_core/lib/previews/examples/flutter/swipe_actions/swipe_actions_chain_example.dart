import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSwipeActionsStyle] slot without constructing the
/// widget from scratch.
class SwipeActionsChainExample extends StatelessWidget {
  const SwipeActionsChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SwipeActions(
      trailingActions: [
        CoreSwipeAction(
          label: '보관',
          icon: const Icon(LucideIcons.archive),
          onPressed: () => debugPrint('Archived'),
        ),
        CoreSwipeAction(
          label: '삭제',
          icon: const Icon(LucideIcons.trash2),
          variant: CoreSwipeActionVariant.destructive,
          onPressed: () => debugPrint('Deleted'),
        ),
      ],
      child: Basic(
        leading: const Icon(LucideIcons.mail),
        title: const Text('주간 보고서'),
        subtitle: const Text('이번 주 진행 상황을 정리했어요'),
      ),
    ).withStyle(
      const CoreSwipeActionsStyle(
        platterColor: CoreColor.token(CoreColors.surfaceContainer),
        fullSwipeScale: 1.08,
      ),
    );
  }
}
