import 'package:coui_web/coui_web.dart';

class MenubarDefaultExample extends StatelessComponent {
  const MenubarDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
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
}
