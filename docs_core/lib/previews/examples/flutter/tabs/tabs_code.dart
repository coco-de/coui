/// Returns a Flutter code snippet string for the Tabs component.
String tabsCode(String? variant) {
  return switch (variant) {
    'badge' => _tabsBadgeCode,
    'closable' => _tabsClosableCode,
    'chain' => _tabsChainCode,
    'line' => _tabsLineCode,
    _ => _tabsDefaultCode,
  };
}

const _tabsChainCode = '''
class TabsChainExample extends StatefulWidget {
  const TabsChainExample({super.key});

  @override
  State<TabsChainExample> createState() => _TabsChainExampleState();
}

class _TabsChainExampleState extends State<TabsChainExample> {
  static const _contents = [
    '계정 설정을 관리해요.',
    '여기에서 비밀번호를 바꿔요.',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tabs(
              tabs: const [
                CoreTabItem(label: '계정'),
                CoreTabItem(label: '비밀번호'),
              ],
              selectedIndex: _index,
              onChanged: (i) => setState(() => _index = i),
            )
            .withStyle(
              const CoreTabsStyle(
                tabPadding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space16,
                  vertical: CoreSpace.space8,
                ),
                containerRadius: CoreBorderRadius.all(CoreRadius.radius24),
                tabSpacing: CoreSpace.space8,
              ),
            )
            .surfaceContainer,
        const Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
    );
  }
}''';

const _tabsDefaultCode = '''
class TabsDefaultExample extends StatefulWidget {
  const TabsDefaultExample({super.key});

  @override
  State<TabsDefaultExample> createState() => _TabsDefaultExampleState();
}

class _TabsDefaultExampleState extends State<TabsDefaultExample> {
  static const _contents = [
    '계정 설정을 관리해요.',
    '여기에서 비밀번호를 바꿔요.',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tabs(
          tabs: const [
            CoreTabItem(label: '계정'),
            CoreTabItem(label: '비밀번호'),
          ],
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
        const Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
    );
  }
}''';

const _tabsLineCode = '''
class TabsLineExample extends StatefulWidget {
  const TabsLineExample({super.key});

  @override
  State<TabsLineExample> createState() => _TabsLineExampleState();
}

class _TabsLineExampleState extends State<TabsLineExample> {
  static const _contents = [
    '계정 설정을 관리해요.',
    '여기에서 비밀번호를 바꿔요.',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tabs(
          tabs: const [
            CoreTabItem(label: '계정'),
            CoreTabItem(label: '비밀번호'),
          ],
          selectedIndex: _index,
          variant: CoreTabVariant.underline,
          onChanged: (i) => setState(() => _index = i),
        ),
        const Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
    );
  }
}''';

const _tabsBadgeCode = '''
class TabsBadgeExample extends StatefulWidget {
  const TabsBadgeExample({super.key});

  @override
  State<TabsBadgeExample> createState() => _TabsBadgeExampleState();
}

class _TabsBadgeExampleState extends State<TabsBadgeExample> {
  static const _contents = [
    '읽지 않은 메시지가 3개 있어요.',
    '아직 보낸 메시지가 없어요.',
    '작성 중인 글은 자동으로 저장돼요.',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tabs(
          tabs: const [
            CoreTabItem(
              label: '받은편지함',
              badge: Badge(
                variant: CoreBadgeVariant.filled,
                form: CoreBadgeForm.count,
                size: CoreComponentSize.xs,
                child: Text('3'),
              ),
            ),
            CoreTabItem(label: '보낸편지함'),
            CoreTabItem(label: '임시보관함'),
          ],
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
        const Gap.space16(),
        Text(_contents[_index]).bodyMedium.onSurface,
      ],
    );
  }
}''';

const _tabsClosableCode = r'''
class TabsClosableExample extends StatefulWidget {
  const TabsClosableExample({super.key});

  @override
  State<TabsClosableExample> createState() => _TabsClosableExampleState();
}

class _TabsClosableExampleState extends State<TabsClosableExample> {
  static const _files = ['main.dart', 'app.dart', 'theme.dart'];

  final _open = [..._files];
  int _index = 0;

  void _close(int index) {
    setState(() {
      _open.removeAt(index);
      if (index < _index || _index == _open.length) {
        _index = (_index - 1).clamp(0, _open.length);
      }
    });
  }

  void _reopen() {
    setState(() {
      _open
        ..clear()
        ..addAll(_files);
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_open.isEmpty)
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: _reopen,
            child: const Text('파일 다시 열기'),
          )
        else
          Tabs(
            tabs: [
              for (final (i, file) in _open.indexed) CoreTabItem(label: file, onClose: () => _close(i)),
            ],
            selectedIndex: _index,
            onChanged: (i) => setState(() => _index = i),
          ),
        const Gap.space16(),
        Text(
          _open.isEmpty ? '모든 파일을 닫았어요.' : '편집 중: ${_open[_index]}',
        ).bodyMedium.onSurface,
      ],
    );
  }
}''';
