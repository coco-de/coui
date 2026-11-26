import 'package:coui_flutter/coui_flutter.dart';

/// T1 저작 규약 형태의 chain 예제 — 두 인스턴스로 구성한다:
/// (1) 토큰-정확 getter **combo 체인** 1개 (`.radius16.primary` — radius
/// 축·색 축 getter 가 base 전체에서 정확히 1회씩, 랜덤 순열 토글의 치환
/// 앵커), (2) **withStyle full-control** 1개 — getter 밖 필드까지 조합해
/// `CoreCommandStyle` 슬롯 전체를 여는 경로.
class CommandChainExample extends StatefulWidget {
  const CommandChainExample({super.key});

  @override
  State<CommandChainExample> createState() => _CommandChainExampleState();
}

class _CommandChainExampleState extends State<CommandChainExample> {
  String _query = '';

  static const List<CoreCommandGroup<Widget>> _groups = [
    CoreCommandGroup(
      heading: '추천',
      items: [
        CoreCommandItem(
          value: 'calendar',
          label: '캘린더',
          icon: Icon(LucideIcons.calendar),
        ),
        CoreCommandItem(
          value: 'search',
          label: '이모지 검색',
          icon: Icon(LucideIcons.smile),
        ),
        CoreCommandItem(
          value: 'calculator',
          label: '계산기',
          icon: Icon(LucideIcons.calculator),
        ),
      ],
    ),
    CoreCommandGroup(
      heading: '설정',
      items: [
        CoreCommandItem(
          value: 'profile',
          label: '프로필',
          icon: Icon(LucideIcons.user),
          shortcut: '⌘P',
        ),
        CoreCommandItem(
          value: 'billing',
          label: '결제',
          icon: Icon(LucideIcons.creditCard),
          shortcut: '⌘B',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Command(
          query: _query,
          onQueryChanged: (q) => setState(() => _query = q),
          onSelect: (_) {},
          groups: _groups,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(searchPadding)까지 한 번에.
        Command(
          query: _query,
          onQueryChanged: (q) => setState(() => _query = q),
          onSelect: (_) {},
          groups: _groups,
        ).withStyle(
          const CoreCommandStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
            searchPadding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
    );
  }
}
