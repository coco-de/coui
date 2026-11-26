/// Returns a Flutter code snippet string for the SwipeActions component.
String swipeActionsCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
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
}''',
    'scope' =>
      '''
class SwipeActionsScopeExample extends StatelessWidget {
  const SwipeActionsScopeExample({super.key});

  @override
  Widget build(BuildContext context) {
    SwipeActions row(String title, String subtitle) {
      return SwipeActions(
        leadingActions: [
          CoreSwipeAction(
            label: '고정',
            icon: const Icon(LucideIcons.pin),
            onPressed: () => debugPrint('Pinned \$title'),
          ),
        ],
        trailingActions: [
          CoreSwipeAction(
            label: '보관',
            icon: const Icon(LucideIcons.archive),
            onPressed: () => debugPrint('Archived \$title'),
          ),
          CoreSwipeAction(
            label: '삭제',
            icon: const Icon(LucideIcons.trash2),
            variant: CoreSwipeActionVariant.destructive,
            onPressed: () => debugPrint('Deleted \$title'),
          ),
        ],
        child: Basic(
          leading: const Icon(LucideIcons.mail),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
      );
    }

    return SwipeActionScope(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row('주간 보고서', '이번 주 진행 상황을 정리했어요'),
          const Divider(),
          row('디자인 리뷰 초대', '내일 오후 2시, 3층 회의실'),
        ],
      ),
    );
  }
}''',
    _ =>
      '''
class SwipeActionsDefaultExample extends StatelessWidget {
  const SwipeActionsDefaultExample({super.key});

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
    );
  }
}''',
  };
}
