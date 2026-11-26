String tabPaneCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class TabPaneChainExample extends StatefulComponent {
  const TabPaneChainExample({super.key});

  @override
  State<TabPaneChainExample> createState() => _TabPaneChainExampleState();
}

class _TabPaneChainExampleState extends State<TabPaneChainExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        TabPane(
          tabs: [
            CoreTabItem(
              label: '계정',
              content: div(
                [Text('계정 설정을 관리해요.').bodyMedium.onSurfaceVariant],
                classes: 'p-\${CoreSpace.scale.space20}',
              ),
            ),
            CoreTabItem(
              label: '비밀번호',
              content: div(
                [Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant],
                classes: 'p-\${CoreSpace.scale.space20}',
              ),
            ),
          ],
          selectedIndex: _index,
          onChanged: (index) => setState(() => _index = index),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TabPane(
          tabs: [
            CoreTabItem(
              label: '계정',
              content: div(
                [Text('계정 설정을 관리해요.').bodyMedium.onSurfaceVariant],
                classes: 'p-\${CoreSpace.scale.space20}',
              ),
            ),
            CoreTabItem(
              label: '비밀번호',
              content: div(
                [Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant],
                classes: 'p-\${CoreSpace.scale.space20}',
              ),
            ),
          ],
          selectedIndex: _index,
          onChanged: (index) => setState(() => _index = index),
        ).withStyle(
          const CoreTabPaneStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'editor-strip' => _tabPaneEditorStripCode,
    _ => _tabPaneCode,
  };
}

const _tabPaneCode = '''
class TabPaneExample extends StatefulComponent {
  const TabPaneExample({super.key});

  @override
  State<TabPaneExample> createState() => _TabPaneExampleState();
}

class _TabPaneExampleState extends State<TabPaneExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return TabPane(
      tabs: [
        CoreTabItem(
          label: '계정',
          content: div(
            [Text('계정 설정을 관리해요.').bodyMedium.onSurfaceVariant],
            classes: 'p-\${CoreSpace.scale.space20}',
          ),
        ),
        CoreTabItem(
          label: '비밀번호',
          content: div(
            [Text('여기에서 비밀번호를 바꿔요.').bodyMedium.onSurfaceVariant],
            classes: 'p-\${CoreSpace.scale.space20}',
          ),
        ),
      ],
      selectedIndex: _index,
      onChanged: (index) => setState(() => _index = index),
    );
  }
}''';

const _tabPaneEditorStripCode = '''
class TabPaneEditorStripExample extends StatefulComponent {
  const TabPaneEditorStripExample({super.key});

  @override
  State<TabPaneEditorStripExample> createState() => _TabPaneEditorStripExampleState();
}

class _TabPaneEditorStripExampleState extends State<TabPaneEditorStripExample> {
  final List<String> _files = ['main.dart', 'pubspec.yaml', 'README.md'];
  int _index = 0;

  void _handleClose(int index) {
    if (_files.length == 1) return;
    setState(() {
      _files.removeAt(index);
      if (_index >= _files.length) _index = _files.length - 1;
    });
  }

  @override
  Component build(BuildContext context) {
    return TabPane(
      variant: .editorStrip,
      tabs: [
        for (var i = 0; i < _files.length; i++)
          CoreTabItem(
            label: _files[i],
            leading: Icon(LucideIcons.fileCode),
            onClose: () => _handleClose(i),
          ),
      ],
      selectedIndex: _index,
      onChanged: (index) => setState(() => _index = index),
    );
  }
}''';
