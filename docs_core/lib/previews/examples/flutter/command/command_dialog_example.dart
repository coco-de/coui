import 'package:coui_flutter/coui_flutter.dart';

class CommandDialogExample extends StatefulWidget {
  const CommandDialogExample({super.key});

  @override
  State<CommandDialogExample> createState() => _CommandDialogExampleState();
}

class _CommandDialogExampleState extends State<CommandDialogExample> {
  bool _open = false;
  String _query = '';

  static const List<CoreCommandGroup<Widget>> _groups = [
    CoreCommandGroup(
      heading: '추천',
      items: [
        CoreCommandItem(
          value: 'calendar',
          label: '캘린더',
          icon: Icon(LucideIcons.calendar),
          keywords: ['date', 'schedule', '날짜', '일정'],
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
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () => setState(() => _open = true),
          child: const Text('메뉴 열기'),
        ),
        Dialog(
          open: _open,
          onClose: () => setState(() => _open = false),
          dialogStyle: const CoreDialogStyle(
            panelPadding: CoreEdgeInsets.all(CoreSpace.space0),
            panelMaxWidth: CoreLayout.layout640,
          ),
          content: Command(
            presentation: CoreCommandPresentation.dialog,
            query: _query,
            onQueryChanged: (q) => setState(() => _query = q),
            onSelect: (_) => setState(() => _open = false),
            onDismiss: () => setState(() => _open = false),
            groups: _groups,
          ),
        ),
      ],
    );
  }
}
