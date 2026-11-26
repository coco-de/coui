/// Returns a Flutter code snippet string for the Menubar component.
String menubarCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class MenubarChainExample extends StatelessWidget {
  const MenubarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Menubar(
      menus: const [
        CoreMenubarMenu(
          label: '파일',
          entries: [
            CoreMenubarEntry.action(label: '새로 만들기', shortcut: 'Ctrl+N'),
            CoreMenubarEntry.action(label: '열기', shortcut: 'Ctrl+O'),
            CoreMenubarEntry.divider(),
            CoreMenubarEntry.action(label: '종료'),
          ],
        ),
        CoreMenubarMenu(
          label: '편집',
          entries: [
            CoreMenubarEntry.action(label: '잘라내기', shortcut: 'Ctrl+X'),
            CoreMenubarEntry.action(label: '복사', shortcut: 'Ctrl+C'),
            CoreMenubarEntry.action(label: '붙여넣기', shortcut: 'Ctrl+V'),
          ],
        ),
        CoreMenubarMenu(
          label: '보기',
          entries: [
            CoreMenubarEntry.action(label: '확대'),
            CoreMenubarEntry.action(label: '축소'),
            CoreMenubarEntry.divider(),
            CoreMenubarEntry.action(label: '전체 화면'),
          ],
        ),
      ],
    ).withStyle(
      const CoreMenubarStyle(
        barPadding: CoreEdgeInsets.all(CoreSpace.space8),
        barBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        barBorderWidth: CoreStrokeWidth.stroke2,
        barBackgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        barBorderColor: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}''',
    _ =>
      '''
class MenubarDefaultExample extends StatelessWidget {
  const MenubarDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Menubar(
      menus: const [
        CoreMenubarMenu(
          label: '파일',
          entries: [
            CoreMenubarEntry.action(label: '새로 만들기', shortcut: 'Ctrl+N'),
            CoreMenubarEntry.action(label: '열기', shortcut: 'Ctrl+O'),
            CoreMenubarEntry.divider(),
            CoreMenubarEntry.action(label: '종료'),
          ],
        ),
        CoreMenubarMenu(
          label: '편집',
          entries: [
            CoreMenubarEntry.action(label: '잘라내기', shortcut: 'Ctrl+X'),
            CoreMenubarEntry.action(label: '복사', shortcut: 'Ctrl+C'),
            CoreMenubarEntry.action(label: '붙여넣기', shortcut: 'Ctrl+V'),
          ],
        ),
        CoreMenubarMenu(
          label: '보기',
          entries: [
            CoreMenubarEntry.action(label: '확대'),
            CoreMenubarEntry.action(label: '축소'),
            CoreMenubarEntry.divider(),
            CoreMenubarEntry.action(label: '전체 화면'),
          ],
        ),
      ],
    );
  }
}''',
  };
}
