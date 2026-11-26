/// Returns a Web code snippet string for the Command component.
String commandCode(String? variant) {
  return switch (variant) {
    'dialog' =>
      '''
class CommandDialogExample extends StatefulComponent {
  const CommandDialogExample({super.key});

  @override
  State<CommandDialogExample> createState() => _CommandDialogExampleState();
}

class _CommandDialogExampleState extends State<CommandDialogExample> {
  bool _open = false;
  String _query = '';

  static const List<CoreCommandGroup<Component>> _groups = [
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
  Component build(BuildContext context) {
    return div([
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
    ]);
  }
}''',
    'scrollable' =>
      '''
class CommandScrollableExample extends StatefulComponent {
  const CommandScrollableExample({super.key});

  @override
  State<CommandScrollableExample> createState() =>
      _CommandScrollableExampleState();
}

class _CommandScrollableExampleState extends State<CommandScrollableExample> {
  String _query = '';

  static final List<CoreCommandGroup<Component>> _groups = [
    CoreCommandGroup(
      heading: '페이지',
      items: [
        for (var i = 1; i <= 24; i++)
          CoreCommandItem(value: 'page-\$i', label: '페이지 \$i'),
      ],
    ),
  ];

  @override
  Component build(BuildContext context) {
    return Command(
      query: _query,
      onQueryChanged: (q) => setState(() => _query = q),
      onSelect: (_) {},
      groups: _groups,
    );
  }
}''',
    'empty' =>
      '''
class CommandEmptyExample extends StatefulComponent {
  const CommandEmptyExample({super.key});

  @override
  State<CommandEmptyExample> createState() => _CommandEmptyExampleState();
}

class _CommandEmptyExampleState extends State<CommandEmptyExample> {
  String _query = 'zzz';

  @override
  Component build(BuildContext context) {
    return Command(
      query: _query,
      onQueryChanged: (q) => setState(() => _query = q),
      onSelect: (_) {},
      groups: const [
        CoreCommandGroup(
          heading: '추천',
          items: [
            CoreCommandItem(value: 'calendar', label: '캘린더'),
            CoreCommandItem(value: 'search', label: '이모지 검색'),
            CoreCommandItem(value: 'calculator', label: '계산기'),
          ],
        ),
      ],
    );
  }
}''',
    'chain' =>
      '''
class CommandChainExample extends StatefulComponent {
  const CommandChainExample({super.key});

  @override
  State<CommandChainExample> createState() => _CommandChainExampleState();
}

class _CommandChainExampleState extends State<CommandChainExample> {
  String _query = '';

  static const List<CoreCommandGroup<Component>> _groups = [
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
  Component build(BuildContext context) {
    return div(
      [
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
      classes: 'flex flex-col items-start',
    );
  }
}''',
    _ =>
      '''
class CommandDefaultExample extends StatefulComponent {
  const CommandDefaultExample({super.key});

  @override
  State<CommandDefaultExample> createState() => _CommandDefaultExampleState();
}

class _CommandDefaultExampleState extends State<CommandDefaultExample> {
  String _query = '';
  String? _scope;

  @override
  Component build(BuildContext context) {
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
}''',
  };
}
