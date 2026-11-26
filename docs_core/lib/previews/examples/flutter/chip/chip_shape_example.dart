import 'package:coui_flutter/coui_flutter.dart';

class ChipShapeExample extends StatefulWidget {
  const ChipShapeExample({super.key});

  @override
  State<ChipShapeExample> createState() => _ChipShapeExampleState();
}

class _ChipShapeExampleState extends State<ChipShapeExample> {
  static const _labels = ['전체', 'USD', 'JPY', 'EUR'];

  String _picked = '전체';

  @override
  Widget build(BuildContext context) {
    // 알약 칩 — 양 끝이 반원. 필터 · 정렬 · 통화 줄에 쓰고, 하나만 켜진다.
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Theme.of(context).geometry.space(CoreSpace.space8),
      children: [
        for (final label in _labels)
          Chip(
            label: label,
            shape: CoreChipShape.pill,
            selected: _picked == label,
            onTap: () => setState(() => _picked = label),
          ),
      ],
    );
  }
}
