/// Returns a Flutter code snippet string for the Button component.
String buttonCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ButtonChainExample extends StatelessWidget {
  const ButtonChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('기본').lineLimit(1).ellipsis,
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('직접 지정').lineLimit(1).ellipsis,
        ).withStyle(
          const CoreButtonStyle(
            backgroundColor: .tertiary,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
    );
  }
}''',
    'destructive' =>
      '''
class ButtonDestructiveExample extends StatefulWidget {
  const ButtonDestructiveExample({super.key});

  @override
  State<ButtonDestructiveExample> createState() => _ButtonDestructiveExampleState();
}

class _ButtonDestructiveExampleState extends State<ButtonDestructiveExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.destructive,
      onPressed: () {},
      child: Text('삭제').lineLimit(1).ellipsis,
    );
  }
}''',
    'ghost' =>
      '''
class ButtonGhostExample extends StatefulWidget {
  const ButtonGhostExample({super.key});

  @override
  State<ButtonGhostExample> createState() => _ButtonGhostExampleState();
}

class _ButtonGhostExampleState extends State<ButtonGhostExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.ghost,
      onPressed: () {},
      child: Text('고스트').lineLimit(1).ellipsis,
    );
  }
}''',
    'outline' =>
      '''
class ButtonOutlineExample extends StatefulWidget {
  const ButtonOutlineExample({super.key});

  @override
  State<ButtonOutlineExample> createState() => _ButtonOutlineExampleState();
}

class _ButtonOutlineExampleState extends State<ButtonOutlineExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {},
      child: Text('외곽선').lineLimit(1).ellipsis,
    );
  }
}''',
    'secondary' =>
      '''
class ButtonSecondaryExample extends StatefulWidget {
  const ButtonSecondaryExample({super.key});

  @override
  State<ButtonSecondaryExample> createState() => _ButtonSecondaryExampleState();
}

class _ButtonSecondaryExampleState extends State<ButtonSecondaryExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.secondary,
      onPressed: () {},
      child: Text('보조').lineLimit(1).ellipsis,
    );
  }
}''',
    'tonal' =>
      '''
class ButtonTonalExample extends StatefulWidget {
  const ButtonTonalExample({super.key});

  @override
  State<ButtonTonalExample> createState() => _ButtonTonalExampleState();
}

class _ButtonTonalExampleState extends State<ButtonTonalExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.tonal,
      onPressed: () {},
      child: Text('톤').lineLimit(1).ellipsis,
    );
  }
}''',
    'plain' =>
      '''
class ButtonPlainExample extends StatefulWidget {
  const ButtonPlainExample({super.key});

  @override
  State<ButtonPlainExample> createState() => _ButtonPlainExampleState();
}

class _ButtonPlainExampleState extends State<ButtonPlainExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.plain,
      onPressed: () {},
      child: Text('플레인').lineLimit(1).ellipsis,
    );
  }
}''',
    'card' =>
      '''
class ButtonCardExample extends StatefulWidget {
  const ButtonCardExample({super.key});

  @override
  State<ButtonCardExample> createState() => _ButtonCardExampleState();
}

class _ButtonCardExampleState extends State<ButtonCardExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {},
      child: Text('카드').lineLimit(1).ellipsis,
    ).withStyle(
      const CoreButtonStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    );
  }
}''',
    'cast-motion' =>
      '''
class ButtonCastMotionExample extends StatefulWidget {
  const ButtonCastMotionExample({super.key});

  @override
  State<ButtonCastMotionExample> createState() =>
      _ButtonCastMotionExampleState();
}

class _ButtonCastMotionExampleState extends State<ButtonCastMotionExample> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          buttonStyle: const CoreButtonStyle(
            castMotion: CoreCastMotion.defaultMotion,
          ),
          onPressed: () {},
          child: Text('기본').lineLimit(1).ellipsis,
        ),
        const Gap.space12(),
        Button(
          variant: CoreButtonVariant.primary,
          buttonStyle: const CoreButtonStyle(
            castMotion: CoreCastMotion.noShadow,
          ),
          onPressed: () {},
          child: Text('그림자 없음').lineLimit(1).ellipsis,
        ),
        const Gap.space12(),
        Button(
          variant: CoreButtonVariant.primary,
          buttonStyle: const CoreButtonStyle(castMotion: CoreCastMotion.reverse),
          onPressed: () {},
          child: Text('반대로').lineLimit(1).ellipsis,
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class ButtonPrimaryExample extends StatefulWidget {
  const ButtonPrimaryExample({super.key});

  @override
  State<ButtonPrimaryExample> createState() => _ButtonPrimaryExampleState();
}

class _ButtonPrimaryExampleState extends State<ButtonPrimaryExample> {
  @override
  Widget build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.primary,
      onPressed: () {},
      child: Text('기본').lineLimit(1).ellipsis,
    );
  }
}''',
  };
}
