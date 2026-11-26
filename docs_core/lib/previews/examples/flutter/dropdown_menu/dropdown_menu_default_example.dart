import 'package:coui_flutter/coui_flutter.dart';

class DropdownMenuDefaultExample extends StatelessWidget {
  const DropdownMenuDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      trigger: Button(
        variant: CoreButtonVariant.outline,
        onPressed: () {},
        child: const Text('메뉴 열기'),
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
