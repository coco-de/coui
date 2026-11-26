import 'package:coui_web/coui_web.dart';

class RadioGroupCardExample extends StatefulComponent {
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
  Component build(BuildContext context) {
    // 설명이 붙은 선택지 — 타일마다 인디케이터 · 제목 · 설명을 담는다.
    return div(
      [
        RadioGroup(
          value: _selected,
          onChanged: (v) => setState(() => _selected = v),
          variant: CoreRadioGroupVariant.card,
          child: div(
            [
              for (final plan in _plans)
                Radio(
                  value: plan.value,
                  label: plan.label,
                  description: plan.description,
                ),
            ],
            classes: 'flex flex-col gap-${CoreSpace.scale.space8}',
          ),
        ),
      ],
      // 타일 열이 Flutter 처럼 프리뷰 너비를 채운다.
      classes: 'w-full',
    );
  }
}
