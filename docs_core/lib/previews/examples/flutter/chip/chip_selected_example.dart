import 'package:coui_flutter/coui_flutter.dart';

class ChipSelectedExample extends StatefulWidget {
  const ChipSelectedExample({super.key});

  @override
  State<ChipSelectedExample> createState() => _ChipSelectedExampleState();
}

class _ChipSelectedExampleState extends State<ChipSelectedExample> {
  static const _labels = ['전체', '디자인', '개발'];

  final Set<String> _plain = {'전체'};
  final Set<String> _primary = {'디자인'};

  void _toggle(Set<String> picked, String label) {
    setState(() {
      if (!picked.remove(label)) picked.add(label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 인자 없이 쓴 칩 — 꺼지면 옅은 테두리, 켜지면 반전 채움.
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            for (final label in _labels)
              Chip(
                label: label,
                selected: _plain.contains(label),
                onTap: () => _toggle(_plain, label),
              ),
          ],
        ),
        const Gap.space12(),
        // primary 로 같은 모양 — 꺼진 칩은 무채이고, 켜질 때만 색을 쓴다.
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Theme.of(context).geometry.space(CoreSpace.space8),
          children: [
            for (final label in _labels)
              Chip(
                label: label,
                chipColor: CoreChipColor.primary,
                selected: _primary.contains(label),
                onTap: () => _toggle(_primary, label),
              ),
          ],
        ),
      ],
    );
  }
}
