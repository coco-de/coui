import 'package:coui_flutter/coui_flutter.dart';

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
            onPressed: () => debugPrint('Pinned $title'),
          ),
        ],
        trailingActions: [
          CoreSwipeAction(
            label: '보관',
            icon: const Icon(LucideIcons.archive),
            onPressed: () => debugPrint('Archived $title'),
          ),
          CoreSwipeAction(
            label: '삭제',
            icon: const Icon(LucideIcons.trash2),
            variant: CoreSwipeActionVariant.destructive,
            onPressed: () => debugPrint('Deleted $title'),
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
}
