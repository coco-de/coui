import 'package:coui_web/coui_web.dart';

class PopupDefaultExample extends StatelessComponent {
  const PopupDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Popup(
      children: [
        div(
          [Text('프로필').bodyMedium],
          classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
        ),
        div(
          [Text('설정').bodyMedium],
          classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
        ),
        div(
          [Text('로그아웃').bodyMedium],
          classes: 'px-${CoreSpace.scale.space8} py-${CoreSpace.scale.space4}',
        ),
      ],
    );
  }
}
