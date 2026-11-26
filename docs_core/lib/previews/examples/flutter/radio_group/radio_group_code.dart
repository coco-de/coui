/// Returns a Flutter code snippet string for the RadioGroup component.
String radioGroupCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class RadioGroupChainExample extends StatefulWidget {
  const RadioGroupChainExample({super.key});

  @override
  State<RadioGroupChainExample> createState() => _RadioGroupChainExampleState();
}

class _RadioGroupChainExampleState extends State<RadioGroupChainExample> {
  String? _selected = 'option1';

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      value: _selected,
      onChanged: (v) => setState(() => _selected = v),
      options: const [
        (value: 'option1', label: '옵션 1'),
        (value: 'option2', label: '옵션 2'),
        (value: 'option3', label: '옵션 3'),
      ],
    ).withStyle(
      const CoreRadioGroupStyle(
        indicatorActiveColor: CoreColor.token(CoreColors.tertiary),
        indicatorBorderColor: CoreColor.token(CoreColors.tertiary),
        indicatorBorderWidth: CoreStrokeWidth.stroke3,
        selectedIndicatorBorderWidth: CoreStrokeWidth.stroke6,
        indicatorSize: CoreSize.size24,
        itemSpacing: CoreSpace.space16,
      ),
    );
  }
}''',
    'card' =>
      '''
class RadioGroupCardExample extends StatefulWidget {
  const RadioGroupCardExample({super.key});

  @override
  State<RadioGroupCardExample> createState() => _RadioGroupCardExampleState();
}

class _RadioGroupCardExampleState extends State<RadioGroupCardExample> {
  static const _plans = [
    (value: 'basic', label: 'Basic', description: '개인 프로젝트에 알맞아요'),
    (value: 'pro', label: 'Pro', description: '성장하는 팀에 알맞아요'),
    (value: 'enterprise', label: 'Enterprise', description: '고급 보안과 지원을 제공해요'),
  ];

  String? _selected = 'pro';

  @override
  Widget build(BuildContext context) {
    // 설명이 붙은 선택지 — 타일마다 인디케이터 · 제목 · 설명을 담는다.
    return RadioGroup<String>(
      value: _selected,
      onChanged: (v) => setState(() => _selected = v),
      variant: CoreRadioGroupVariant.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          for (final plan in _plans)
            Radio<String>(
              value: plan.value,
              label: plan.label,
              description: plan.description,
            ),
        ],
      ),
    );
  }
}''',
    _ =>
      '''
class RadioGroupDefaultExample extends StatefulWidget {
  const RadioGroupDefaultExample({super.key});

  @override
  State<RadioGroupDefaultExample> createState() =>
      _RadioGroupDefaultExampleState();
}

class _RadioGroupDefaultExampleState extends State<RadioGroupDefaultExample> {
  String? _selected = 'option1';

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      value: _selected,
      onChanged: (v) => setState(() => _selected = v),
      options: const [
        (value: 'option1', label: '옵션 1'),
        (value: 'option2', label: '옵션 2'),
        (value: 'option3', label: '옵션 3'),
      ],
    );
  }
}''',
  };
}
