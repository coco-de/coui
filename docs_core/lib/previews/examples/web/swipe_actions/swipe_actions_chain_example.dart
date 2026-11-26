import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreSwipeActionsStyle] slot without constructing the
/// component from scratch.
class SwipeActionsChainExample extends StatelessComponent {
  const SwipeActionsChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return SwipeActions(
      trailingActions: [
        CoreSwipeAction(
          label: '보관',
          icon: const Icon(LucideIcons.archive),
          onPressed: () => print('Archived'),
        ),
        CoreSwipeAction(
          label: '삭제',
          icon: const Icon(LucideIcons.trash2),
          variant: CoreSwipeActionVariant.destructive,
          onPressed: () => print('Deleted'),
        ),
      ],
      child: Basic(
        leading: const Icon(LucideIcons.mail),
        title: Text('주간 보고서'),
        subtitle: Text('이번 주 진행 상황을 정리했어요'),
      ),
    ).withStyle(
      const CoreSwipeActionsStyle(
        platterColor: CoreColor.token(CoreColors.surfaceContainer),
        fullSwipeScale: 1.08,
      ),
    );
  }
}
