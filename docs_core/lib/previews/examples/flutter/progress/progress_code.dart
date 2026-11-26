/// Returns a Flutter code snippet string for the Progress component.
String progressCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ProgressChainExample extends StatefulWidget {
  const ProgressChainExample({super.key});

  @override
  State<ProgressChainExample> createState() => _ProgressChainExampleState();
}

class _ProgressChainExampleState extends State<ProgressChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        SizedBox(
          width: double.infinity,
          child: const Progress(value: 0.65).radius16.primary,
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(minHeight)까지 한 번에.
        SizedBox(
          width: double.infinity,
          child: const Progress(value: 0.65).withStyle(
            const CoreProgressStyle(
              color: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              minHeight: CoreSpace.space16,
            ),
          ),
        ),
      ],
    );
  }
}''',
    'indeterminate' =>
      '''
class ProgressIndeterminateExample extends StatelessWidget {
  const ProgressIndeterminateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Progress(),
    );
  }
}''',
    'radial' =>
      '''
class ProgressRadialExample extends StatefulWidget {
  const ProgressRadialExample({super.key});

  @override
  State<ProgressRadialExample> createState() => _ProgressRadialExampleState();
}

class _ProgressRadialExampleState extends State<ProgressRadialExample> {
  @override
  Widget build(BuildContext context) {
    return const RadialProgress(
      value: 75,
      showValueText: true,
    );
  }
}''',
    'tone' =>
      '''
class ProgressToneExample extends StatelessWidget {
  const ProgressToneExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Progress(value: 0.65),
        Gap.space8(),
        Progress(value: 0.65, tone: CoreProgressTone.success),
        Gap.space8(),
        Progress(value: 0.65, tone: CoreProgressTone.warning),
        Gap.space8(),
        Progress(value: 0.65, tone: CoreProgressTone.destructive),
      ],
    );
  }
}''',
    'labelled' =>
      '''
class ProgressLabelledExample extends StatelessWidget {
  const ProgressLabelledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Progress(
        value: 0.62,
        label: Text('팀 요금제'),
        valueLabel: Text('62%'),
        caption: Text('AI 사용량 · 18일 남음'),
      ),
    );
  }
}''',
    'segments' =>
      '''
class ProgressSegmentsExample extends StatelessWidget {
  const ProgressSegmentsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Progress(
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
      ),
    );
  }
}''',
    _ =>
      '''
class ProgressDefaultExample extends StatefulWidget {
  const ProgressDefaultExample({super.key});

  @override
  State<ProgressDefaultExample> createState() => _ProgressDefaultExampleState();
}

class _ProgressDefaultExampleState extends State<ProgressDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Progress(value: 0.65),
    );
  }
}''',
  };
}
