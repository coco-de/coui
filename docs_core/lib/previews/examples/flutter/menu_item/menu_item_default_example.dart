import 'package:coui_flutter/coui_flutter.dart';

class MenuItemDefaultExample extends StatelessWidget {
  const MenuItemDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 행은 자기 폭을 정하지 않는다 — 메뉴 패널이 정한다. 프리뷰에서는
    // 패널 폭 상한(`layout280`)을 부모가 대신 준다.
    return SizedBox(
      width: CoreLayout.layout280,
      child: MenuItem(
        onPressed: () {},
        label: const Text('복사'),
        shortcut: const Text('⌘C'),
        leading: const Icon(LucideIcons.copy),
      ),
    );
  }
}
