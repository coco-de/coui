import 'package:coui_flutter/coui_flutter.dart';

class AvatarDiameterExample extends StatelessWidget {
  const AvatarDiameterExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 크기 단계에 없는 지름은 그 아바타에만 정한다.
    // 이니셜은 고른 크기 단계(lg)의 글자 크기를 그대로 쓴다.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Avatar(
          initials: 'A',
          size: CoreComponentSize.lg,
          avatarStyle: CoreAvatarStyle(diameter: CoreSize.size44),
        ),
        Gap.space12(),
        Avatar(
          initials: 'B',
          size: CoreComponentSize.lg,
          avatarStyle: CoreAvatarStyle(diameter: CoreSize.size56),
        ),
      ],
    );
  }
}
