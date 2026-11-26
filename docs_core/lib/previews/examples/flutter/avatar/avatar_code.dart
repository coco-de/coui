/// Returns a Flutter code snippet string for the Avatar component.
String avatarCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class AvatarChainExample extends StatelessWidget {
  const AvatarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const Avatar(initials: 'A').radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(ringColor/ringWidth)까지.
        const Avatar(initials: 'B').withStyle(
          const CoreAvatarStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiaryContainer),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            ringColor: CoreColor.token(CoreColors.tertiary),
            ringWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}''',
    'diameter' =>
      '''
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
}''',
    'initials' =>
      '''
class AvatarInitialsExample extends StatefulWidget {
  const AvatarInitialsExample({super.key});

  @override
  State<AvatarInitialsExample> createState() => _AvatarInitialsExampleState();
}

class _AvatarInitialsExampleState extends State<AvatarInitialsExample> {
  @override
  Widget build(BuildContext context) {
    return const Avatar(
      initials: 'A',
    );
  }
}''',
    'rounded' =>
      '''
class AvatarRoundedExample extends StatelessWidget {
  const AvatarRoundedExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Avatar(
      initials: 'A',
      shape: CoreAvatarShape.rounded,
    );
  }
}''',
    'placeholder' =>
      '''
class AvatarPlaceholderExample extends StatefulWidget {
  const AvatarPlaceholderExample({super.key});

  @override
  State<AvatarPlaceholderExample> createState() =>
      _AvatarPlaceholderExampleState();
}

class _AvatarPlaceholderExampleState extends State<AvatarPlaceholderExample> {
  @override
  Widget build(BuildContext context) {
    return const Avatar();
  }
}''',
    _ =>
      '''
class AvatarDefaultExample extends StatefulWidget {
  const AvatarDefaultExample({super.key});

  @override
  State<AvatarDefaultExample> createState() => _AvatarDefaultExampleState();
}

class _AvatarDefaultExampleState extends State<AvatarDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const Avatar(
      initials: 'A',
    );
  }
}''',
  };
}
