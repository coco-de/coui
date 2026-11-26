import 'package:coui_web/coui_web.dart';

class DropdownMenuDefaultExample extends StatelessComponent {
  const DropdownMenuDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return DropdownMenu(
      trigger: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: Text('메뉴 열기'),
      ),
      items: [
        CoreMenuItem.action('프로필', onPressed: () {}),
        CoreMenuItem.action('설정', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('로그아웃', onPressed: () {}),
      ],
    );
  }
}
