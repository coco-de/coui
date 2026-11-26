import 'package:coui_web/coui_web.dart';

class SwipeActionsScopeExample extends StatelessComponent {
  const SwipeActionsScopeExample({super.key});

  @override
  Component build(BuildContext context) {
    SwipeActions row(String title, String subtitle) {
      return SwipeActions(
        leadingActions: [
          CoreSwipeAction(
            label: '고정',
            icon: const Icon(LucideIcons.pin),
            onPressed: () => print('Pinned $title'),
          ),
        ],
        trailingActions: [
          CoreSwipeAction(
            label: '보관',
            icon: const Icon(LucideIcons.archive),
            onPressed: () => print('Archived $title'),
          ),
          CoreSwipeAction(
            label: '삭제',
            icon: const Icon(LucideIcons.trash2),
            variant: CoreSwipeActionVariant.destructive,
            onPressed: () => print('Deleted $title'),
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
      child: div(
        [
          row('주간 보고서', '이번 주 진행 상황을 정리했어요'),
          const Divider(),
          row('디자인 리뷰 초대', '내일 오후 2시, 3층 회의실'),
        ],
        classes: 'flex flex-col',
      ),
    );
  }
}
