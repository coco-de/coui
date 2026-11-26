import 'package:coui_flutter/coui_flutter.dart';

class ChipVariantExample extends StatefulWidget {
  const ChipVariantExample({super.key});

  @override
  State<ChipVariantExample> createState() => _ChipVariantExampleState();
}

class _ChipVariantExampleState extends State<ChipVariantExample> {
  static const _labels = ['전체', '디자인', '개발'];

  final Set<String> _outlined = {'전체'};
  final Set<String> _filled = {'전체'};
  final Set<String> _onGrey = {'전체'};

  void _toggle(Set<String> picked, String label) {
    setState(() {
      if (!picked.remove(label)) picked.add(label);
    });
  }

  Widget _row(CoreChipVariant variant, Set<String> picked) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space8,
      children: [
        for (final label in _labels)
          Chip(
            label: label,
            variant: variant,
            selected: picked.contains(label),
            onTap: () => _toggle(picked, label),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // outlined(기본) — 투명 채움에 옅은 테두리. 어느 바탕 위에서도 쓴다.
        Text('outlined').labelSmall.onSurfaceVariant,
        const Gap.space4(),
        _row(CoreChipVariant.outlined, _outlined),
        const Gap.space12(),
        // filled — 회색 채움에 테두리 없음. 켜지면 진한 채움으로 바뀐다.
        Text('filled').labelSmall.onSurfaceVariant,
        const Gap.space4(),
        _row(CoreChipVariant.filled, _filled),
        const Gap.space12(),
        // 회색 바탕 위의 filled 는 바탕에 묻힌다 — 거기서는 outlined.
        Text('회색 바탕 위에서는 outlined').labelSmall.onSurfaceVariant,
        const Gap.space4(),
        Card(
          variant: CoreCardVariant.filled,
          body: _row(CoreChipVariant.outlined, _onGrey),
        ),
      ],
    );
  }
}
