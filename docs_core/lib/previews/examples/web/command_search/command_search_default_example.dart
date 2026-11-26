import 'package:coui_web/coui_web.dart';

class CommandSearchDefaultExample extends StatelessComponent {
  const CommandSearchDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // 트리거는 자기 폭을 정하지 않는다 — 앱 바의 가운데 칸 같은 부모가
    // 정한다. 프리뷰에서는 폭 상한(`layout320`)을 부모가 대신 준다.
    return div(
      [
        CommandSearch(
          shortcut: const Kbd(keys: ['⌘K']),
          onPressed: () {},
        ),
      ],
      classes: 'w-${CoreLayout.scale.layout320}',
    );
  }
}
