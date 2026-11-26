/// Returns a Flutter code snippet string for the Stat component.
String statCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class StatChainExample extends StatefulWidget {
  const StatChainExample({super.key});

  @override
  State<StatChainExample> createState() => _StatChainExampleState();
}

class _StatChainExampleState extends State<StatChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        const Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).withStyle(
          const CoreStatStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
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
    'outlined' =>
      '''
class StatOutlinedExample extends StatefulWidget {
  const StatOutlinedExample({super.key});

  @override
  State<StatOutlinedExample> createState() => _StatOutlinedExampleState();
}

class _StatOutlinedExampleState extends State<StatOutlinedExample> {
  @override
  Widget build(BuildContext context) {
    return const Stat(
      label: '총매출',
      value: '4,523만',
      unit: '원',
      variant: CoreStatVariant.outlined,
      change: '+20.1%',
      changeType: CoreStatChangeType.positive,
      description: '환불 전 금액',
    );
  }
}''',
    'empty' =>
      '''
class StatEmptyExample extends StatefulWidget {
  const StatEmptyExample({super.key});

  @override
  State<StatEmptyExample> createState() => _StatEmptyExampleState();
}

class _StatEmptyExampleState extends State<StatEmptyExample> {
  @override
  Widget build(BuildContext context) {
    return const Stat(
      label: '총매출',
      unit: '원',
      description: '아직 집계 전이에요',
    );
  }
}''',
    _ =>
      '''
class StatDefaultExample extends StatefulWidget {
  const StatDefaultExample({super.key});

  @override
  State<StatDefaultExample> createState() => _StatDefaultExampleState();
}

class _StatDefaultExampleState extends State<StatDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const Stat(
      label: '총매출',
      value: '4,523만',
      unit: '원',
      change: '+20.1%',
      changeType: CoreStatChangeType.positive,
      description: '환불 전 금액',
    );
  }
}''',
  };
}
