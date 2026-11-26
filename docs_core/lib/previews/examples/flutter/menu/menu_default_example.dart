import 'package:coui_flutter/coui_flutter.dart';

class MenuDefaultExample extends StatelessWidget {
  const MenuDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Menu(
      ariaLabel: '주 메뉴',
      items: [
        const CoreMenuItem.label('탐색'),
        CoreMenuItem.action('홈', onPressed: () {}, active: true),
        CoreMenuItem.action('프로필', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.checkbox('격자 보기', onChanged: (_) {}, checked: true),
        CoreMenuItem.action('설정', disabled: true),
      ],
    );
  }
}
