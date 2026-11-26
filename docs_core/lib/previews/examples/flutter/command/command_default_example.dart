import 'package:coui_flutter/coui_flutter.dart';

class CommandDefaultExample extends StatefulWidget {
  const CommandDefaultExample({super.key});

  @override
  State<CommandDefaultExample> createState() => _CommandDefaultExampleState();
}

class _CommandDefaultExampleState extends State<CommandDefaultExample> {
  String _query = '';
  String? _scope;

  @override
  Widget build(BuildContext context) {
    return Command(
      query: _query,
      onQueryChanged: (q) => setState(() => _query = q),
      scopes: const [
        CoreCommandScope(value: 'actions', label: '작업'),
        CoreCommandScope(value: 'pages', label: '페이지'),
      ],
      scope: _scope,
      onScopeChanged: (next) => setState(() => _scope = next),
      onSelect: (_) {},
      groups: const [
        CoreCommandGroup(
          heading: '추천',
          scope: 'actions',
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
          scope: 'pages',
          items: [
            CoreCommandItem(
              value: 'profile',
              label: '프로필',
              overline: '계정',
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
      ],
    );
  }
}
