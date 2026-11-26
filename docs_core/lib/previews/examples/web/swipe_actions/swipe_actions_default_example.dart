import 'package:coui_web/coui_web.dart';

class SwipeActionsDefaultExample extends StatelessComponent {
  const SwipeActionsDefaultExample({super.key});

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
    );
  }
}
