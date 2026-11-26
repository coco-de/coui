/// Returns a Web code snippet string for the Progress component.
String progressCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ProgressChainExample extends StatefulComponent {
  const ProgressChainExample({super.key});

  @override
  State<ProgressChainExample> createState() => _ProgressChainExampleState();
}

class _ProgressChainExampleState extends State<ProgressChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Progress(value: 0.65).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(minHeight)까지 한 번에.
        Progress(value: 0.65).withStyle(
          const CoreProgressStyle(
            color: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            minHeight: CoreSpace.space16,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'indeterminate' =>
      '''
class ProgressIndeterminateExample extends StatelessComponent {
  const ProgressIndeterminateExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Progress();
  }
}''',
    'radial' =>
      '''
class ProgressRadialExample extends StatefulComponent {
  const ProgressRadialExample({super.key});

  @override
  State<ProgressRadialExample> createState() => _ProgressRadialExampleState();
}

class _ProgressRadialExampleState extends State<ProgressRadialExample> {
  @override
  Component build(BuildContext context) {
    return RadialProgress(
      value: 75,
      showValueText: true,
    );
  }
}''',
    'tone' =>
      '''
class ProgressToneExample extends StatelessComponent {
  const ProgressToneExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        const Progress(value: 0.65),
        const Gap.space8(),
        const Progress(value: 0.65, tone: CoreProgressTone.success),
        const Gap.space8(),
        const Progress(value: 0.65, tone: CoreProgressTone.warning),
        const Gap.space8(),
        const Progress(value: 0.65, tone: CoreProgressTone.destructive),
      ],
      classes: 'flex flex-col w-full',
    );
  }
}''',
    'labelled' =>
      '''
class ProgressLabelledExample extends StatelessComponent {
  const ProgressLabelledExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Progress(
      value: 0.62,
      label: Text('팀 요금제'),
      valueLabel: Text('62%'),
      caption: Text('AI 사용량 · 18일 남음'),
    );
  }
}''',
    'segments' =>
      '''
class ProgressSegmentsExample extends StatelessComponent {
  const ProgressSegmentsExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Progress(
      value: 1,
      max: 2,
      segments: 2,
      size: CoreProgressSize.xs,
      label: Text('1 / 2단계'),
      progressStyle: CoreProgressStyle(
        labelStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}''',
    _ =>
      '''
class ProgressDefaultExample extends StatefulComponent {
  const ProgressDefaultExample({super.key});

  @override
  State<ProgressDefaultExample> createState() => _ProgressDefaultExampleState();
}

class _ProgressDefaultExampleState extends State<ProgressDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Progress(value: 0.65);
  }
}''',
  };
}
