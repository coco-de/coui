import 'package:coui_web/coui_web.dart';

class ChipPrefixExample extends StatefulComponent {
  const ChipPrefixExample({super.key});

  @override
  State<ChipPrefixExample> createState() => _ChipPrefixExampleState();
}

class _ChipPrefixExampleState extends State<ChipPrefixExample> {
  static const _filters = [
    (key: '상태', value: '진행 중'),
    (key: '담당자', value: '나'),
  ];

  final Set<String> _applied = {'상태'};

  void _toggle(String key) {
    setState(() {
      if (!_applied.remove(key)) _applied.add(key);
    });
  }

  @override
  Component build(BuildContext context) {
    // 필터 칩 — 키 글자(무엇을 거르는가) + 지금 값. 걸린 필터만 켜진다.
    return div(
      [
        for (final filter in _filters)
          Chip(
            variant: CoreChipVariant.filled,
            prefixLabel: filter.key,
            label: _applied.contains(filter.key) ? filter.value : '전체',
            trailing: const Icon(LucideIcons.chevronDown),
            selected: _applied.contains(filter.key),
            onTap: () => _toggle(filter.key),
          ),
      ],
      classes: 'flex flex-row items-center gap-${CoreSpace.scale.space8}',
    );
  }
}
