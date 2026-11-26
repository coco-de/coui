/// Returns a Web code snippet string for the Button component.
String buttonCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ButtonChainExample extends StatelessComponent {
  const ButtonChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('기본').lineLimit(1).ellipsis,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('직접 지정').lineLimit(1).ellipsis,
        ).withStyle(
          const CoreButtonStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'destructive' =>
      '''
class ButtonDestructiveExample extends StatefulComponent {
  const ButtonDestructiveExample({super.key});

  @override
  State<ButtonDestructiveExample> createState() => _ButtonDestructiveExampleState();
}

class _ButtonDestructiveExampleState extends State<ButtonDestructiveExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.destructive,
      onPressed: () {},
      child: Text('삭제').lineLimit(1).ellipsis,
    );
  }
}''',
    'ghost' =>
      '''
class ButtonGhostExample extends StatefulComponent {
  const ButtonGhostExample({super.key});

  @override
  State<ButtonGhostExample> createState() => _ButtonGhostExampleState();
}

class _ButtonGhostExampleState extends State<ButtonGhostExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.ghost,
      onPressed: () {},
      child: Text('고스트').lineLimit(1).ellipsis,
    );
  }
}''',
    'outline' =>
      '''
class ButtonOutlineExample extends StatefulComponent {
  const ButtonOutlineExample({super.key});

  @override
  State<ButtonOutlineExample> createState() => _ButtonOutlineExampleState();
}

class _ButtonOutlineExampleState extends State<ButtonOutlineExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {},
      child: Text('외곽선').lineLimit(1).ellipsis,
    );
  }
}''',
    'secondary' =>
      '''
class ButtonSecondaryExample extends StatefulComponent {
  const ButtonSecondaryExample({super.key});

  @override
  State<ButtonSecondaryExample> createState() => _ButtonSecondaryExampleState();
}

class _ButtonSecondaryExampleState extends State<ButtonSecondaryExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.secondary,
      onPressed: () {},
      child: Text('보조').lineLimit(1).ellipsis,
    );
  }
}''',
    'tonal' =>
      '''
class ButtonTonalExample extends StatefulComponent {
  const ButtonTonalExample({super.key});

  @override
  State<ButtonTonalExample> createState() => _ButtonTonalExampleState();
}

class _ButtonTonalExampleState extends State<ButtonTonalExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.tonal,
      onPressed: () {},
      child: Text('톤').lineLimit(1).ellipsis,
    );
  }
}''',
    'plain' =>
      '''
class ButtonPlainExample extends StatefulComponent {
  const ButtonPlainExample({super.key});

  @override
  State<ButtonPlainExample> createState() => _ButtonPlainExampleState();
}

class _ButtonPlainExampleState extends State<ButtonPlainExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.plain,
      onPressed: () {},
      child: Text('플레인').lineLimit(1).ellipsis,
    );
  }
}''',
    'card' =>
      '''
class ButtonCardExample extends StatefulComponent {
  const ButtonCardExample({super.key});

  @override
  State<ButtonCardExample> createState() => _ButtonCardExampleState();
}

class _ButtonCardExampleState extends State<ButtonCardExample> {
  @override
  Component build(BuildContext context) {
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
class ButtonCastMotionExample extends StatefulComponent {
  const ButtonCastMotionExample({super.key});

  @override
  State<ButtonCastMotionExample> createState() =>
      _ButtonCastMotionExampleState();
}

class _ButtonCastMotionExampleState extends State<ButtonCastMotionExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
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
      classes: 'flex flex-row items-center',
    );
  }
}''',
    _ =>
      '''
class ButtonPrimaryExample extends StatefulComponent {
  const ButtonPrimaryExample({super.key});

  @override
  State<ButtonPrimaryExample> createState() => _ButtonPrimaryExampleState();
}

class _ButtonPrimaryExampleState extends State<ButtonPrimaryExample> {
  @override
  Component build(BuildContext context) {
    return Button(
      variant: CoreButtonVariant.primary,
      onPressed: () {},
      child: Text('기본').lineLimit(1).ellipsis,
    );
  }
}''',
  };
}
