import 'package:coui_web/coui_web.dart';

class AvatarDiameterExample extends StatelessComponent {
  const AvatarDiameterExample({super.key});

  @override
  Component build(BuildContext context) {
    // 크기 단계에 없는 지름은 그 아바타에만 정한다.
    // 이니셜은 고른 크기 단계(lg)의 글자 크기를 그대로 쓴다.
    return div([
      Avatar(
        initials: 'A',
        size: CoreComponentSize.lg,
        avatarStyle: const CoreAvatarStyle(diameter: CoreSize.size44),
      ),
      Avatar(
        initials: 'B',
        size: CoreComponentSize.lg,
        avatarStyle: const CoreAvatarStyle(diameter: CoreSize.size56),
      ),
    ], classes: 'flex items-center gap-${CoreSpace.scale.space12}');
  }
}
