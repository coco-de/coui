/// Returns a Web code snippet string for the Stat component.
String statCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class StatChainExample extends StatefulComponent {
  const StatChainExample({super.key});

  @override
  State<StatChainExample> createState() => _StatChainExampleState();
}

class _StatChainExampleState extends State<StatChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        Stat(
          label: '총매출',
          value: '4,523만 원',
          change: '+20.1%',
          changeType: CoreStatChangeType.positive,
        ).withStyle(
          const CoreStatStyle(
            backgroundColor: .tertiary,
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
    'outlined' =>
      '''
class StatOutlinedExample extends StatefulComponent {
  const StatOutlinedExample({super.key});

  @override
  State<StatOutlinedExample> createState() => _StatOutlinedExampleState();
}

class _StatOutlinedExampleState extends State<StatOutlinedExample> {
  @override
  Component build(BuildContext context) {
    return Stat(
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
class StatEmptyExample extends StatefulComponent {
  const StatEmptyExample({super.key});

  @override
  State<StatEmptyExample> createState() => _StatEmptyExampleState();
}

class _StatEmptyExampleState extends State<StatEmptyExample> {
  @override
  Component build(BuildContext context) {
    return Stat(
      label: '총매출',
      unit: '원',
      description: '아직 집계 전이에요',
    );
  }
}''',
    _ =>
      '''
class StatDefaultExample extends StatefulComponent {
  const StatDefaultExample({super.key});

  @override
  State<StatDefaultExample> createState() => _StatDefaultExampleState();
}

class _StatDefaultExampleState extends State<StatDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Stat(
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
