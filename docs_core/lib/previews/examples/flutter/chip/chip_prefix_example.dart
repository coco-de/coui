import 'package:coui_flutter/coui_flutter.dart';

class ChipPrefixExample extends StatefulWidget {
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
  Widget build(BuildContext context) {
    // 필터 칩 — 키 글자(무엇을 거르는가) + 지금 값. 걸린 필터만 켜진다.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space8),
      children: [
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
    );
  }
}
